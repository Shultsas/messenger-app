// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:ui'; // Для эффекта размытия
import 'package:flutter/material.dart';
import '../services/search_service.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  final int currentUserId;

  const SearchScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final SearchService _searchService = SearchService();
  final TextEditingController _controller = TextEditingController();
  
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  
  // Анимация для появления списка
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    // Небольшая задержка для плавности UI
    await Future.delayed(const Duration(milliseconds: 300));
    
    final results = await _searchService.searchUsers(query, widget.currentUserId);
    
    if (!mounted) return;
    
    setState(() {
      _results = results;
      _isSearching = false;
      _animController.forward(from: 0); // Запуск анимации при новых результатах
    });
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    print('🔍 Starting chat with user: ${user['username']} (ID: ${user['id']})');
    
    // Блокируем кнопку во время создания
    setState(() => _isSearching = true);

    final chatData = await _searchService.createDirectChat(
      widget.currentUserId,
      user['id'],
    );

    if (!mounted) return;
    setState(() => _isSearching = false);

    if (chatData != null) {
      print('✅ Чат создан: ${chatData['id']}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatData['id'],
            currentUserId: widget.currentUserId,
            chatName: user['username'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось создать чат. Попробуйте еще раз', style: Theme.of(context).textTheme.bodyLarge),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ПОИСК ПОЛЬЗОВАТЕЛЕЙ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'CascadiaCode',
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 🔍 ПОЛЕ ПОИСКА (Стекло + Градиент)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'CascadiaCode',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Введите имя пользователя...',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontFamily: 'CascadiaCode',
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.blueAccent, size: 24),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white54),
                              onPressed: () {
                                _controller.clear();
                                setState(() => _results = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    ),
                    onChanged: _search,
                  ),
                ),
              ),
            ),
          ),

          // Индикатор загрузки
          if (_isSearching && _results.isEmpty)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),

          // Список результатов
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _controller.text.isEmpty
                              ? 'Начните ввод для поиска'
                              : 'Ничего не найдено',
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
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        return _buildUserTile(user);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Карточка пользователя (Стекло + Аватарка)
  Widget _buildUserTile(Map<String, dynamic> user) {
    final username = user['username'] ?? 'Unknown';
    final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startChat(user),
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Аватарка (Буква)
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'CascadiaCode',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Имя
                Expanded(
                  child: Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'CascadiaCode',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Иконка действия
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}