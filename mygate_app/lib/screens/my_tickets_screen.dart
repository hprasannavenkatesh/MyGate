// lib/screens/my_tickets_screen.dart
import 'package:flutter/material.dart';
import '../services/helpdesk_service.dart';
import 'raise_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      final tickets = await HelpdeskService.getMyTickets();
      if (mounted) setState(() { _tickets = tickets; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
      appBar: AppBar(title: const Text('My Support Tickets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const RaiseTicketScreen()));
          _fetchTickets(); // Refresh after adding
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty 
              ? const Center(child: Text('No tickets raised yet.'))
              : ListView.builder(
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final t = _tickets[index];
                    return Card(
                      child: ListTile(
                        title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(t['category'] ?? 'General'),
                        trailing: Chip(label: Text(_getStatusText(t['status'] ?? 0))),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TicketDetailScreen(ticketId: t['id']))),
                      ),
                    );
                  },
                ),
    );
  }
}