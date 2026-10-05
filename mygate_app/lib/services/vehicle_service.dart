// lib/services/vehicle_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class VehicleService {
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> getMyVehicles() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.vehiclesBaseUrl}/my-vehicles?societyId=$societyId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load vehicles');
  }

  static Future<bool> registerVehicle(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(ApiConfig.vehiclesBaseUrl),
      headers: headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 201;
  }
}