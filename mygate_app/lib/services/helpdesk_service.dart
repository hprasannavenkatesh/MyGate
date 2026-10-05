// lib/services/helpdesk_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class HelpdeskService {
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> getMyTickets() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.helpdeskBaseUrl}/my-tickets?societyId=$societyId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load tickets');
  }

  static Future<Map<String, dynamic>> getTicketDetails(String ticketId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.helpdeskBaseUrl}/$ticketId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load ticket details');
  }

  static Future<bool> raiseTicket(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.helpdeskBaseUrl}/raise'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 201;
  }

  static Future<bool> addComment(String ticketId, String commentText, bool isAdmin) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.helpdeskBaseUrl}/$ticketId/comments'),
      headers: headers,
      body: jsonEncode({'commentText': commentText, 'isAdminComment': isAdmin}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}