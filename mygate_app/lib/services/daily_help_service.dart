// lib/services/daily_help_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class DailyHelpService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }
// RESIDENT: Get assignments for my flat
  static Future<List<dynamic>> getMyDailyHelp() async {
    // FIX: The controller is AssignmentsController, and it expects flatId
    final flatId = await AuthService.getFlatId();
    final headers = await _getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.dailyHelpBaseUrl}/api/Assignments/my-help?flatId=$flatId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load daily help: ${response.body}');
  }

   // ADMIN: Get all Help Types for a society
  static Future<List<dynamic>> getHelpTypes() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.dailyHelpBaseUrl}/api/HelpTypes/society/$societyId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load help types');
  }

  // ADMIN: Create a new Help Type
  static Future<bool> createHelpType(String name) async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.dailyHelpBaseUrl}/api/HelpTypes'),
      headers: headers,
      body: jsonEncode({'societyId': societyId, 'name': name}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // ADMIN: Get all Staff for a society
  static Future<List<dynamic>> getStaff() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.dailyHelpBaseUrl}/api/Staff/society/$societyId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load staff');
  }

  // ADMIN: Create a new Staff member
  static Future<bool> createStaff(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.dailyHelpBaseUrl}/api/Staff'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // ADMIN: Assign Staff to a Flat
  static Future<bool> assignStaff(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.dailyHelpBaseUrl}/api/Assignments'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}