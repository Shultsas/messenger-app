// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/message.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _apiService;

  ChatService(this._apiService);

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

  Future<bool> deleteMessage(int messageId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${_apiService.baseUrl}/messages/$messageId?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Delete message error: $e');
      return false;
    }
  }

  Future<Message?> sendMessage(int chatId, int senderId, String text) async {
    final data = {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'imageUrl': '',
    };

    final response = await _apiService.post('messages', data);

    if (response is Map && response.containsKey('error')) {
      print('Error: ${response['error']}');
      return null;
    }

    if (response is Map<String, dynamic>) {
      return Message.fromJson(response);
    }

    return null;
  }

  Future<Message?> sendImageMessage(int chatId, int senderId, String imageUrl) async {
    final data = {
      'chatId': chatId,
      'senderId': senderId,
      'text': '',
      'imageUrl': imageUrl,
    };

    final response = await _apiService.post('messages', data);

    if (response is Map && response.containsKey('error')) {
      print('Error sending image: ${response['error']}');
      return null;
    }

    if (response is Map<String, dynamic>) {
      return Message.fromJson(response);
    }

    return null;
  }

  Future<List<Message>> getMessages(int chatId) async {
    final response = await _apiService.get('messages/$chatId');

    if (response is Map && response.containsKey('error')) {
      print('Error: ${response['error']}');
      return [];
    }

    if (response is List) {
      final List<Message> messages = [];

      for (var item in response) {
        if (item is Map<String, dynamic>) {
          messages.add(Message.fromJson(item));
        }
      }

      return messages;
    }

    return [];
  }

  Future<String?> getCustomName(int userId, int chatId) async {
    try {
      final uri = Uri.parse('${_apiService.baseUrl}/settings/rename')
          .replace(queryParameters: {
        'userId': userId.toString(),
        'chatId': chatId.toString(),
      });

      final rawResponse = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (rawResponse.statusCode == 200) {
        final data = jsonDecode(rawResponse.body);
        return data['customName'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting custom name: $e');
      return null;
    }
  }

  Future<bool> renameContact(int userId, int chatId, int targetUserId, String customName) async {
    final data = {
      'userId': userId,
      'chatId': chatId,
      'targetUserId': targetUserId,
      'customName': customName,
    };

    try {
      final response = await _apiService.post('settings/rename', data);

      if (response is Map && response.containsKey('error')) {
        print('Rename error: ${response['error']}');
        return false;
      }

      return response is Map && response['success'] == true;
    } catch (e) {
      print('Exception in renameContact: $e');
      return false;
    }
  }
}