// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GroupService {
  final String baseUrl = AppConfig.baseUrl;

  // Создание группы
  Future<Map<String, dynamic>?> createGroup(
    String groupName,
    int creatorId,
    List<int> memberIds,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/group'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'groupName': groupName,
          'creatorId': creatorId,
          'userIds': memberIds,
        }),
      );

      print('Create group: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Create group exception: $e');
      return null;
    }
  }

  // 👇 НОВОЕ: Получить участников группы
  Future<List<Map<String, dynamic>>> getGroupMembers(int chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$chatId/members'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Get members error: $e');
      return [];
    }
  }

  // Поиск пользователей
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
      return [];
    } catch (e) {
      print('Search users error: $e');
      return [];
    }
  }
}