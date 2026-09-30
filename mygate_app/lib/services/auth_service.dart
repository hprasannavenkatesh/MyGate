// lib/services/auth_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyToken = 'jwt_token';
  static const _keyUserId = 'cached_user_id';
  static const _keyUserRole = 'cached_user_role';
  static const _keyUserName = 'cached_user_name';
  static const _keySocietyId = 'society_id';
  static const _keyFlatId = 'flat_id';
  static const _keyFlatNumber = 'flat_number';

  /// Decode JWT and cache all claims to SharedPreferences.
  /// Call ONCE after login or context switch.
  static Future<void> cacheTokenClaims(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);

    final claims = _decodeJwt(token);
    if (claims != null) {
      await prefs.setString(_keyUserId, claims['sub'] ?? '');
      
      // Role can be in "role", "Role", or the full ClaimTypes.Role URI
      final role = claims['role'] 
          ?? claims['Role'] 
          ?? claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] 
          ?? '';
      await prefs.setString(_keyUserRole, role);
      await prefs.setString(_keyUserName, claims['FullName'] ?? '');
    }
  }

  /// Get cached User ID (no JWT decode needed)
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_keyUserId) ?? '';
    if (userId.isEmpty) {
      // Fallback: decode and cache if not cached yet
      final token = prefs.getString(_keyToken) ?? '';
      if (token.isNotEmpty) {
        await cacheTokenClaims(token);
        userId = prefs.getString(_keyUserId) ?? '';
      }
    }
    return userId;
  }

  /// Get cached User Role (no JWT decode needed)
  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    var role = prefs.getString(_keyUserRole) ?? '';
    if (role.isEmpty) {
      final token = prefs.getString(_keyToken) ?? '';
      if (token.isNotEmpty) {
        await cacheTokenClaims(token);
        role = prefs.getString(_keyUserRole) ?? '';
      }
    }
    return role;
  }

  /// Get cached User Name
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'Resident';
  }

  /// Get Society ID from SharedPreferences
  static Future<String> getSocietyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySocietyId) ?? '';
  }

  /// Get Flat ID from SharedPreferences
  static Future<String> getFlatId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFlatId) ?? '';
  }

  /// Get Flat Number from SharedPreferences (e.g. "B-204")
  static Future<String> getFlatNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFlatNumber) ?? '';
  }

  /// Get JWT token
  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken) ?? '';
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken) != null;
  }

  /// Full logout — clear everything
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keySocietyId);
    await prefs.remove(_keyFlatId);
    await prefs.remove(_keyFlatNumber);
  }

  /// Extract context from JWT claims directly (for cases where
  /// you need SocietyId/FlatId from the token itself)
  static Map<String, String> extractContextFromToken(String token) {
    final claims = _decodeJwt(token);
    if (claims == null) return {'societyId': '', 'flatId': ''};
    return {
      'societyId': claims['SocietyId'] ?? '',
      'flatId': claims['FlatId'] ?? '',
    };
  }

  /// Internal: Decode JWT payload
  static Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}