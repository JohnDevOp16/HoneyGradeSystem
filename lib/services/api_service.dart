import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── BASE URL ───────────────────────────────────────────────────────
  // Change this to your PC IP address
  static const String baseUrl = 'http://192.168.42.20:8000/api';

  static final _client = http.Client();

  // ── STATS CACHE ────────────────────────────────────────────────────
  static Map<String, dynamic>? _statsCache;
  static DateTime? _statsCacheTime;

  // ── STORAGE HELPERS ────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('user');
    return user != null ? jsonDecode(user) : null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _statsCache = null;
    _statsCacheTime = null;
  }

  // ── AUTH HEADERS ───────────────────────────────────────────────────
  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── REFRESH TOKEN ──────────────────────────────────────────────────
  static Future<bool> refreshToken() async {
    try {
      final refresh = await getRefreshToken();
      if (refresh == null || refresh.isEmpty) return false;

      final res = await _client
          .post(
            Uri.parse('$baseUrl/auth/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refresh}),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        if (data.containsKey('refresh')) {
          await prefs.setString('refresh_token', data['refresh']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ── SMART GET — retries with refreshed token on 401 ───────────────
  static Future<http.Response> _smartGet(String url) async {
    try {
      var headers = await authHeaders();
      var res = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          headers = await authHeaders();
          res = await _client
              .get(Uri.parse(url), headers: headers)
              .timeout(const Duration(seconds: 10));
        }
      }
      return res;
    } catch (e) {
      rethrow;
    }
  }

  // ── SMART POST — retries with refreshed token on 401 ──────────────
  static Future<http.Response> _smartPost(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      var headers = await authHeaders();
      var res = await _client
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          headers = await authHeaders();
          res = await _client
              .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 10));
        }
      }
      return res;
    } catch (e) {
      rethrow;
    }
  }

  // ── LOGIN ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/auth/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timed out'),
          );

      if (res.statusCode == 200 ||
          res.statusCode == 400 ||
          res.statusCode == 401) {
        return jsonDecode(res.body);
      }
      throw Exception('Server error: ${res.statusCode}');
    } on Exception {
      rethrow;
    }
  }

  // ── REGISTER ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/auth/register/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timed out'),
          );
      return jsonDecode(res.body);
    } on Exception {
      rethrow;
    }
  }

  // ── DASHBOARD STATS ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardStats() async {
    // Return cache if fresh
    if (_statsCache != null &&
        _statsCacheTime != null &&
        DateTime.now().difference(_statsCacheTime!).inSeconds < 30) {
      return _statsCache!;
    }
    final res = await _smartGet('$baseUrl/dashboard/');
    if (res.statusCode == 200) {
      _statsCache = jsonDecode(res.body);
      _statsCacheTime = DateTime.now();
      return _statsCache!;
    }
    throw Exception('Failed to load stats: ${res.statusCode}');
  }

  // ── ASSESSMENT HISTORY ─────────────────────────────────────────────
  static Future<List<dynamic>> getHistory() async {
    final res = await _smartGet('$baseUrl/assess/history/');
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load history: ${res.statusCode}');
  }

  // ── ASSESS HONEY ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> assessHoney(
    String filePath,
    String sampleLabel,
  ) async {
    final token = await getToken();

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/assess/'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['sample_label'] = sampleLabel;
    request.files.add(await http.MultipartFile.fromPath('image', filePath));

    var streamed = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Upload timed out'),
    );
    var res = await http.Response.fromStream(streamed);

    // If 401 — refresh token and retry
    if (res.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        final newToken = await getToken();
        final request2 = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/assess/'),
        );
        request2.headers['Authorization'] = 'Bearer $newToken';
        request2.fields['sample_label'] = sampleLabel;
        request2.files.add(
          await http.MultipartFile.fromPath('image', filePath),
        );
        streamed = await request2.send().timeout(const Duration(seconds: 30));
        res = await http.Response.fromStream(streamed);
      }
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception('Assessment failed: ${res.statusCode} ${res.body}');
  }

  // ── UPDATE PROFILE ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final res = await _smartPost('$baseUrl/auth/profile/', data);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update profile: ${res.statusCode}');
  }

  // ── GET PROFILE ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await _smartGet('$baseUrl/auth/profile/');
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load profile: ${res.statusCode}');
  }
}
