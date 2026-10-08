// lib/screens/guard_screen.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/emergency_service.dart';
import 'login_screen.dart';
import 'guard_verify_otp_screen.dart';
import 'guard_walk_in_screen.dart';
import 'guard_mark_exit_screen.dart';
import 'guard_active_visitors_screen.dart';

class GuardScreen extends StatefulWidget {
  final String token;
  const GuardScreen({super.key, required this.token});

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen> {
  String _societyName = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final prefs = await SharedPreferences.getInstance();
    final role = await AuthService.getUserRole();
    
    setState(() {
      _userRole = role;
      _societyName = prefs.getString('society_name') ?? 'Unknown Society';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Portal'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService.logout(); 
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            }
          ),
        ],
      ),
      body: Column(
        children: [
          // CONTEXT BANNER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_societyName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      Text('Role: $_userRole', style: const TextStyle(color: Colors.deepOrange, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // GRID MENU
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: GridView.count(
                crossAxisCount: 3, 
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.2,
                children: [
                  _buildNavCard('Verify OTP', Icons.password,  GuardVerifyOtpScreen()),
                  _buildNavCard('Walk In', Icons.login,  GuardWalkInScreen()),
                  _buildNavCard('Mark Exit', Icons.logout,  GuardMarkExitScreen()),
                  _buildNavCard('Inside Now', Icons.people_alt,  GuardActiveVisitorsScreen()),
                  _buildSosCard(), // Special SOS card
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Standard Nav Card
  Widget _buildNavCard(String text, IconData icon, Widget screen) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Colors.deepOrange.shade400), 
              const SizedBox(height: 6),
              Text(
                text, 
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w600, 
                  color: Colors.deepOrange.shade800 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SPECIAL: SOS Panic Card
  Widget _buildSosCard() {
    return Card(
      elevation: 3,
      color: Colors.red.shade50, // Fixed color shade
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.red, width: 2)),
      child: InkWell(
        onTap: () => _triggerPanic(),
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sos, size: 32, color: Colors.red), 
              SizedBox(height: 6),
              Text(
                'SOS', 
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.red 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _triggerPanic() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🚨 Trigger SOS?'),
        content: const Text('This will broadcast an emergency alert to all residents and admins in the society.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('TRIGGER SOS')),
        ],
      )
    );

    if (confirm == true) {
      try {
        await EmergencyService.triggerPanic(); 
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ SOS Broadcasted!'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }
}