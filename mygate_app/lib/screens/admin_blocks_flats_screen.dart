import 'package:flutter/material.dart';
import 'package:mygate_app/services/auth_service.dart';
import 'package:mygate_app/services/tenant_admin_service.dart';

class AdminBlocksFlatsScreen extends StatefulWidget {
  const AdminBlocksFlatsScreen({super.key});
  @override
  State<AdminBlocksFlatsScreen> createState() => _AdminBlocksFlatsScreenState();
}

class _AdminBlocksFlatsScreenState extends State<AdminBlocksFlatsScreen> {
  String _societyId = '';
  List<dynamic> _blocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final societyId = await AuthService.getSocietyId();
    // FIX: If societyId is empty, throw an error so the catch block handles it gracefully
      if (societyId.isEmpty) {
        throw Exception('Society ID not found. Please log out and log back in.');
      }
    if (societyId.isEmpty) return;
    setState(() => _societyId = societyId);
    try {
      final blocks = await TenantAdminService.getBlocks(_societyId);
      setState(() { _blocks = blocks; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
        // Show the user what went wrong instead of failing silently
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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

  Future<void> _showAddFlatDialog(String blockId) async {
    final flatNumberController = TextEditingController();
    final flatTypeController = TextEditingController(text: '2BHK');
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Flat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: flatNumberController, decoration: const InputDecoration(labelText: 'Flat Number (e.g., 101)')),
            const SizedBox(height: 8),
            TextField(controller: flatTypeController, decoration: const InputDecoration(labelText: 'Type (e.g., 2BHK, 3BHK)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, {
              'flatNumber': flatNumberController.text,
              'flatType': flatTypeController.text,
            }), 
            child: const Text('Create')
          ),
        ],
      ),
    );

    if (result != null && result['flatNumber']!.isNotEmpty) {
      final success = await TenantAdminService.createFlat(blockId, _societyId, result['flatNumber']!, result['flatType']!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flat Added!')));
        setState(() {}); 
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add flat')));
      }
    }
  }

    // ==========================================
  // BLOCK EDIT & DELETE
  // ==========================================
  Future<void> _showEditBlockDialog(Map<String, dynamic> block) async {
    final nameController = TextEditingController(text: block['name'] ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Block'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Block Name *', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              //final success = await TenantAdminService.updateBlock(block['id'], {'societyId': _societyId, 'name': nameController.text.trim()});
              final success = await TenantAdminService.updateBlock(block['id'], {
                'blockId': block['id'],         // Required by UpdateBlockCommand
                'societyId': _societyId,        // Required for security check
                'name': nameController.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (success) { _loadData(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Block Updated!'), backgroundColor: Colors.green)); }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBlock(String blockId) async {
    final confirm = await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Block?'), content: const Text('This will also delete all flats inside it.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete'))]));
    if (confirm == true) {
      final success = await TenantAdminService.deleteBlock(blockId, _societyId);
      if (success && mounted) { _loadData(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Block Deleted'), backgroundColor: Colors.red)); }
    }
  }

  // ==========================================
  // FLAT EDIT & DELETE
  // ==========================================
  Future<void> _showEditFlatDialog(Map<String, dynamic> flat, String blockId) async {
    final flatNumberController = TextEditingController(text: flat['flatNumber'] ?? '');
    final flatTypeController = TextEditingController(text: flat['type'] ?? '2BHK');
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Flat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: flatNumberController, decoration: const InputDecoration(labelText: 'Flat Number *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: flatTypeController, decoration: const InputDecoration(labelText: 'Flat Type', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (flatNumberController.text.trim().isEmpty) return;
              /*final success = await TenantAdminService.updateFlat(flat['id'], {
                'societyId': _societyId,
                'blockId': blockId,
                'flatNumber': flatNumberController.text.trim(),
                'type': flatTypeController.text.trim(),
              });*/
              final success = await TenantAdminService.updateFlat(flat['id'], {
                'flatId': flat['id'],           // Required by UpdateFlatCommand
                'societyId': _societyId,        // Required for security check
                'blockId': blockId,             // Required to find the flat
                'flatNumber': flatNumberController.text.trim(),
                'type': flatTypeController.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (success) { setState(() {}); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flat Updated!'), backgroundColor: Colors.green)); }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFlat(String flatId) async {
    final confirm = await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Flat?'), content: const Text('Are you sure?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete'))]));
    if (confirm == true) {
      final success = await TenantAdminService.deleteFlat(flatId, _societyId);
      if (success && mounted) { setState(() {}); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flat Deleted'), backgroundColor: Colors.red)); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocks & Flats')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBlockDialog,
        tooltip: 'Add Block',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _blocks.length,
              itemBuilder: (context, index) {
                final block = _blocks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ExpansionTile(
                    leading: const Icon(Icons.domain, color: Colors.indigo),
                    title: Text(block['name'] ?? 'Unknown Block', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Block ID: ${block['id']?.toString().substring(0, 8)}...'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditBlockDialog(block)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteBlock(block['id'])),
                      ],
                    ),
                    children: [
                      FutureBuilder<List<dynamic>>(
                        future: TenantAdminService.getFlats(block['id']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Padding(padding: EdgeInsets.all(16.0), child: Text('No flats in this block.'));
                          }
                          
                          final flats = snapshot.data!;
                          return Column(
                            children: [
                              ...flats.map((flat) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.meeting_room, size: 20),
                                title: Text('Flat: ${flat['flatNumber']}'),
                                subtitle: Text('Type: ${flat['type'] ?? 'N/A'}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, size: 16, color: Colors.blue), onPressed: () => _showEditFlatDialog(flat, block['id'])),
                                    IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red), onPressed: () => _deleteFlat(flat['id'])),
                                  ],
                                ),
                              )).toList(),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Flat'),
                                    onPressed: () => _showAddFlatDialog(block['id']),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}