// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SearchService {
  final String baseUrl = AppConfig.baseUrl;

  Future<List<Map<String, dynamic>>> searchUsers(String query, int currentUserId) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/search?query=$query&currentUserId=$currentUserId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      print('Search error: ${response.body}');
      return [];
    } catch (e) {
      print('Search exception: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createDirectChat(int user1Id, int user2Id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/direct'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user1Id': user1Id, 'user2Id': user2Id}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print('Create chat error: ${response.body}');
      return null;
    } catch (e) {
      print('Create chat exception: $e');
      return null;
    }
  }
}