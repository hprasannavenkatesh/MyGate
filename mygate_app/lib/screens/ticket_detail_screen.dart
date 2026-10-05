// lib/screens/ticket_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/helpdesk_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Map<String, dynamic>? _ticket;
  List<dynamic> _comments = [];
  bool _isLoading = true;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await HelpdeskService.getTicketDetails(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = data;
          _comments = data['comments'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final isSuccess = await HelpdeskService.addComment(
        widget.ticketId, 
        _commentController.text, 
        false // isAdminComment = false
      );

      if (isSuccess) {
        _commentController.clear();
        _fetchDetails(); 
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to post comment')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Open';
      case 1: return 'In Progress';
      case 2: return 'Resolved';
      case 3: return 'Closed';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ticket?['title'] ?? 'Ticket Details'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${_getStatusText(_ticket?['status'] ?? 0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 8),
                      Text(_ticket?['description'] ?? '', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                
                Expanded(
                  child: _comments.isEmpty
                      ? const Center(child: Text('No comments yet. Wait for admin to respond.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final c = _comments[index];
                            bool isAdmin = c['isAdminComment'] == true;
                            
                            return Align(
                              alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isAdmin ? Colors.blue.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isAdmin ? '👨‍💼 Admin' : '👤 You', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isAdmin ? Colors.blue : Colors.orange)),
                                    Text(c['commentText'], style: const TextStyle(fontSize: 14)),
                                    Text(c['createdAt'].toString().substring(0, 16), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: _postComment,
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}