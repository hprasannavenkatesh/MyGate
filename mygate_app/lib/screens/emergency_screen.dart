// lib/screens/emergency_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/emergency_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _isSOS = false;

  Future<void> _triggerSOS() async {
    setState(() => _isSOS = true);
    try {
      final societyId = await AuthService.getSocietyId();
      final flatId = await AuthService.getFlatId();
      
      // FIX: Payload strictly matches C# TriggerPanicCommand
      final isSuccess = await EmergencyService.triggerSOS({
        'societyId': societyId,
        'flatId': flatId,               
        'type': 0,                      // ADDED: Integer representation of EmergencyType Enum (0 is usually the first enum value, e.g., 'General' or 'Medical')
        'description': 'PANIC/SOS Button Pressed by Resident!',
      });

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚨 Emergency Alert Broadcasted!'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSOS = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency / SOS'), backgroundColor: Colors.red),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Press the button to alert Security and Society Members', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            SizedBox(
              height: 150,
              width: 150,
              child: ElevatedButton(
                onPressed: _isSOS ? null : _triggerSOS,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: const CircleBorder(), elevation: 10),
                child: _isSOS 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Icon(Icons.sos, size: 80, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}