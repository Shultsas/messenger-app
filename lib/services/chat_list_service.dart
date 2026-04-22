// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/chat.dart';

class ChatListService {
  final ApiService _apiService;

  ChatListService(this._apiService);

  // Получить чаты пользователя
  Future<List<Chat>> getUserChats(int userId) async {
    try {
      final response = await _apiService.get('chats?userId=$userId');
      
      if (response is Map && response.containsKey('error')) {
        print('Error: ${response['error']}');
        return [];
      }

      if (response is List) {
        final List<Chat> chats = [];
        for (var item in response) {
          if (item is Map<String, dynamic>) {
            chats.add(Chat.fromJson(item));
          }
        }
        return chats;
      }
    } catch (e) {
      print('Error fetching chats: $e');
    }
    
    return [];
  }

  // 👇 НОВОЕ: Удаление чата
  Future<bool> deleteChat(int chatId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${_apiService.baseUrl}/chats/$chatId?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Delete chat error: $e');
      return false;
    }
  }
}