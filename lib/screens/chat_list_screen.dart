// ignore_for_file: use_build_context_synchronously

import 'dart:ui'; 
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/chat_list_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/signalr_service.dart'; 
import 'chat_screen.dart';
import 'login_screen.dart';
import 'search_screen.dart';
import 'create_group_screen.dart';
import '../utils/avatar_color_generator.dart';

class ChatListScreen extends StatefulWidget {
  final int currentUserId;

  const ChatListScreen({super.key, required this.currentUserId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  final ChatListService _chatService = ChatListService(ApiService());
  final SignalRService _signalR = SignalRService(); 

  
  List<Chat> _chats = [];
  bool _isLoading = true;
  
  // Анимации
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _initSignalR(); 
    
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

 
  
  Future<void> _initSignalR() async {
    try {
      await _signalR.connect();

      await _signalR.joinChat(-1); 

      _signalR.on("RefreshChatList", (args) {
        print("🔄 Получен сигнал: Обновляем список чатов!");
        if (mounted) {
          _loadChats(); 
        }
      });

      _signalR.on("UserStatusChanged", (args) {
         if (mounted) _loadChats(); 
      });

    } catch (e) {
      print("❌ Ошибка подключения SignalR в списке чатов: $e");
    }
  }

  @override
  void dispose() {
    _signalR.disconnect(); 
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    final chats = await _chatService.getUserChats(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _chats = chats;
      _isLoading = false;
    });
  }

  Future<void> _deleteChat(int chatId) async {
    final success = await _chatService.deleteChat(chatId, widget.currentUserId);
    
    if (!mounted) return;

    if (success) {
      setState(() {
        _chats.removeWhere((c) => c.id == chatId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Чат удалён', style: Theme.of(context).textTheme.bodyLarge),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text('Ошибка удаления', style: Theme.of(context).textTheme.bodyLarge),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

 
  Widget _pixelIcon(String iconName, {double size = 24}) {
    return Image.asset(
      'assets/images/icons/$iconName',
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
       
        return Icon(Icons.help_outline, color: Colors.blueAccent, size: size);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), 
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chat_bubble_outline, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'PIXAR CHATS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'CascadiaCode', // НОВЫЙ ШРИФТ
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined, color: Colors.blueAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateGroupScreen(currentUserId: widget.currentUserId),
                ),
              ).then((_) => _loadChats());
            },
            tooltip: 'Создать группу',
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.blueAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(currentUserId: widget.currentUserId),
                ),
              ).then((_) => _loadChats());
            },
            tooltip: 'Поиск',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              final authService = AuthService();
              await authService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            tooltip: 'Выход',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              : _chats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          Text(
                            'Чатов пока нет.\nНайдите пользователя!',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              fontFamily: 'CascadiaCode',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _chats.length,
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        return _buildChatTile(chat);
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(currentUserId: widget.currentUserId),
                ),
              ).then((_) => _loadChats());
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: const Text('НОВЫЙ', style: TextStyle(fontFamily: 'CascadiaCode', fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChatTile(Chat chat) {
    return Dismissible(
      key: Key('chat-${chat.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirm(chat);
      },
      onDismissed: (direction) {
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05), 
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AvatarColorGenerator.getColor(chat.name),
                child: Text(
                  chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'CascadiaCode',
                  ),
                ),
              ),
              title: Text(
                chat.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'CascadiaCode',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                chat.isGroup ? '👥 Группа' : '💬 Личный чат',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'CascadiaCode',
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: chat.id,
                      currentUserId: widget.currentUserId,
                      chatName: chat.name,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirm(Chat chat) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Удалить чат?',
          style: TextStyle(color: Colors.white, fontFamily: 'CascadiaCode', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Чат "${chat.name}" будет удалён безвозвратно.',
          style: const TextStyle(color: Colors.white70, fontFamily: 'CascadiaCode'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.white54, fontFamily: 'CascadiaCode')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Удалить', style: TextStyle(color: Colors.white, fontFamily: 'CascadiaCode')),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await _deleteChat(chat.id);
      return true;
    }
    
    return false;
  }
}