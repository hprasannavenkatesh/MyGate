// lib/screens/admin_master_data_screen.dart
import 'package:flutter/material.dart';
import '../../services/master_data_service.dart';
import '../../services/tenant_admin_service.dart';
import '../../services/auth_service.dart';

class AdminMasterDataScreen extends StatefulWidget {
  const AdminMasterDataScreen({super.key});

  @override
  State<AdminMasterDataScreen> createState() => _AdminMasterDataScreenState();
}

class _AdminMasterDataScreenState extends State<AdminMasterDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Societies State ---
  List<dynamic> _societies = [];
  bool _isLoadingSocieties = true;

  // --- Blocks/Flats State ---
  List<dynamic> _blocks = [];
  bool _isLoadingBlocks = true;
  String _selectedSocietyId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSocieties();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // TAB 1: SOCIETY CRUD (SUPERADMIN)
  // ==========================================
  Future<void> _fetchSocieties() async {
    setState(() => _isLoadingSocieties = true);
    try {
      final data = await MasterDataService.getAllSocieties();
      if (mounted) setState(() => _societies = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingSocieties = false);
    }
  }

  Future<void> _showCreateSocietyDialog() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Society'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Society Name *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Society Code *', border: OutlineInputBorder(), hintText: 'e.g., SUN-APT')),
              const SizedBox(height: 12),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || codeController.text.isEmpty) return;
              
              final success = await MasterDataService.createSociety({
                'name': nameController.text.trim(),
                'code': codeController.text.trim(),
                'address': addressController.text.trim(),
                'city': cityController.text.trim(),
              });

              if (ctx.mounted) Navigator.pop(ctx);
              if (success) {
                _fetchSocieties();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Society Created!'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSociety(String societyId) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Society?'),
        content: const Text('This will permanently delete this society and all its blocks, flats, and members. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await MasterDataService.deleteSociety(societyId);
      if (success && mounted) {
        _fetchSocieties();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Society Deleted'), backgroundColor: Colors.red));
      }
    }
  }

  // ==========================================
  // TAB 2: BLOCKS & FLATS (ADMIN)
  // ==========================================
  Future<void> _loadBlocksForSociety(String societyId) async {
    setState(() { _selectedSocietyId = societyId; _isLoadingBlocks = true; });
    try {
      final blocks = await TenantAdminService.getBlocks(societyId);
      if (mounted) setState(() => _blocks = blocks);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingBlocks = false);
    }
  }

  Future<void> _showAddBlockDialog() async {
    if (_selectedSocietyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a society first.'), backgroundColor: Colors.orange));
      return;
    }

    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Block'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Block Name (e.g., A)', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final success = await TenantAdminService.createBlock(_selectedSocietyId, nameController.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (success) _loadBlocksForSociety(_selectedSocietyId);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFlatDialog(String blockId) async {
    final flatNumController = TextEditingController();
    final flatTypeController = TextEditingController(text: '2BHK');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Flat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: flatNumController, decoration: const InputDecoration(labelText: 'Flat Number (e.g., 101)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: flatTypeController, decoration: const InputDecoration(labelText: 'Type (e.g., 2BHK)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (flatNumController.text.isEmpty) return;
              final success = await TenantAdminService.createFlat(blockId, _selectedSocietyId, flatNumController.text, flatTypeController.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (success) _loadBlocksForSociety(_selectedSocietyId); // Refresh
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Data Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.apartment), text: 'Societies'),
            Tab(icon: Icon(Icons.domain), text: 'Blocks & Flats'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tabController.index == 0 ? _showCreateSocietyDialog : _showAddBlockDialog,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: SOCIETIES LIST
          _isLoadingSocieties
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _societies.length,
                  itemBuilder: (context, index) {
                    final s = _societies[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${s['code'] ?? ''} | ${s['city'] ?? ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteSociety(s['id']),
                        ),
                        onTap: () => _loadBlocksForSociety(s['id']), // Load blocks for this society
                      ),
                    );
                  },
                ),

          // TAB 2: BLOCKS & FLATS
          _selectedSocietyId.isEmpty
              ? const Center(child: Text('Select a Society from the first tab to manage its Blocks and Flats.'))
              : _isLoadingBlocks
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _blocks.length,
                      itemBuilder: (context, index) {
                        final b = _blocks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ExpansionTile(
                            title: Text(b['name'] ?? 'Unknown Block', style: const TextStyle(fontWeight: FontWeight.bold)),
                            children: [
                              FutureBuilder<List<dynamic>>(
                                future: TenantAdminService.getFlats(b['id']),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No flats.'));
                                  
                                  return Column(
                                    children: [
                                      ...snapshot.data!.map((f) => ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.meeting_room, size: 20),
                                        title: Text('Flat: ${f['flatNumber']}'),
                                        subtitle: Text('Type: ${f['type'] ?? 'N/A'}'),
                                      )).toList(),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () => _showAddFlatDialog(b['id']),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text('Add Flat'),
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
        ],
      ),
    );
  }
}