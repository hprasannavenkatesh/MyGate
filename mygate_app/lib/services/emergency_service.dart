// lib/services/emergency_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class EmergencyService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Future<bool> triggerSOS(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
      // DEBUG: Print exactly what we are sending
    print('🔍 DEBUG SOS Payload: ${jsonEncode(payload)}');
    final response = await http.post(
      Uri.parse('${ApiConfig.emergencyService}/api/emergency/trigger'),
      headers: headers,
      body: jsonEncode(payload),
    );
      // DEBUG: Print exactly what the backend replied
    print('🔍 DEBUG SOS Status: ${response.statusCode}');
    print('🔍 DEBUG SOS Body: ${response.body}');

    //return response.statusCode == 200 || response.statusCode == 201;
     if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      // Throw the actual backend error so we can see it on the UI
      throw Exception('Failed (${response.statusCode}): ${response.body}');
    }
  }

    static Future<void> triggerPanic() async {
    final token = await AuthService.getToken();
    final societyId = await AuthService.getSocietyId();
    final flatId = await AuthService.getFlatId();

    final response = await http.post(
      Uri.parse('${ApiConfig.emergencyService}/api/Emergency/trigger'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'societyId': societyId,
        'flatId': flatId,
        'type': 0, // 0 = Panic enum
        'description': 'Panic button triggered by Guard'
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to trigger panic');
    }
  }
}