// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';

class AuthService {
  final String baseUrl = AppConfig.baseUrl;

  Future<User?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data);
        await _saveSession(user);
        return user;
      }
      print('Login failed: ${response.body}');
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<User?> register(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        return login(username, password);
      }
      print('Register failed: ${response.body}');
      return null;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<User?> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final username = prefs.getString('username');
    final token = prefs.getString('token');

    if (userId != null && username != null) {
      return User(
        id: userId,
        username: username,
        token: token,
      );
    }
    return null;
  }

  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', user.id);
    await prefs.setString('username', user.username);
    if (user.token != null) {
      await prefs.setString('token', user.token!);
    }
  }
}