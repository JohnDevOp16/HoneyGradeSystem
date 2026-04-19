import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.42.20:8000/api';

  // If using physical device replace with your PC IP e.g. http://192.168.1.5:8000/api

  // ── GET TOKEN ──────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // ── SAVE TOKENS ────────────────────────────────────────────────────
  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  // ── SAVE USER ──────────────────────────────────────────────────────
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  // ── GET USER ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('user');
    return user != null ? jsonDecode(user) : null;
  }

  // ── LOGOUT ─────────────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── AUTH HEADERS ───────────────────────────────────────────────────
  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── LOGIN ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/login/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw Exception('Connection timed out'),
        );
    return jsonDecode(res.body);
  }

  // ── REGISTER ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/register/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        )
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw Exception('Connection timed out'),
        );
    return jsonDecode(res.body);
  }

  // ── DASHBOARD STATS ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await http
        .get(Uri.parse('$baseUrl/dashboard/'), headers: await authHeaders())
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw Exception('Connection timed out'),
        );
    return jsonDecode(res.body);
  }

  // ── ASSESSMENT HISTORY ─────────────────────────────────────────────
  static Future<List<dynamic>> getHistory() async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/assess/history/'),
          headers: await authHeaders(),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Timed out'),
        );
    return jsonDecode(res.body);
  }

  // ── ASSESS HONEY ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> assessHoney(
    String filePath,
    String sampleLabel,
  ) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/assess/'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['sample_label'] = sampleLabel;
    request.files.add(await http.MultipartFile.fromPath('image', filePath));
    final streamed = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Timed out'),
    );
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body);
  }

  // ── UPDATE PROFILE ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/auth/profile/'),
          headers: await authHeaders(),
          body: jsonEncode(data),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Timed out'),
        );
    return jsonDecode(res.body);
  }
}
