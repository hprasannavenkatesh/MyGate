// lib/services/directory_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class DirectoryService {
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> getSocietyDirectory() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.directoryBaseUrl}?societyId=$societyId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load directory');
  }

  // ADMIN: Get unique categories for filter chips (matches React parity)
  static Future<List<dynamic>> getCategories() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.directoryBaseUrl}/categories/$societyId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load directory categories');
  }

    static Future<bool> addEntry(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('${ApiConfig.directoryBaseUrl}'), headers: headers, body: jsonEncode(payload));
    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> updateEntry(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final entryId = payload['id'];
    final response = await http.put(Uri.parse('${ApiConfig.directoryBaseUrl}/$entryId'), headers: headers, body: jsonEncode(payload));
    return response.statusCode == 204 || response.statusCode == 200;
  }

  static Future<bool> deleteEntry(String entryId, String societyId) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('${ApiConfig.directoryBaseUrl}/$entryId?societyId=$societyId'), headers: headers);
    return response.statusCode == 204 || response.statusCode == 200;
  }
}