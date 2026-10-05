// lib/services/amenity_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class AmenityService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // FIX: Aligned with [HttpGet("society/{societyId}")] in AmenitiesController
  static Future<List<dynamic>> getAmenities() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.amenityBaseUrl}/society/$societyId'), 
      headers: headers,
    );
    
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load amenities: ${response.body}');
  }

  // FIX: Aligned with [HttpGet("my-bookings")] + [FromQuery] Guid societyId in BookingsController
  static Future<List<dynamic>> getMyBookings() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.bookingsBaseUrl}/my-bookings?societyId=$societyId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load bookings');
  }

  // FIX: Aligned with [HttpPut("{id}/cancel")] + [FromQuery] Guid societyId
  static Future<bool> cancelBooking(String bookingId, String societyId) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${ApiConfig.bookingsBaseUrl}/$bookingId/cancel?societyId=$societyId'),
      headers: headers,
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // NEW: Aligned with [HttpGet("slots/available")]
  static Future<List<dynamic>> getAvailableSlots(String amenityId, String societyId, String date) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.bookingsBaseUrl}/slots/available?amenityId=$amenityId&societyId=$societyId&date=$date'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load available slots');
  }

  // NEW: Aligned with [HttpPost] in BookingsController
  static Future<bool> createBooking(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(ApiConfig.bookingsBaseUrl),
      headers: headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }
}