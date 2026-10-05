// lib/screens/society_directory_screen.dart
import 'package:flutter/material.dart';
import '../services/directory_service.dart';

class SocietyDirectoryScreen extends StatefulWidget {
  const SocietyDirectoryScreen({super.key});

  @override
  State<SocietyDirectoryScreen> createState() => _SocietyDirectoryScreenState();
}

class _SocietyDirectoryScreenState extends State<SocietyDirectoryScreen> {
  List<dynamic> _entries = [];
  List<dynamic> _filteredEntries = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final entries = await DirectoryService.getSocietyDirectory();
      if (mounted) {
        setState(() {
          _entries = entries;
          _filteredEntries = _entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filteredEntries = _entries);
    } else {
      setState(() {
        _filteredEntries = _entries.where((e) {
          final name = (e['name'] ?? '').toLowerCase();
          final number = (e['contactNumber'] ?? '').toLowerCase();
          final category = (e['category'] ?? '').toLowerCase();
          return name.contains(query.toLowerCase()) || 
                 number.contains(query.toLowerCase()) ||
                 category.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Map<String, List<dynamic>> _groupedByCategory() {
    final map = <String, List<dynamic>>{};
    for (var entry in _filteredEntries) {
      final cat = entry['category'] ?? 'Other';
      if (!map.containsKey(cat)) map[cat] = [];
      map[cat]!.add(entry);
    }
    return map;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedByCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Directory'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearch,
              decoration: InputDecoration(
                hintText: 'Search by name, number, or category...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                    ? const Center(child: Text('No contacts found.', style: TextStyle(fontSize: 18, color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, index) {
                          final category = grouped.keys.elementAt(index);
                          final contacts = grouped[category]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Text(
                                  category.toUpperCase(),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.brown, letterSpacing: 1.2),
                                ),
                              ),
                              // Contacts in this category
                              for (var contact in contacts)
                                Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.brown.shade100,
                                      child: Text(
                                        contact['name'][0],
                                        style: TextStyle(color: Colors.brown.shade800, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(contact['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(contact['contactNumber'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                          ],
                                        ),
                                        if (contact['address'] != null && contact['address'].isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    contact['address'], 
                                                    style: const TextStyle(color: Colors.grey, fontSize: 12), 
                                                    overflow: TextOverflow.ellipsis
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.call, color: Colors.green),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Call ${contact['contactNumber']}'))
                                        );
                                      },
                                    ),
                                  ), // End of ListTile
                                ), // End of Card
                            ], // End of Column children
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}