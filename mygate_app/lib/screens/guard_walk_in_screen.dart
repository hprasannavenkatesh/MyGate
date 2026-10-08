import 'package:flutter/material.dart';
import '../services/visitor_service.dart';
import '../services/auth_service.dart';

class GuardWalkInScreen extends StatefulWidget {
  const GuardWalkInScreen({super.key});
  @override
  State<GuardWalkInScreen> createState() => _GuardWalkInScreenState();
}

class _GuardWalkInScreenState extends State<GuardWalkInScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _walkIn() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final societyId = await AuthService.getSocietyId();
      final userId = await AuthService.getUserId();
      final flatId = await AuthService.getFlatId(); // Guard's flat context

      // 1. Pre-approve
      final result = await VisitorService.preApproveVisitor({
        'societyId': societyId,
        'flatId': flatId, 
        'invitedByUserId': userId,
        'visitorName': _nameController.text,
        'visitorMobile': _mobileController.text,
        'purpose': _purposeController.text,
        'expectedDate': DateTime.now().toIso8601String().split('T').first,
      });

      // 2. Immediate Manual Entry (No OTP)
      await VisitorService.guardManualEntry(result['id'], 'Walk-in at gate');

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Walk-in Allowed!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Walk-In Entry (No OTP)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Visitor Name *', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _purposeController, decoration: const InputDecoration(labelText: 'Purpose (e.g., Delivery)', border: OutlineInputBorder())),
            const Spacer(),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _walkIn, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Allow Entry'))),
          ],
        ),
      ),
    );
  }
}