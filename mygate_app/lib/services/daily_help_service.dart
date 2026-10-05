// lib/services/daily_help_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class DailyHelpService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Future<List<dynamic>> getMyDailyHelp() async {
    // FIX: The controller is AssignmentsController, and it expects flatId
    final flatId = await AuthService.getFlatId();
    final headers = await _getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.dailyHelpBaseUrl}/api/Assignments/my-help?flatId=$flatId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load daily help: ${response.body}');
  }
}