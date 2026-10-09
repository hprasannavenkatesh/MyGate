// lib/screens/admin_guard_management_screen.dart
import 'package:flutter/material.dart';
import '../../services/guard_management_service.dart';
import '../../services/auth_service.dart';

class AdminGuardManagementScreen extends StatefulWidget {
  const AdminGuardManagementScreen({super.key});

  @override
  State<AdminGuardManagementScreen> createState() => _AdminGuardManagementScreenState();
}

class _AdminGuardManagementScreenState extends State<AdminGuardManagementScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Guard@123'); // Default temp password
  bool _isRegistering = false;

  Future<void> _registerGuard() async {
    if (_nameController.text.trim().isEmpty || _mobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Mobile are required.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isRegistering = true);

    try {
      final societyId = await AuthService.getSocietyId();
      if (societyId.isEmpty) throw Exception('Society ID not found. Please log in again.');

      // Step 1: Create the User in Identity Service
      final result = await GuardManagementService.registerGuard(
        _mobileController.text.trim(),
        _nameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result != null && result.containsKey('id')) {
        final userId = result['id'].toString();

        // Step 2: Assign the User to the Society as a 'Guard' member
        final assigned = await GuardManagementService.assignGuardToSociety(userId, societyId);

        if (assigned && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Guard Registered & Assigned Successfully!'), backgroundColor: Colors.green),
          );
          _nameController.clear();
          _mobileController.clear();
          _passwordController.text = 'Guard@123';
        } else {
          throw Exception('Guard created, but failed to assign to society.');
        }
      } else {
        throw Exception('Invalid response from server during registration.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Management'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Colors.deepOrange, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Register Security Guard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange)),
                        SizedBox(height: 4),
                        Text('This will create their login and assign them to your society.', style: TextStyle(fontSize: 12, color: Colors.deepOrange)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Guard Full Name *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number *',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Temporary Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
                helperText: 'Guard will use this for their first login',
              ),
            ),
            const Spacer(),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isRegistering ? null : _registerGuard,
                icon: _isRegistering 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Icon(Icons.shield),
                label: const Text('Register Guard', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}