// lib/screens/my_dues_screen.dart
import 'package:flutter/material.dart';
import '../services/billing_service.dart'; // FIX: Added missing import

class MyDuesScreen extends StatefulWidget {
  const MyDuesScreen({super.key});

  @override
  State<MyDuesScreen> createState() => _MyDuesScreenState();
}

class _MyDuesScreenState extends State<MyDuesScreen> {
  List<dynamic> _dues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDues();
  }

  Future<void> _fetchDues() async {
    try {
      final dues = await BillingService.getMyDues();
      if (mounted) {
        setState(() {
          _dues = dues;
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
        title: const Text('My Maintenance Dues'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dues.isEmpty
              ? const Center(child: Text('No dues found.', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _dues.length,
                  itemBuilder: (context, index) {
                    final d = _dues[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.receipt, color: Colors.purple, size: 40),
                        title: Text(d['description'] ?? 'Maintenance Due', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Due Date: ${d['dueDate'].toString().substring(0, 10)}'),
                        trailing: Text('₹${d['amount']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                      ),
                    );
                  },
                ),
    );
  }
}