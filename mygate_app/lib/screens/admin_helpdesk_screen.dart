// lib/screens/admin_helpdesk_screen.dart
import 'package:flutter/material.dart';
import '../../services/helpdesk_service.dart';
import 'ticket_detail_screen.dart';

class AdminHelpdeskScreen extends StatefulWidget {
  const AdminHelpdeskScreen({super.key});

  @override
  State<AdminHelpdeskScreen> createState() => _AdminHelpdeskScreenState();
}

class _AdminHelpdeskScreenState extends State<AdminHelpdeskScreen> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    try {
      final data = await HelpdeskService.getSocietyTickets();
      if (mounted) setState(() => _tickets = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String ticketId, int newStatus) async {
    try {
      final success = await HelpdeskService.updateTicketStatus(ticketId, newStatus);
      if (success) {
        _fetchTickets(); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status Updated!'), backgroundColor: Colors.green)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
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

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.orange.shade100;
      case 1: return Colors.blue.shade100;
      case 2: return Colors.green.shade100;
      case 3: return Colors.grey.shade200;
      default: return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Helpdesk Tickets')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty 
              ? const Center(child: Text('No tickets found.'))
              : ListView.builder(
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final t = _tickets[index];
                    final status = t['status'] ?? 0;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ADDED: Make the ticket details tappable to view/add comments
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => TicketDetailScreen(ticketId: t['id']))
                                ).then((_) => _fetchTickets()); // Refresh status when returning
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t['title'] ?? '', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                        )
                                      ),
                                      Chip(
                                        label: Text(_getStatusText(status), style: const TextStyle(fontSize: 12)),
                                        backgroundColor: _getStatusColor(status),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    t['description'] ?? '', 
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis, 
                                    style: TextStyle(color: Colors.grey.shade700)
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('Tap for details', style: TextStyle(fontSize: 11, color: Colors.indigo.shade300, fontStyle: FontStyle.italic)),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // EXISTING BUTTONS + NEW CLOSE BUTTON
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (status == 0) 
                                  ElevatedButton.icon(
                                    onPressed: () => _updateStatus(t['id'], 1),
                                    icon: const Icon(Icons.play_arrow, size: 16),
                                    label: const Text('Start'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue, 
                                      foregroundColor: Colors.white, 
                                      padding: const EdgeInsets.symmetric(horizontal: 12)
                                    ),
                                  ),
                                if (status == 1) 
                                  ElevatedButton.icon(
                                    onPressed: () => _updateStatus(t['id'], 2),
                                    icon: const Icon(Icons.check_circle, size: 16),
                                    label: const Text('Resolve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green, 
                                      foregroundColor: Colors.white, 
                                      padding: const EdgeInsets.symmetric(horizontal: 12)
                                    ),
                                  ),
                                // ADDED: Close button for Resolved tickets
                                if (status == 2) 
                                  ElevatedButton.icon(
                                    onPressed: () => _updateStatus(t['id'], 3),
                                    icon: const Icon(Icons.lock_outline, size: 16),
                                    label: const Text('Close'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey, 
                                      foregroundColor: Colors.white, 
                                      padding: const EdgeInsets.symmetric(horizontal: 12)
                                    ),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}