// ignore_for_file: avoid_print

import 'package:signalr_netcore/signalr_client.dart';
import '../config/app_config.dart';

class SignalRService {
  HubConnection? _connection;
  final String _hubUrl;

  SignalRService() : _hubUrl = AppConfig.baseUrl.replaceFirst('/api', '/chathub');
  

  // Подключение к хабу
  Future<void> connect() async {
    if (_connection != null) return;

    _connection = HubConnectionBuilder()
        .withUrl(_hubUrl)
        .withAutomaticReconnect()
        .build();

    await _connection!.start();
    print('SignalR connected!');
  }

  // Присоединиться к чату
  Future<void> joinChat(int chatId) async {
    if (_connection == null) await connect();
    await _connection!.invoke('JoinChat', args: [chatId]);
    print('Joined chat: $chatId');
  }

  // Отправить сообщение через SignalR
  Future<void> sendMessage(int chatId, int senderId, String text) async {
    if (_connection == null) await connect();
    await _connection!.invoke('SendMessage', args: [chatId, senderId, text]);
  }

  // Слушать входящие сообщения
  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    _connection?.on('ReceiveMessage', (args) {
      if (args != null && args.isNotEmpty) {
        callback(args[0] as Map<String, dynamic>);
      }
    });
  }

  // 👇 ИСПРАВЛЕННЫЙ МЕТОД
void on(String eventName, void Function(List<dynamic>? args) handler) {
  if (_connection != null) {
    _connection!.on(eventName, handler);
  } else {
    print('⚠️ Попытка подписки на событие "$eventName" до подключения к SignalR!');
  }
}


  // Отключение
  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
      print('SignalR disconnected');
    }
  }

  // Отправить статус "печатает"
  Future<void> sendTypingStatus(int chatId, int userId, String username) async {
    if (_connection == null) await connect();
    await _connection!.invoke('UserTyping', args: [chatId, userId, username]);
  }

  // Слушать статус "печатает" от других
  void onUserTyping(Function(Map<String, dynamic>) callback) {
    _connection?.on('UserTyping', (args) {
      if (args != null && args.isNotEmpty) {
        callback(args[0] as Map<String, dynamic>);
      }
    });
  }
}