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
// RESIDENT: Get my vehicles
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
  // RESIDENT: Register a new vehicle
  static Future<bool> registerVehicle(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(ApiConfig.vehiclesBaseUrl),
      headers: headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 201;
  }

  // ADMIN: Get all vehicles for a society (for Parking Visualizer)
  static Future<List<dynamic>> getSocietyVehicles() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.vehiclesBaseUrl}/society/$societyId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load society vehicles');
  }

  // ADMIN: Get all parking slots for a society (for Parking Visualizer)
  static Future<List<dynamic>> getSocietyParkingSlots() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();
    // Note: URL uses ParkingSlots controller path relative to the VehicleService base
    final response = await http.get(
      Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots/society/$societyId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load parking slots');
  }

   // ADMIN: Assign a vehicle to a parking slot
  static Future<bool> assignParkingSlot({required String slotId, required String vehicleId, required String societyId}) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots/$slotId/assign?vehicleId=$vehicleId&societyId=$societyId'),
      headers: headers,
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // ADMIN: Unassign a vehicle from a parking slot
  static Future<bool> unassignParkingSlot({required String slotId, required String societyId}) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots/$slotId/unassign?societyId=$societyId'),
      headers: headers,
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }
}