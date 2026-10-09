// lib/screens/my_visitors_screen.dart
import 'package:flutter/material.dart';
import '../services/visitor_service.dart';
import 'add_visitor_screen.dart';

class MyVisitorsScreen extends StatefulWidget {
  const MyVisitorsScreen({super.key});

  @override
  State<MyVisitorsScreen> createState() => _MyVisitorsScreenState();
}

class _MyVisitorsScreenState extends State<MyVisitorsScreen> {
  List<dynamic> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVisitors();
  }

  Future<void> _fetchVisitors() async {
    try {
      final visitors = await VisitorService.getMyVisitors();
      if (mounted) {
        setState(() { 
          _visitors = visitors; 
          _isLoading = false; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Visitors'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddVisitorScreen()));
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Visitor'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _visitors.isEmpty 
              ? const Center(
                  child: Text(
                    'No visitors pre-approved yet.\nTap + to add one.', 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey)
                  )
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _visitors.length,
                  itemBuilder: (context, index) {
                    final v = _visitors[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_outline, size: 40),
                        title: Text(v['visitorName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mobile: ${v['visitorMobile']}'),
                            Text('Date: ${v['expectedDate'].toString().substring(0, 10)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        /*trailing: Chip(
                          label: Text(v['status'] == 0 ? 'Pending' : 'Expired'),
                          backgroundColor: v['status'] == 0 ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        ),*/
                        trailing: Chip(
  label: Text(
    v['status'] == 0 || v['status'] == 'Pending' ? 'Pending' : 
    v['status'] == 1 || v['status'] == 'Inside' ? 'Inside' : 
    v['status'] == 2 || v['status'] == 'Exited' ? 'Exited' : 
    'Expired'
  ),
  backgroundColor: 
    v['status'] == 0 || v['status'] == 'Pending' ? Colors.orange.withOpacity(0.1) : 
    v['status'] == 1 || v['status'] == 'Inside' ? Colors.green.withOpacity(0.1) : 
    v['status'] == 2 || v['status'] == 'Exited' ? Colors.grey.withOpacity(0.1) : 
    Colors.red.withOpacity(0.1),
),
                      ),
                    );
                  },
                ),
    );
  }
}