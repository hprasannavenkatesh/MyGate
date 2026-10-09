// lib/services/tenant_admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'auth_service.dart';

class TenantAdminService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // READ
  static Future<List<dynamic>> getBlocks(String societyId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${ApiConfig.societiesBaseUrl}/$societyId/blocks'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load blocks');
  }


  static Future<List<dynamic>> getFlats(String blockId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${ApiConfig.societiesBaseUrl}/blocks/$blockId/flats'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load flats');
  }

  // COMMANDS
  static Future<bool> createSociety(String name, String address, String city) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('${ApiConfig.societiesBaseUrl}/create'), headers: headers, body: jsonEncode({'name': name, 'address': address, 'city': city}));
    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> createBlock(String societyId, String name) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('${ApiConfig.societiesBaseUrl}/create-block'), headers: headers, body: jsonEncode({'societyId': societyId, 'name': name}));
    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> createFlat(String blockId, String societyId, String flatNumber, String type) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('${ApiConfig.societiesBaseUrl}/create-flat'), headers: headers, body: jsonEncode({'blockId': blockId, 'societyId': societyId, 'flatNumber': flatNumber, 'type': type}));
    return response.statusCode == 201 || response.statusCode == 200;
  }

/*
  static Future<Map<String, dynamic>?> registerUser(String mobile, String fullName, String password, [String? email]) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse(ApiConfig.registerUrl), headers: headers, body: jsonEncode({'mobileNumber': mobile, 'fullName': fullName, 'password': password, 'email': email}));
    if (response.statusCode == 201 || response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to register user');
  }*/
   // COMMAND: Register User (IdentityService) - Returns dynamic to capture the new UserId
  static Future<Map<String, dynamic>?> registerUser(String mobile, String fullName, String password, [String? email, String? role]) async {
    final headers = await _getHeaders();
    final payload = {
      'mobileNumber': mobile,
      'fullName': fullName,
      'password': password,
      'role': role ?? 'Resident', // Default to Resident if not specified
    };
    if (email != null) payload['email'] = email;

    final response = await http.post(Uri.parse(ApiConfig.registerUrl), headers: headers, body: jsonEncode(payload));
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to register user: ${response.body}');
  }

   // ADMIN: Get ALL societies (for Master Data root list - matches React MasterData.tsx)
  static Future<List<dynamic>> getAllSocieties() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(ApiConfig.societiesBaseUrl), // GET /api/societies
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load societies');
  }
   // COMMAND: Add Member to Flat (Matches .NET AddMemberCommand)
  static Future<bool> addMember(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('${ApiConfig.societiesBaseUrl}/add-member'), headers: headers, body: jsonEncode(payload));
    return response.statusCode == 201 || response.statusCode == 200;
  }


 



 
}