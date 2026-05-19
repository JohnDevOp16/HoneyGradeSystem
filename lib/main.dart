import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  bool loggedIn = false;

  if (token != null && token.isNotEmpty) {
    // Silently try to refresh token
    loggedIn = await ApiService.refreshToken();
    if (!loggedIn) {
      await prefs.clear(); // Token invalid — clear and go to login
    }
  }

  runApp(HoneyGradeApp(isLoggedIn: loggedIn));
}

class HoneyGradeApp extends StatelessWidget {
  final bool isLoggedIn;
  const HoneyGradeApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoneyGrade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB45309)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
