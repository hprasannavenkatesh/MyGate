// lib/services/master_data_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class MasterDataService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // SUPERADMIN: Get all societies
  static Future<List<dynamic>> getAllSocieties() async {
    final headers = await _getHeaders();
    // Routes through IdentityService proxy (5103) as per architecture rules
    final response = await http.get(
      Uri.parse('${ApiConfig.identityService}/api/superadmin/societies'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load societies: ${response.body}');
  }

  // SUPERADMIN: Create a new society
  static Future<bool> createSociety(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.identityService}/api/superadmin/societies'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  // SUPERADMIN: Delete a society
  static Future<bool> deleteSociety(String societyId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConfig.identityService}/api/superadmin/societies/$societyId'),
      headers: headers,
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }
}