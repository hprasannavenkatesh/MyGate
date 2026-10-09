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