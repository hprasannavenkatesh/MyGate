// lib/screens/home_screen.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart' hide ConnectionState;
import '../services/auth_service.dart';
import '../services/api_config.dart';
import 'login_screen.dart';
import 'society_selection_screen.dart';
import 'my_visitors_screen.dart';
import 'my_dues_screen.dart';
import 'my_tickets_screen.dart';
import 'notice_board_screen.dart';
import 'amenity_hub_screen.dart'; // Merged Hub
import 'my_daily_help_screen.dart';
import 'my_vehicles_screen.dart';
import 'society_directory_screen.dart';
import 'emergency_screen.dart';
import 'admin_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HubConnection _hubConnection;
  bool _isHubConnected = false;

  // Context state
  String _societyName = '';
  String _flatInfo = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadContext();
    _initSignalR(); 
  }
/*
  Future<void> _loadContext() async {
    final societyId = await AuthService.getSocietyId();
    final flatId = await AuthService.getFlatId();
    final role = await AuthService.getUserRole();
    
    // You can expand this to fetch the actual Society Name from an API if needed
    // For now, showing the IDs so the user knows exactly which context they are in.
    setState(() {
      _userRole = role;
      _societyName = 'Society: $societyId'; 
      _flatInfo = 'Flat: $flatId';
    });
  }*/
    Future<void> _loadContext() async {
    final prefs = await SharedPreferences.getInstance();
    final role = await AuthService.getUserRole();
    
    setState(() {
      _userRole = role;
      _societyName = prefs.getString('society_name') ?? 'Unknown Society'; 
      _flatInfo = '${prefs.getString('block_name') ?? 'Block'} - ${prefs.getString('flat_number') ?? 'Flat'}';
    });
  }

  Future<void> _initSignalR() async {
    final societyId = await AuthService.getSocietyId();
    if (societyId.isEmpty) return;

    _hubConnection = HubConnectionBuilder()
        .withUrl("${ApiConfig.emergencyGateway}/hubs/emergency")
        .withAutomaticReconnect()
        .build();

    _hubConnection.on("ReceiveEmergencyAlert", (message) {
      if (mounted) _showEmergencyPopup(message);
    });

    try {
      await _hubConnection.start();
      await _hubConnection.invoke("JoinSocietyGroup", args: [societyId]);
      setState(() => _isHubConnected = true);
    } catch (e) {
      debugPrint("SignalR init failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if user is an Admin type
    bool isAdmin = _userRole == 'Admin' || _userRole == 'SuperAdmin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyGate Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz), 
            tooltip: 'Switch Society/Flat',
            onPressed: () async {
              final token = await AuthService.getToken();
              if (mounted) {
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (context) => SocietySelectionScreen(token: token))
                );
              }
            }
          ),
          IconButton(
            icon: const Icon(Icons.logout), 
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService.logout(); 
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
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
            color: Colors.indigo.shade100,
            child: Row(
              children: [
                const Icon(Icons.apartment, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_societyName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      Text(_flatInfo, style: const TextStyle(color: Colors.indigo, fontSize: 12)),
                    ],
                  ),
                ),
                if (_isHubConnected)
                  const Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('SOS Active', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ),

          // GRID MENU
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: GridView.count(
                crossAxisCount: 3, // 3 columns to save vertical space
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.2, // Makes cards shorter
                children: [
                  _buildNavCard('Visitors', Icons.people, const MyVisitorsScreen()),
                  _buildNavCard('Dues', Icons.receipt_long, const MyDuesScreen()),
                  _buildNavCard('Tickets', Icons.support_agent, const MyTicketsScreen()),
                  _buildNavCard('Notices', Icons.campaign, const NoticeBoardScreen()),
                  _buildNavCard('Amenities', Icons.pool, const AmenityHubScreen()), // Merged Hub
                  _buildNavCard('Daily Help', Icons.cleaning_services, const MyDailyHelpScreen()),
                  _buildNavCard('Vehicles', Icons.directions_car, const MyVehiclesScreen()),
                  _buildNavCard('Directory', Icons.contact_phone, const SocietyDirectoryScreen()),
                  _buildNavCard('Emergency', Icons.sos, const EmergencyScreen()),
                  
                  // HIDE ADMIN FOR RESIDENTS
                  if (isAdmin) 
                    _buildNavCard('Admin', Icons.admin_panel_settings, const AdminManagementScreen()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Compact Card Button
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
              Icon(icon, size: 28, color: Colors.indigo.shade400), 
              const SizedBox(height: 6),
              Text(
                text, 
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w600, 
                  color: Colors.indigo.shade800 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyPopup(dynamic messageData) {
    String description = "Emergency Alert Triggered!";
    if (messageData is Map) {
      description = messageData['description'] ?? description;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.yellow, size: 40),
              SizedBox(width: 10),
              Text('EMERGENCY ALERT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(description, style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5), textAlign: TextAlign.center),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
                child: const Text('ACKNOWLEDGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    try {
      if (_hubConnection.state != HubConnectionState.Disconnected) {
        _hubConnection.stop();
      }
    } catch (e) {
      debugPrint("SignalR dispose skipped: $e");
    }
    super.dispose();
  }
}