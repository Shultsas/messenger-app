import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  final String baseUrl = AppConfig.baseUrl;

  // 👇 Возвращаем dynamic, т.к. ответ может быть и Map, и List
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConfig.timeout);
      
      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  Future<dynamic> post(String endpoint, dynamic body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(AppConfig.timeout);
      
      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Если тело пустое — возвращаем пустой объект
      if (response.body.isEmpty) return {};
      
      // jsonDecode сам вернёт или Map, или List — что пришло
      return jsonDecode(response.body);
    }
    return {'error': 'API Error ${response.statusCode}: ${response.body}'};
  }
}