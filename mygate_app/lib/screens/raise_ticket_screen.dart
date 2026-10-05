// lib/screens/raise_ticket_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/helpdesk_service.dart';

class RaiseTicketScreen extends StatefulWidget {
  const RaiseTicketScreen({super.key});

  @override
  State<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends State<RaiseTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  
  int _selectedPriority = 1; 
  bool _isLoading = false;

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final societyId = await AuthService.getSocietyId();
      final flatId = await AuthService.getFlatId();

      final isSuccess = await HelpdeskService.raiseTicket({
        'societyId': societyId,
        'flatId': flatId,
        'title': _titleController.text,
        'description': _descController.text,
        'category': _categoryController.text,
        'priority': _selectedPriority
      });

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Ticket submitted successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        _showError('Failed to submit ticket');
      }
    } catch (e) { 
      _showError('Error: $e'); 
    } finally { 
      setState(() => _isLoading = false); 
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raise Support Ticket'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Subject / Title *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                validator: (val) => val!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe your issue in detail *',
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.description),
                  hintText: "E.g., The water pressure in Block A is very low today...",
                ),
                validator: (val) => val!.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category (e.g., Plumbing, Electrical)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField(
                value: _selectedPriority,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Low Priority')),
                  DropdownMenuItem(value: 1, child: Text('Medium Priority (Default)')),
                  DropdownMenuItem(value: 2, child: Text('High Priority')),
                  DropdownMenuItem(value: 3, child: Text('Critical Priority')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Priority *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.priority_high),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                onChanged: (val) => setState(() => _selectedPriority = val!),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Ticket', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}