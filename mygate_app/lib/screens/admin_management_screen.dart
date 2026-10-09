// lib/screens/admin_management_screen.dart
import 'package:flutter/material.dart';
import 'admin_blocks_flats_screen.dart'; 
import 'admin_register_user_screen.dart'; 
import 'admin_society_management_screen.dart'; // NEW IMPORT

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header context
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.indigo, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Society Administration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                        SizedBox(height: 4),
                        Text('Manage structure, users, and society operations.', style: TextStyle(fontSize: 12, color: Colors.indigo)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // The 3 Requested Tiles
            _buildAdminTile(
              context,
              title: 'Blocks & Flats',
              subtitle: 'Create blocks and associate flats',
              icon: Icons.apartment,
              color: Colors.brown,
              screen: const AdminBlocksFlatsScreen(),
            ),
            const SizedBox(height: 16),
            _buildAdminTile(
              context,
              title: 'Register User',
              subtitle: 'Register new users to the society',
              icon: Icons.person_add,
              color: Colors.blue,
              screen: const AdminRegisterUserScreen(),
            ),
            const SizedBox(height: 16),
            _buildAdminTile(
              context,
              title: 'Society Management',
              subtitle: 'Visitors, Notices, Billing, Helpdesk, etc.',
              icon: Icons.manage_accounts,
              color: Colors.deepOrange,
              screen: const AdminSocietyManagementScreen(), // ROUTES TO NEW SCREEN
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}