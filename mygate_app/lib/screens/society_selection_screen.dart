// lib/screens/society_selection_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SocietySelectionScreen extends StatefulWidget {
  final String token;
  const SocietySelectionScreen({super.key, required this.token});

  @override
  State<SocietySelectionScreen> createState() => _SocietySelectionScreenState();
}

class _SocietySelectionScreenState extends State<SocietySelectionScreen> {
  List<dynamic> _societies = [];
  bool _isLoading = true;

  Future<void> _fetchSocieties() async {
    try {
      final userId = await AuthService.getUserId();
      final response = await http.get(
        Uri.parse('${ApiConfig.mySocietiesUrl}?userId=$userId'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() { _societies = jsonDecode(response.body); _isLoading = false; });
      } else { _showError('Failed to load societies'); }
    } catch (e) {  
      _showError('Error: $e'); setState(() => _isLoading = false); }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() { super.initState(); _fetchSocieties(); }

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
}