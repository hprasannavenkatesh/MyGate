import 'package:flutter/material.dart';
import 'package:mygate_app/services/tenant_admin_service.dart';

class AdminRegisterUserScreen extends StatefulWidget {
  const AdminRegisterUserScreen({super.key});
  @override
  State<AdminRegisterUserScreen> createState() => _AdminRegisterUserScreenState();
}

class _AdminRegisterUserScreenState extends State<AdminRegisterUserScreen> {
  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'TempPass@123');
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await TenantAdminService.registerUser(
        _mobileController.text, 
        _nameController.text, 
        _passwordController.text,
        _emailController.text.isEmpty ? null : _emailController.text
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ User Registered Successfully!')));
      _mobileController.clear();
      _nameController.clear();
      _emailController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email (Optional)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Register User'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}