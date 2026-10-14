// lib/screens/society_selection_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../services/master_data_service.dart';

class SocietySelectionScreen extends StatefulWidget {
  final String token;
  const SocietySelectionScreen({super.key, required this.token});

  @override
  State<SocietySelectionScreen> createState() => _SocietySelectionScreenState();
}

class _SocietySelectionScreenState extends State<SocietySelectionScreen> {
  List<dynamic> _societies = [];
  bool _isLoading = true;

 /* Future<void> _fetchSocieties() async {
    try {
      final userId = await AuthService.getUserId();
       final role = await AuthService.getUserRole(); // Get the role
         final token = await AuthService.getToken(); // Safer to get fresh token from storage
debugPrint('🔍 DEBUG fetchSocieties: Role=$role, UserId=$userId');
          List<dynamic>societies=[];

      /*final response = await http.get(
        Uri.parse('${ApiConfig.mySocietiesUrl}?userId=$userId'),
        //headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
         headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );*/
       if (role == 'SuperAdmin') {
        // SUPERADMIN: Fetch ALL societies via IdentityService Proxy (5103)
        // We reuse=use MasterDataService which correctly hits the proxy
          debugPrint('🔍 DEBUG: Fetching ALL societies via SuperAdmin proxy...');
        societies = await MasterDataService.getAllSocieties();
         debugPrint('🔍 DEBUG: SuperAdmin fetch complete. Count=${societies.length}');
        if (societies.isNotEmpty) {
          debugPrint('🔍 DEBUG: First society keys: ${societies[0].keys.toList()}');
          debugPrint('🔍 DEBUG: First society data: ${societies[0]}');
        }
          } else {
        // RESIDENT/ADMIN: Fetch only societies they belong! belong to via TenantService (5104)
         debugPrint('🔍 DEBUG: Fetching MY societies via Tenant service...');
        final response = await http.get(
          Uri.parse('${ApiConfig.mySocietiesUrl}?userId=$userId'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        );
          debugPrint('🔍 DEBUG: MySocieties response status=${response.statusCode}');
        debugPrint('🔍 DEBUG: MySocieties response body=${response.body}');
      if (response.statusCode == 200) {
        setState(() { _societies = jsonDecode(response.body); _isLoading = false; });
      } else {  _showError('Failed to load societies (${response.statusCode}): ${response.body}'); }
          }
           if (mounted) {
        debugPrint('🔍 DEBUG: Setting state. Societies count=${societies.length}, isLoading=false');
        setState(() { 
          _societies = societies; 
          _isLoading = false; 
        });
      }
    } catch (e) {  
        debugPrint('❌ DEBUG ERROR in _fetchSocieties: $e');
      _showError('Error: $e'); setState(() => _isLoading = false); }
  }*/

  Future<void> _fetchSocieties() async {
    try {
      final userId = await AuthService.getUserId();
      final role = await AuthService.getUserRole();
      final token = await AuthService.getToken();
      
      List<dynamic> societies = [];

      if (role == 'SuperAdmin') {
        // SuperAdmins always see all societies
        societies = await MasterDataService.getAllSocieties();
      } else if (role == 'Admin') {
        // Admins: First try to get their assigned flats
        final response = await http.get(
          Uri.parse('${ApiConfig.mySocietiesUrl}?userId=$userId'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          societies = jsonDecode(response.body);
        }

        // FALLBACK: If an Admin has no flats assigned, fetch all societies 
        // so they can at least select the Society Context to access the Admin Panel
        if (societies.isEmpty) {
          societies = await MasterDataService.getAllSocieties();
        }
      } else {
        // Residents MUST have flats
        final response = await http.get(
          Uri.parse('${ApiConfig.mySocietiesUrl}?userId=$userId'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          societies = jsonDecode(response.body);
        }
      }

      if (mounted) {
        setState(() { 
          _societies = societies; 
          _isLoading = false; 
        });
      }
    } catch (e) {  
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() { super.initState(); _fetchSocieties(); }

/*
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Flat'), actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
           await AuthService.logout();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  LoginScreen()));
        })
      ]),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _societies.length,
        itemBuilder: (context, index) {
          final society = _societies[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.apartment, color: Colors.blue, size: 40),
              title: Text(society['societyName'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Block: ${society['blockName']} - Flat: ${society['flatNumber']}'),
              trailing: Chip(label: Text(society['memberType']), backgroundColor: Colors.blue.withOpacity(0.1)),
            // Inside society_selection_screen.dart -> onTap
onTap: () async {
  final currentToken = await AuthService.getToken();
  final userId = await AuthService.getUserId();
  //await prefs.setString('flat_number', society['flatNumber'] ?? ''); 

  try {
    final response = await http.post(
      Uri.parse(ApiConfig.selectContextUrl),
      headers: {'Authorization': 'Bearer $currentToken', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'societyId': society['societyId'],
        'flatId': society['flatId'],
        'memberType': society['memberType']
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newContextToken = data['token'];

      await AuthService.cacheTokenClaims(newContextToken);     
      final prefs = await SharedPreferences.getInstance();
            
      // Save IDs
      await prefs.setString('society_id', society['societyId']);
      await prefs.setString('flat_id', society['flatId']);
      
      // SAVE HUMAN-READABLE NAMES
      await prefs.setString('society_name', society['societyName'] ?? '');
      await prefs.setString('block_name', society['blockName'] ?? '');
      await prefs.setString('flat_number', society['flatNumber'] ?? ''); 
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    } else {
      _showError('Failed to generate context token');
    }
  } catch (e) {
    _showError('Error: $e');
  }
}
            ),
          );
        },
      ),
    );
  }
  */

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Context'), 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () async {
              await AuthService.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            }
          )
        ]
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _societies.isEmpty 
              ? const Center(child: Text('No entries found.'))
              : FutureBuilder<String>(
                  // Fetch role dynamically to adjust UI text
                  future: AuthService.getUserRole(),
                  builder: (context, roleSnapshot) {
                    final role = roleSnapshot.data ?? '';
                    
                    // Determine UI text based on role
                    String pageTitle;
                    String emptyStateText;
                    
                    if (role == 'SuperAdmin') {
                      pageTitle = 'Select Society to Manage';
                      emptyStateText = 'No societies found in the system.';
                    } else if (role == 'Admin') {
                      pageTitle = 'Select Your Flat / Society';
                      emptyStateText = 'No flats or societies assigned.';
                    } else {
                      pageTitle = 'Select Your Flat';
                      emptyStateText = 'No flats assigned to your account.';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            pageTitle,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                        ),
                        
                        // List Body
                        Expanded(
                          child: ListView.builder(
                            itemCount: _societies.length,
                            itemBuilder: (context, index) {
                              final society = _societies[index];
                              
                              // Safely map properties
                              final societyName = society['societyName']?.toString() ?? society['name']?.toString() ?? 'Unknown Society';
                              final societyId = society['societyId']?.toString() ?? society['id']?.toString() ?? '';
                              final blockName = society['blockName']?.toString() ?? '';
                              final flatNumber = society['flatNumber']?.toString() ?? '';
                              final memberType = society['memberType']?.toString() ?? (role == 'SuperAdmin' ? 'SuperAdmin' : 'Admin');

                              // Format subtitle based on role and available data
                              String subtitleText;
                              if (role == 'SuperAdmin') {
                                subtitleText = 'Global Access (Tap to manage)';
                              } else if (blockName.isNotEmpty && flatNumber.isNotEmpty) {
                                subtitleText = 'Block: $blockName - Flat: $flatNumber';
                              } else {
                                subtitleText = 'Society Management';
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: Icon(
                                    role == 'SuperAdmin' ? Icons.admin_panel_settings : Icons.apartment, 
                                    color: role == 'SuperAdmin' ? Colors.deepOrange : Colors.blue, 
                                    size: 40
                                  ),
                                  title: Text(societyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(subtitleText),
                                  trailing: Chip(
                                    label: Text(memberType), 
                                    backgroundColor: (memberType == 'SuperAdmin' || memberType == 'Admin') 
                                        ? Colors.deepOrange.withOpacity(0.1) 
                                        : Colors.blue.withOpacity(0.1)
                                  ),
                                  onTap: () async {
                                    final currentToken = await AuthService.getToken();
                                    final userId = await AuthService.getUserId();

                                    try {
                                      // Safely map IDs
                                        final societyId = society['societyId']?.toString() ?? society['id']?.toString() ?? '';
                                        final flatId = society['flatId']?.toString() ?? "00000000-0000-0000-0000-000000000000"; // Default to Guid.Empty
                                        final response = await http.post(
                                        Uri.parse(ApiConfig.selectContextUrl),
                                        headers: {'Authorization': 'Bearer $currentToken', 'Content-Type': 'application/json'},
                                        body: jsonEncode({
                                          'userId': userId,
                                          'societyId': societyId,
                                          // SuperAdmins don't have flats, pass Guid.Empty
                                          //'flatId': society['flatId'] ?? "00000000-0000-0000-0000-000000000000",
                                          'flatId': flatId,
                                          //'memberType': memberType
                                          'memberType': society['memberType'] ?? 'Admin'
                                        }),
                                      );

                                      if (response.statusCode == 200) {
                                        final data = jsonDecode(response.body);
                                        final newContextToken = data['token'];

                                        await AuthService.cacheTokenClaims(newContextToken);     
                                        final prefs = await SharedPreferences.getInstance();
                                              
                                        await prefs.setString('society_id', societyId);
                                        await prefs.setString('flat_id', society['flatId'] ?? '');
                                        await prefs.setString('society_name', societyName);
                                        await prefs.setString('block_name', blockName);
                                        await prefs.setString('flat_number', flatNumber); 
                                        
                                        if (mounted) {
                                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                                        }
                                      } else {
                                        _showError('Failed to generate context token: ${response.body}');
                                      }
                                    } catch (e) {
                                      _showError('Error: $e');
                                    }
                                  }
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }
                ),
    );
  }
}