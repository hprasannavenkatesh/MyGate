// lib/services/guard_management_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class GuardManagementService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // ADMIN: Register a new Guard user in Identity Service
  static Future<Map<String, dynamic>?> registerGuard(String mobile, String fullName, String password) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(ApiConfig.registerUrl),
      headers: headers,
      body: jsonEncode({
        'mobileNumber': mobile,
        'fullName': fullName,
        'password': password,
        'role': 'Guard', // Explicitly force Guard role
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body); // Returns { id: "..." }
    }
    throw Exception('Failed to register guard: ${response.body}');
  }

  // ADMIN: Assign Guard to a Society as a member (Tenant Service)
  static Future<bool> assignGuardToSociety(String userId, String societyId) async {
    final headers = await _getHeaders();
    
    // We use the add-member endpoint. FlatId is Guid.Empty because Guards aren't assigned to flats.
    final response = await http.post(
      Uri.parse('${ApiConfig.societiesBaseUrl}/add-member'),
      headers: headers,
      body: jsonEncode({
        'societyId': societyId,
        'userId': userId,
        'flatId': "00000000-0000-0000-0000-000000000000", // Guid.Empty
        'memberType': "Guard",
        'isPrimary': false,
      }),
    );
    
    return response.statusCode == 200 || response.statusCode == 201;
  }
}