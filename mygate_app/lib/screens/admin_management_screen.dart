import 'package:flutter/material.dart';
import 'package:mygate_app/services/auth_service.dart';
import 'package:mygate_app/services/tenant_admin_service.dart';
import '../services/auth_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _societyId = '';
  List<dynamic> _blocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final societyId = await AuthService.getSocietyId();
    if (societyId.isEmpty) return;
    
    setState(() => _societyId = societyId);
    
    try {
      final blocks = await TenantAdminService.getBlocks(_societyId);
      setState(() { _blocks = blocks; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddBlockDialog() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Block'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Block Name (e.g., B)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, nameController.text), child: const Text('Create')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await TenantAdminService.createBlock(_societyId, result);
      if (success) _loadData(); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Block Added!' : 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.apartment), text: 'Blocks & Flats'),
            Tab(icon: Icon(Icons.person_add), text: 'Register User'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Blocks & Flats
          _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
            itemCount: _blocks.length,
            itemBuilder: (context, index) {
              final block = _blocks[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.domain),
                  title: Text(block['name'] ?? 'Unknown Block'),
                  subtitle: Text('ID: ${block['id']}'),
                ),
              );
            },
          ),
          // TAB 2: Register User
          _RegisterUserTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBlockDialog,
        tooltip: 'Add Block',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Extracted Register User Tab Widget
class _RegisterUserTab extends StatefulWidget {
  @override
  State<_RegisterUserTab> createState() => _RegisterUserTabState();
}

class _RegisterUserTabState extends State<_RegisterUserTab> {
  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'TempPass@123'); // Default temp password
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
    return Padding(
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
    );
  }
}