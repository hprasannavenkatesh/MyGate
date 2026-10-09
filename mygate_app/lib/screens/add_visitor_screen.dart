// lib/screens/add_visitor_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/visitor_service.dart';

class AddVisitorScreen extends StatefulWidget {
  const AddVisitorScreen({super.key});

  @override
  State<AddVisitorScreen> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends State<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitVisitor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final societyId = await AuthService.getSocietyId();
      final flatId = await AuthService.getFlatId();
      final userId = await AuthService.getUserId();

      final data = await VisitorService.preApproveWalkIn(
        societyId: societyId,
        flatId: flatId,
        visitorName: _nameController.text,
        visitorMobile: _mobileController.text,
        purpose: _purposeController.text.isEmpty ? 'Visit' : _purposeController.text,
        //expectedDate: DateTime.now().toIso8601String(),
        expectedDate: DateTime.now().toUtc().add(const Duration(hours: 23, minutes: 59, seconds: 59)).toIso8601String(),
        invitedByUserId: userId,
      );

      if (data != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Visitor Pre-Approved!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Approve Visitor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Visitor Name *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _purposeController, decoration: const InputDecoration(labelText: 'Purpose (Optional)', border: OutlineInputBorder())),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVisitor,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Pre-Approve', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}