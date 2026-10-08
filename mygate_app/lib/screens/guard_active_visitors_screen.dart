// lib/screens/guard_active_visitors_screen.dart
import 'package:flutter/material.dart';
import '../services/visitor_service.dart';
import '../services/auth_service.dart';

class GuardActiveVisitorsScreen extends StatefulWidget {
  const GuardActiveVisitorsScreen({super.key});

  @override
  State<GuardActiveVisitorsScreen> createState() => _GuardActiveVisitorsScreenState();
}

class _GuardActiveVisitorsScreenState extends State<GuardActiveVisitorsScreen> {
  List<dynamic> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVisitors();
  }

  Future<void> _fetchVisitors() async {
    try {
      final societyId = await AuthService.getSocietyId();
      final allVisitors = await VisitorService.getSocietyVisitors(societyId);
      
      // Filter for only those currently Inside (Adjust logic based on your backend enum response)
      // If backend returns string: v['status'] == 'Inside'
      // If backend returns int: v['status'] == 1
      final insideVisitors = allVisitors.where((v) => v['status'] == 1 || v['status'] == 'Inside').toList();
      
      if (mounted) setState(() { _visitors = insideVisitors; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Currently Inside Society')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _visitors.isEmpty 
              ? const Center(child: Text('No visitors currently inside.'))
              : ListView.builder(
                  itemCount: _visitors.length,
                  itemBuilder: (context, index) {
                    final v = _visitors[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.directions_walk, color: Colors.green),
                        title: Text(v['visitorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Mobile: ${v['visitorMobile'] ?? 'N/A'}\nFlat: ${v['flatId'] ?? 'N/A'}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.red),
                          tooltip: 'Quick Exit',
                          onPressed: () async {
                            await VisitorService.markExit(v['id']);
                            _fetchVisitors(); // Refresh list
                          }
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}