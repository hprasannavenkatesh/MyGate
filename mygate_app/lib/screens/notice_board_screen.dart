// lib/screens/notice_board_screen.dart
import 'package:flutter/material.dart';
import '../services/notice_service.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  List<dynamic> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    try {
      final notices = await NoticeService.getNotices();
      if (mounted) setState(() { _notices = notices; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notice Board'), backgroundColor: Colors.teal),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty 
              ? const Center(child: Text('No notices available.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _notices.length,
                  itemBuilder: (context, index) {
                    final n = _notices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['title'] ?? 'Notice', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(n['content'] ?? '', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(n['createdAt'].toString().substring(0, 10), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}