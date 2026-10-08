// lib/services/visitor_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class VisitorService {
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> getMyVisitors() async {
    final userId = await AuthService.getUserId();
    final headers = await _getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.visitorsBaseUrl}/my-visitors?inviterId=$userId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load visitors');
  }

  static Future<bool> verifyOtp(String preApprovalId, String otp) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.visitorsBaseUrl}/verify-otp'),
      headers: headers,
      body: jsonEncode({'preApprovalId': preApprovalId, 'otp': otp}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> markExit(String preApprovalId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.visitorsBaseUrl}/mark-exit'),
      headers: headers,
      body: jsonEncode({'preApprovalId': preApprovalId}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> preApproveWalkIn({
    required String societyId,
    required String flatId,
    required String visitorName,
    required String visitorMobile,
    required String purpose,
    required String expectedDate,
    required String invitedByUserId,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.visitorsBaseUrl}/pre-approve'),
      headers: headers,
      body: jsonEncode({
        'societyId': societyId,
        'flatId': flatId,
        'visitorName': visitorName,
        'visitorMobile': visitorMobile,
        'purpose': purpose,
        'expectedDate': expectedDate,
        'invitedByUserId': invitedByUserId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to pre-approve walk-in');
  }

  static Future<bool> manualEntry(String visitorId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.visitorsBaseUrl}/$visitorId/manual-entry'),
      headers: headers,
      body: jsonEncode({
        'preApprovalId': visitorId,
        'reason': 'Walk-in entry at gate by Security Guard',
      }),
    );
    return response.statusCode == 200;
  }

     // --- GUARD & ADMIN ENDPOINTS ---

  // Fetch all visitors for a society (Guard/Admin)
  static Future<List<dynamic>> getSocietyVisitors(String societyId) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.visitorService}/api/Visitors/society/$societyId'), // Fixed ApiConfig
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load society visitors');
  }

  // Guard Verify OTP at gate
  static Future<bool> guardVerifyOtp(String preApprovalId, String otp) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.visitorService}/api/Visitors/verify-otp'), // Fixed ApiConfig
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'preApprovalId': preApprovalId, 'otp': otp}),
    );
    return response.statusCode == 200;
  }

  // Guard Mark Exit
  static Future<void> guardMarkExit(String preApprovalId) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.visitorService}/api/Visitors/mark-exit'), // Fixed ApiConfig
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'preApprovalId': preApprovalId}),
    );
    if (response.statusCode != 200) throw Exception('Failed to mark exit');
  }

  // Guard Walk-in / Manual Entry
  static Future<void> guardManualEntry(String preApprovalId, String reason) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.visitorService}/api/Visitors/$preApprovalId/manual-entry'), // Fixed ApiConfig
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'preApprovalId': preApprovalId, 'reason': reason}),
    );
    if (response.statusCode != 200) throw Exception('Failed to mark manual entry');
  }

  // Pre-Approve (Required for Walk-in flow)
  static Future<Map<String, dynamic>> preApproveVisitor(Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.visitorService}/api/Visitors/pre-approve'), // Fixed ApiConfig
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to pre-approve visitor');
  }
}