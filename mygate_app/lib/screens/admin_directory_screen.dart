import 'package:flutter/material.dart';
import '../../services/directory_service.dart';
import '../../services/auth_service.dart'; // This is missing in Directory

class AdminDirectoryScreen extends StatefulWidget {
  const AdminDirectoryScreen({super.key});

  @override
  State<AdminDirectoryScreen> createState() => _AdminDirectoryScreenState();
}

class _AdminDirectoryScreenState extends State<AdminDirectoryScreen> {
  List<dynamic> _entries = [];
  List<String> _categories = [];
  String _selectedCategory = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDirectory();
  }

  Future<void> _fetchDirectory() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DirectoryService.getSocietyDirectory(),
        DirectoryService.getCategories(),
      ]);
      
      if (mounted) {
        setState(() {
          _entries = results[0];
          _categories = List<String>.from(results[1]);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredEntries {
    if (_selectedCategory.isEmpty) return _entries;
    return _entries.where((e) => e['category'] == _selectedCategory).toList();
  }

   // ==========================================
  // NEW: ADD / EDIT / DELETE LOGIC
  // ==========================================
  Future<void> _showAddEditDialog({Map<String, dynamic>? existingEntry}) async {
    final isEdit = existingEntry != null;
    
    final nameController = TextEditingController(text: isEdit ? existingEntry!['name'] : '');
    final contactController = TextEditingController(text: isEdit ? existingEntry!['contactNumber'] : '');
    final emailController = TextEditingController(text: isEdit ? existingEntry!['email'] ?? '' : '');
    final addressController = TextEditingController(text: isEdit ? existingEntry!['address'] ?? '' : '');
    final notesController = TextEditingController(text: isEdit ? existingEntry!['notes'] ?? '' : '');
    String selectedCategory = isEdit ? existingEntry!['category'] ?? 'Emergency' : 'Emergency';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Entry' : 'Add New Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: ['Emergency', 'Committee', 'Plumber', 'Electrician', 'Other']
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
                      onChanged: (val) => setDialogState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: contactController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Number *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (Optional)', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address (Optional)', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty || contactController.text.trim().isEmpty) return;

                    final societyId = await AuthService.getSocietyId();
                    final payload = {
                      'societyId': societyId,
                      'category': selectedCategory,
                      'name': nameController.text.trim(),
                      'contactNumber': contactController.text.trim(),
                      'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                      'address': addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                      'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    };

                    bool success;
                    if (isEdit) {
                      payload['id'] = existingEntry!['id']; // Add ID for update payload
                      success = await DirectoryService.updateEntry(payload);
                    } else {
                      success = await DirectoryService.addEntry(payload);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (success) {
                      _fetchDirectory();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isEdit ? 'Entry Updated!' : 'Entry Added!'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEntry(String entryId) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to remove this directory entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      final societyId = await AuthService.getSocietyId();
      final success = await DirectoryService.deleteEntry(entryId, societyId);
      if (success && mounted) {
        _fetchDirectory();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry Deleted'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Society Directory')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        tooltip: 'Add Entry',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Category Filter Chips
          if (_categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategory.isEmpty,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = '');
                      },
                    ),
                  ),
                  ..._categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = category);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          
          // Directory List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                    ? const Center(child: Text('No entries found.'))
                    : ListView.builder(
                        itemCount: _filteredEntries.length,
                        itemBuilder: (context, index) {
                          final e = _filteredEntries[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          e['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(e['category'] ?? '', style: const TextStyle(fontSize: 11)),
                                        backgroundColor: Colors.blue.shade50,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(e['contactNumber'] ?? 'N/A'),
                                    ],
                                  ),
                                  if (e['email'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.email, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(e['email'], style: const TextStyle(fontSize: 12))),
                                        ],
                                      ),
                                    ),
                                  if (e['address'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text('Address: ${e['address']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ),
                                     // NEW: Admin Action Buttons
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _showAddEditDialog(existingEntry: e),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Edit'),
                                        style: TextButton.styleFrom(foregroundColor: Colors.blue),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _deleteEntry(e['id']),
                                        icon: const Icon(Icons.delete_outline, size: 16),
                                        label: const Text('Delete'),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}