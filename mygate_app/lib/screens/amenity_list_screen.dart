// lib/screens/amenity_list_screen.dart
import 'package:flutter/material.dart';
import '../services/amenity_service.dart';
import 'book_amenity_screen.dart';

class AmenityListScreen extends StatefulWidget {
  const AmenityListScreen({super.key});

  @override
  State<AmenityListScreen> createState() => _AmenityListScreenState();
}

class _AmenityListScreenState extends State<AmenityListScreen> {
  List<dynamic> _amenities = [];
  bool _isLoading = true;
  String? _errorMessage; // ADDED: To capture API errors

  @override
  void initState() {
    super.initState();
    _fetchAmenities();
  }

  Future<void> _fetchAmenities() async {
    try {
      final amenities = await AmenityService.getAmenities();
      if (mounted) {
        setState(() {
          _amenities = amenities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString(); // CAPTURE ERROR
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ADDED: Wrap in Scaffold so it doesn't vanish in a TabView
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Failed to load amenities.\n\nError: $_errorMessage', 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 14)
                    ),
                  ),
                )
              : _amenities.isEmpty
                  ? const Center(
                      child: Text(
                        'No amenities configured for this society yet.', 
                        style: TextStyle(fontSize: 16, color: Colors.grey)
                      )
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _amenities.length,
                      itemBuilder: (context, index) {
                        final a = _amenities[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.pool, color: Colors.indigo, size: 40),
                            title: Text(a['name'] ?? 'Amenity', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(a['description'] ?? 'Available for booking'),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => BookAmenityScreen(
                                    amenityId: a['id'] ?? '', 
                                    amenityName: a['name'] ?? 'Amenity'
                                  )
                                )
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}