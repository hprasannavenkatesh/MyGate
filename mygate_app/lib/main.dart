import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyGateApp());
}

class MyGateApp extends StatelessWidget {
  const MyGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyGate Clone',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isOtpSent = false; // NEW: Tracks if we are on the OTP screen
  String? _jwtToken;      // NEW: Holds our wristband

  Future<void> _requestOtp() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5103/api/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': _mobileController.text}),
      );

      if (response.statusCode == 200) {
        setState(() => _isOtpSent = true); // Switch to OTP screen!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP Sent! Check your .NET terminal.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // NEW: Verify the OTP and get the Token!
  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5103/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': _mobileController.text,
          'otp': _otpController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Parse the JSON to get the token
        final data = jsonDecode(response.body);
        setState(() {
          _jwtToken = data['token'];
        });

        // Show a massive success popup with the token!
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Login Successful!'),
            content: Text('Your JWT Token is:\n\n$_jwtToken'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('Welcome to MyGate', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            
            // IF OTP NOT SENT, SHOW MOBILE FIELD
            if (!_isOtpSent) ...[
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestOtp,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send OTP', style: TextStyle(fontSize: 18)),
                ),
              ),
            ] else ...[
              // IF OTP SENT, SHOW OTP FIELD
              Text('Enter OTP sent to ${_mobileController.text}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: '4-Digit OTP',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.password),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify & Login', style: TextStyle(fontSize: 18)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}