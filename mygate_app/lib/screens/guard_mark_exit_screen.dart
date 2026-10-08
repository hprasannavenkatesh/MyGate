import 'package:flutter/material.dart';
import '../services/visitor_service.dart';
import '../services/auth_service.dart';

class GuardMarkExitScreen extends StatefulWidget {
  const GuardMarkExitScreen({super.key});

  @override
  State<GuardMarkExitScreen> createState() => _GuardMarkExitScreenState();
}

class _GuardMarkExitScreenState extends State<GuardMarkExitScreen> {
  List<dynamic> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInsideVisitors();
  }

  Future<void> _fetchInsideVisitors() async {
    try {
      final societyId = await AuthService.getSocietyId();
      final allVisitors = await VisitorService.getSocietyVisitors(societyId);
      final insideVisitors = allVisitors.where((v) => v['status'] == 1 || v['status'] == 'Inside').toList();
      if (mounted) setState(() { _visitors = insideVisitors; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markExit(String visitorId) async {
    try {
      await VisitorService.guardMarkExit(visitorId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Exit Marked!'), backgroundColor: Colors.green));
        _fetchInsideVisitors(); // Refresh list
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Visitor Exit')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _visitors.isEmpty 
              ? const Center(child: Text('No visitors currently inside to exit.'))
              : ListView.builder(
                  itemCount: _visitors.length,
                  itemBuilder: (context, index) {
                    final v = _visitors[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.directions_walk, color: Colors.grey),
                        title: Text(v['visitorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Mobile: ${v['visitorMobile'] ?? 'N/A'}'),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _markExit(v['id']),
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Mark Exit'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}