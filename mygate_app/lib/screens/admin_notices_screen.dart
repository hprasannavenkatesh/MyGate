// lib/screens/admin_notice_screen.dart
import 'package:flutter/material.dart';
import '../../services/notice_service.dart';
import '../../services/auth_service.dart';

class AdminNoticeScreen extends StatefulWidget {
  const AdminNoticeScreen({super.key});

  @override
  State<AdminNoticeScreen> createState() => _AdminNoticeScreenState();
}

class _AdminNoticeScreenState extends State<AdminNoticeScreen> {
  List<dynamic> _notices = [];
  bool _isLoading = true;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() => _isLoading = true);
    try {
      final data = await NoticeService.getNotices();
      if (mounted) setState(() => _notices = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showPostNoticeDialog() async {
    _titleController.clear();
    _descController.clear();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Post New Notice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty) return;

                final societyId = await AuthService.getSocietyId();
                final userId = await AuthService.getUserId();

                final payload = {
                  'societyId': societyId,
                  'title': _titleController.text.trim(),
                  'description': _descController.text.trim(),
                  'category': 0,
                  'isPinned': false,
                  'createdByUserId': userId,
                };

                final success = await NoticeService.createNotice(payload);

                if (ctx.mounted) Navigator.pop(ctx);
                
                if (success) {
                  _fetchNotices();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notice Posted!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to post notice.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notice Board')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostNoticeDialog,
        tooltip: 'Post Notice',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty
              ? const Center(child: Text('No notices found.'))
              : ListView.builder(
                  itemCount: _notices.length,
                  itemBuilder: (context, index) {
                    final n = _notices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n['title'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (n['isPinned'] == true)
                                  const Icon(Icons.push_pin, color: Colors.orange, size: 20),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(n['description'] ?? ''),
                            const SizedBox(height: 12),
                            Text(
                              'Posted: ${n['createdAt']?.substring(0, 10) ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}