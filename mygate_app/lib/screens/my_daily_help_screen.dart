// lib/screens/my_daily_help_screen.dart
import 'package:flutter/material.dart';
import '../services/daily_help_service.dart';

class MyDailyHelpScreen extends StatefulWidget {
  const MyDailyHelpScreen({super.key});

  @override
  State<MyDailyHelpScreen> createState() => _MyDailyHelpScreenState();
}

class _MyDailyHelpScreenState extends State<MyDailyHelpScreen> {
  List<dynamic> _helpers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHelpers();
  }

  Future<void> _fetchHelpers() async {
    try {
      final helpers = await DailyHelpService.getMyDailyHelp();
      if (mounted) setState(() { _helpers = helpers; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Daily Help'), backgroundColor: Colors.lightGreen),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _helpers.isEmpty 
              ? const Center(child: Text('No daily help assigned.'))
              : ListView.builder(
                  itemCount: _helpers.length,
                  itemBuilder: (context, index) {
                    final h = _helpers[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person, size: 40),
                        title: Text(h['name'] ?? 'Helper', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(h['helpType'] ?? 'N/A'),
                        trailing: Text(h['mobileNumber'] ?? '', style: const TextStyle(color: Colors.grey)),
                      ),
                    );
                  },
                ),
    );
  }
}