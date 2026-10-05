// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';
import 'society_selection_screen.dart'; 
import 'guard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGuardMode = false; 
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _jwtToken;

  Future<void> _navigateToGuardWithContext(String basicToken) async {
    try {
      final userId = await AuthService.getUserId();

      final response = await http.get(
        Uri.parse('${ApiConfig.mySocietiesUrl}?userId=$userId'),
        headers: {'Authorization': 'Bearer $basicToken', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final societies = jsonDecode(response.body) as List;
        if (societies.isEmpty) throw Exception('No society assigned to this guard.');

        final society = societies[0];
        final contextResponse = await http.post(
          Uri.parse(ApiConfig.selectContextUrl),
          headers: {'Authorization': 'Bearer $basicToken', 'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'societyId': society['societyId'],
            'flatId': society['flatId'],
            'memberType': society['memberType'],
          }),
        );

        if (contextResponse.statusCode == 200) {
          final data = jsonDecode(contextResponse.body);
          final fatToken = data['token'];

          await AuthService.cacheTokenClaims(fatToken);   
          final prefs = await SharedPreferences.getInstance(); // Keep for local fallbacks if needed
          await prefs.setString('society_id', society['societyId']);
          await prefs.setString('flat_id', society['flatId']);
          await prefs.setString('flat_number', society['flatNumber']);

          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx) => GuardScreen(token: fatToken)));
          }
        } else {
          throw Exception('Failed to generate guard context token.');
        }
      } else {
        throw Exception('Failed to fetch guard societies.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guard Login Error: $e')));
      }
    }
  }

  Future<void> _requestOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.requestOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': _mobileController.text}),
      );
      if (response.statusCode == 200) setState(() => _isOtpSent = true);
      else _showError('Failed to send OTP');
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': _mobileController.text, 'otp': _otpController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _jwtToken = data['token']);
        
        await AuthService.cacheTokenClaims(_jwtToken!);

        if (_isGuardMode) {
          _navigateToGuardWithContext(_jwtToken!);
        } else {
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SocietySelectionScreen(token: _jwtToken!)));
        }
      } else {
        _showError('Invalid OTP');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isGuardMode ? Icons.security : Icons.lock_person, size: 80, color: _isGuardMode ? Colors.orange : Colors.blue),
            const SizedBox(height: 20),
            Text(_isGuardMode ? 'Guard Portal' : 'Welcome to MyGate', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            
            TextButton.icon(
              onPressed: () => setState(() => _isGuardMode = !_isGuardMode),
              icon: Icon(_isGuardMode ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.orange),
              label: const Text('Login as Security Guard', style: TextStyle(color: Colors.orange)),
            ),
            const SizedBox(height: 40),
            
            if (!_isOtpSent) ...[
              TextField(controller: _mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _requestOtp, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send OTP', style: TextStyle(fontSize: 18)))),
            ] else ...[
              TextField(controller: _otpController, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: '4-Digit OTP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.password))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _verifyOtp, style: ElevatedButton.styleFrom(backgroundColor: _isGuardMode ? Colors.orange : Colors.green), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Verify & Login', style: TextStyle(fontSize: 18)))),
            ]
          ],
        ),
      ),
    );
  }
}