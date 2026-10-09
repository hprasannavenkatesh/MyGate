// lib/services/billing_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class BillingService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Future<List<dynamic>> getMyDues() async {
    // FIX: Use flatId instead of societyId, and match the capital 'B' in Billing
    final flatId = await AuthService.getFlatId();
    final headers = await _getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.billingBaseUrl}/my-dues?flatId=$flatId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load dues: ${response.body}');
  }

    // Add to BillingService
  static Future<List<dynamic>> getSocietyInvoices() async {
    final societyId = await AuthService.getSocietyId();
    final headers = await _getHeaders(); // Note: _getHeaders is async in existing code
    final response = await http.get(
      Uri.parse('${ApiConfig.billingBaseUrl}/society/$societyId'),
      headers: await headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load society invoices');
  }

   // FIX: Added missing Generate Invoice API call (matches React parity)
  static Future<bool> generateInvoice(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.billingBaseUrl}/generate'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> bulkGenerateInvoices(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.billingBaseUrl}/bulk-generate'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}