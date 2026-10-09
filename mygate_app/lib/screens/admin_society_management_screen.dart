// lib/screens/admin_society_management_screen.dart
import 'package:flutter/material.dart';
import 'admin_visitors_screen.dart';
import 'admin_notices_screen.dart';
import 'admin_helpdesk_screen.dart';
import 'admin_billing_screen.dart';
import 'admin_daily_help_screen.dart';
import 'admin_vehicle_screen.dart';
import 'admin_directory_screen.dart';
import 'admin_amenity_screen.dart';
import 'admin_guard_management_screen.dart';
import 'emergency_screen.dart';

class AdminSocietyManagementScreen extends StatelessWidget {
  const AdminSocietyManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _MgmtTile(title: 'Visitors', icon: Icons.people, color: Colors.blue, screen: const AdminVisitorsScreen()),
      _MgmtTile(title: 'Notices', icon: Icons.campaign, color: Colors.orange, screen: const AdminNoticeScreen()),
      _MgmtTile(title: 'Helpdesk', icon: Icons.support_agent, color: Colors.purple, screen: const AdminHelpdeskScreen()),
      _MgmtTile(title: 'Billing', icon: Icons.receipt_long, color: Colors.green, screen: const AdminBillingScreen()),
      _MgmtTile(title: 'Daily Help', icon: Icons.cleaning_services, color: Colors.pink, screen: const AdminDailyHelpScreen()),
      _MgmtTile(title: 'Vehicles', icon: Icons.directions_car, color: Colors.cyan, screen: const AdminVehicleScreen()),
      _MgmtTile(title: 'Directory', icon: Icons.contact_phone, color: Colors.teal, screen: const AdminDirectoryScreen()),
      _MgmtTile(title: 'Amenities', icon: Icons.pool, color: Colors.indigo, screen: const AdminAmenityScreen()),
      _MgmtTile(title: 'Guard Mgmt', icon: Icons.security, color: Colors.deepOrange, screen: const AdminGuardManagementScreen()),
      _MgmtTile(title: 'SOS / Emergency', icon: Icons.sos, color: Colors.red, screen: const EmergencyScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Management'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: tiles.map((tile) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tile.screen)),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tile.icon, size: 32, color: tile.color),
                  const SizedBox(height: 8),
                  Text(tile.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MgmtTile {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;
  _MgmtTile({required this.title, required this.icon, required this.color, required this.screen});
}