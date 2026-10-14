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
       if (response.statusCode == 200 || response.statusCode == 201) return true;
     // EXTRACT THE REAL ERROR MESSAGE FROM BACKEND
    if (response.statusCode == 400) {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Validation failed');
      } catch (e) {
        throw Exception('Validation failed: ${response.body}');
      }
    }
    
    throw Exception('Failed to register vehicle');
    //return response.statusCode == 201;
  }

  // ADMIN: Get all vehicles for a society (for Parking Visualizer)
  static Future<List<dynamic>> getSocietyVehicles() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();

    if (societyId.isEmpty || !societyId.contains('-')) {
      print('⚠️ WARNING: getSocietyVehicles aborted. SocietyId is invalid: $societyId');
      return []; 
    }

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

    // ADD THIS GUARD: Prevent bad GUID calls
    if (societyId.isEmpty || !societyId.contains('-')) {
      print('⚠️ WARNING: getSocietyParkingSlots aborted. SocietyId is invalid: $societyId');
      return []; 
    }

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
    // 🚨 GUARD: Abort if societyId is invalid
    if (societyId.isEmpty || !societyId.contains('-')) {
      print('⚠️ ERROR: Cannot assign slot. SocietyId is invalid: $societyId');
      return false;
    }

     // FIX: Send payload as JSON Body to match backend [FromBody] expectation
    final payload = {
      'slotId': slotId,
      'vehicleId': vehicleId,
      'societyId': societyId
    };


    final response = await http.put(
      //Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots/$slotId/assign?vehicleId=$vehicleId&societyId=$societyId'),
      Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots/$slotId/assign'),
      headers: headers,
      body: jsonEncode(payload),
    );
      if (response.statusCode != 204 && response.statusCode != 200) {
      print('❌ Assign Slot Failed: ${response.statusCode} ${response.body}');
    }
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // ADMIN: Unassign a vehicle from a parking slot
  static Future<bool> unassignParkingSlot({required String slotId, required String societyId}) async {
    final headers = await _getHeaders();
   /* final response = await http.put(
      Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots/$slotId/unassign?societyId=$societyId'),
      headers: headers,
    );*/
     final payload = {
      'slotId': slotId,
      'vehicleId': '', // Empty signals removal
      'societyId': societyId
    };

    final response = await http.put(
      Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots/$slotId/unassign?societyId=$societyId'),
      headers: headers,
      body: jsonEncode(payload),
    );
     if (response.statusCode != 204 && response.statusCode != 200) {
      print('❌ Unassign Slot Failed: ${response.statusCode} ${response.body}');
    }
    return response.statusCode == 204 || response.statusCode == 200;
  }

    // ADMIN: Create a new parking slot
  static Future<bool> createParkingSlot(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // ADMIN: Update a parking slot
  static Future<bool> updateParkingSlot(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots/${payload['id']}'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // ADMIN: Delete a parking slot
  static Future<bool> deleteParkingSlot(String slotId, String societyId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots/$slotId?societyId=$societyId'),
      headers: headers,
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

    // ADMIN: Generate default parking slots for all flats
 /* static Future<bool> generateDefaultSlots(String societyId) async {
    final headers = await _getHeaders();
    
    // GUARD: Prevent bad GUID calls
    if (societyId.isEmpty || !societyId.contains('-')) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots/generate-defaults/$societyId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error generating slots: $e');
      return false;
    }
  }*/
    // ADMIN: Generate default parking slots for all flats
  static Future<bool> generateDefaultSlots(String societyId) async {
    final headers = await _getHeaders();
    
    if (societyId.isEmpty || !societyId.contains('-')) return false;

    final response = await http.post(
      Uri.parse('${ApiConfig.vehicleService}/api/ParkingSlots/generate-defaults/$societyId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return true;
    } else {
      // Extract the real error message from backend
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to generate slots');
      } catch (e) {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }
    }
  }
  
}