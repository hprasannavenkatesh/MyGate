// lib/screens/amenity_hub_screen.dart
import 'package:flutter/material.dart';
import 'amenity_list_screen.dart';
import 'my_bookings_screen.dart';

class AmenityHubScreen extends StatefulWidget {
  const AmenityHubScreen({super.key});

  @override
  State<AmenityHubScreen> createState() => _AmenityHubScreenState();
}

class _AmenityHubScreenState extends State<AmenityHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amenities'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,               // Active tab text
          unselectedLabelColor: Colors.white60,    // Inactive tab text
          indicatorSize: TabBarIndicatorSize.tab,  // Makes indicator span whole tab width
          indicator: BoxDecoration(
            color: Colors.orange.shade700,         // Bright orange background for active tab
            borderRadius: BorderRadius.circular(8),
          ),
          tabs: const [
            Tab(
              iconMargin: EdgeInsets.only(bottom: 4),
              icon: Icon(Icons.pool, size: 20), 
              text: 'Book',
            ),
            Tab(
              iconMargin: EdgeInsets.only(bottom: 4),
              icon: Icon(Icons.history, size: 20), 
              text: 'My Bookings',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AmenityListScreen(),
          MyBookingsScreen(),
        ],
      ),
    );
  }
}