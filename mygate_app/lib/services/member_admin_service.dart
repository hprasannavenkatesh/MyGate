//Context: The React portal has an AssignMember page that looks up users by mobile number, registers them if they don't exist, and assigns them to flats. We need a dedicated service in Flutter to hit the IdentityService lookup endpoint, and we also need a method to create Guards (which the React portal has).

// lib/services/member_admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class MemberAdminService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // ADMIN: Lookup a user by mobile number to check if they exist before registering
  // Matches GET /api/auth/lookup/{mobileNumber} on IdentityService
  static Future<Map<String, dynamic>?> lookupUserByMobile(String mobileNumber) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.identityService}/api/auth/lookup/$mobileNumber'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      return null; // User not found, safe to register
    }
    throw Exception('Failed to lookup user: ${response.body}');
  }

  // ADMIN: Register a new Guard user
  // Matches POST /api/auth/create-guard on IdentityService
  static Future<Map<String, dynamic>> createGuard(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.identityService}/api/auth/create-guard'),
      headers: headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to register guard: ${response.body}');
  }
}