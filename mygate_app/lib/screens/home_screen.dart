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
   bool _isHybridAdmin = false; // True if Admin + Resident (Committee Member)

  @override
  void initState() {
    super.initState();
    _loadContext();
    _initSignalR(); 
  }

  Future<void> _loadContext() async {
    final prefs = await SharedPreferences.getInstance();
    final role = await AuthService.getUserRole();
     final flatId = await AuthService.getFlatId(); // Fetch flatId

      // HYBRID LOGIC: If they are an Admin BUT they also have a FlatId assigned,
    // it means they are a Committee Member/Owner acting as Admin.
    // Pure Admins or SuperAdmins won't have a FlatId in their context.
    final isHybrid = (role == 'Admin' || role == 'SuperAdmin') && flatId.isNotEmpty;
    
    setState(() {
      _userRole = role;
      _isHybridAdmin = isHybrid;
      _societyName = prefs.getString('society_name') ?? 'Unknown Society'; 
      _flatInfo = '${prefs.getString('block_name') ?? 'Block'} - ${prefs.getString('flat_number') ?? 'Flat'}';
    });
  }

  Future<void> _initSignalR() async {
    final societyId = await AuthService.getSocietyId();
    if (societyId.isEmpty) return;

    _hubConnection = HubConnectionBuilder()
        .withUrl("${ApiConfig.emergencyGateway}/api/hubs/emergency",
        options: HttpConnectionOptions(
          transport: HttpTransportType.WebSockets,
          logger: null,
        ))           
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

       // Show Resident features IF:
    // 1. They are a standard Resident (!isAdmin)
    // 2. OR They are a Hybrid Admin (Admin + has FlatId)
    bool showResidentFeatures = !isAdmin || _isHybridAdmin;

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
            color: isAdmin ? Colors.deepOrange.shade100 : Colors.indigo.shade100, // Visual cue for Admin
            child: Row(
              children: [
                Icon(isAdmin ? Icons.admin_panel_settings : Icons.apartment, color: isAdmin ? Colors.deepOrange : Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_societyName, style: TextStyle(fontWeight: FontWeight.bold, color: isAdmin ? Colors.deepOrange : Colors.indigo)),
                      Text('Role: $_userRole | $_flatInfo', style: TextStyle(color: isAdmin ? Colors.deepOrange : Colors.indigo, fontSize: 12)),
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

          // GRID MENU - ROLE BASED
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // FIXED SYNTAX
              child: GridView.count(
                crossAxisCount: 3, 
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.2, 
                children: [
                  // ==========================================
                  // ADMIN ROUTING
                  // ==========================================
                  if (isAdmin) 
                    _buildNavCard('Admin Panel', Icons.admin_panel_settings, const AdminManagementScreen(), color: Colors.deepOrange),
                  
                  // ==========================================
                  // RESIDENT-ONLY ACTIONS (Show for Residents, OR Hybrid Admins)
                  // ==========================================
                  //if (!isAdmin) ...[
                    if (showResidentFeatures) ...[
                    _buildNavCard('Visitors', Icons.people, const MyVisitorsScreen()),
                    _buildNavCard('Dues', Icons.receipt_long, const MyDuesScreen()),
                    _buildNavCard('Tickets', Icons.support_agent, const MyTicketsScreen()),
                    _buildNavCard('Amenities', Icons.pool, const AmenityHubScreen()), 
                    _buildNavCard('Daily Help', Icons.cleaning_services, const MyDailyHelpScreen()),
                    _buildNavCard('Vehicles', Icons.directions_car, const MyVehiclesScreen()),
                  ],
                  
                  // ==========================================
                  // COMMON ACTIONS (Visible to both Residents and Admins)
                  // ==========================================
                  _buildNavCard('Notices', Icons.campaign, const NoticeBoardScreen()),
                  _buildNavCard('Directory', Icons.contact_phone, const SocietyDirectoryScreen()),
                  _buildNavCard('SOS', Icons.sos, const EmergencyScreen(), color: Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Compact Card Button (Uses MaterialColor to access .shadeXXX safely)
  Widget _buildNavCard(String text, IconData icon, Widget screen, {MaterialColor? color}) {
    // Fallback to Colors.indigo if no color is provided
    final tileColor = color ?? Colors.indigo; 
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
              Icon(icon, size: 28, color: tileColor.shade400), 
              const SizedBox(height: 6),
              Text(
                text, 
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w600, 
                  color: tileColor.shade800 
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