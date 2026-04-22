// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/group_service.dart';
import 'chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  final int currentUserId;

  const CreateGroupScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final GroupService _groupService = GroupService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedUsers = [];
  bool _isCreating = false;

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final results = await _groupService.searchUsers(query, widget.currentUserId);
    
    if (!mounted) return;
    setState(() {
      _searchResults = results.where((u) => 
        !_selectedUsers.any((s) => s['id'] == u['id'])
      ).toList();
    });
  }

  void _toggleUser(Map<String, dynamic> user) {
    setState(() {
      final index = _selectedUsers.indexWhere((u) => u['id'] == user['id']);
      if (index >= 0) {
        _selectedUsers.removeAt(index);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Введите название группы', style: Theme.of(context).textTheme.bodyLarge),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Выберите хотя бы одного участника', style: Theme.of(context).textTheme.bodyLarge),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    final memberIds = _selectedUsers.map((u) => u['id'] as int).toList();
    final groupData = await _groupService.createGroup(
      _nameController.text.trim(),
      widget.currentUserId,
      memberIds,
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (groupData != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: groupData['id'],
            currentUserId: widget.currentUserId,
            chatName: groupData['name'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания группы', style: Theme.of(context).textTheme.bodyLarge),
          backgroundColor: Colors.red,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'НОВАЯ ГРУППА',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'CascadiaCode',
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildGlassTextField(
              controller: _nameController,
              hint: 'Название группы...',
              icon: Icons.group_add,
              label: 'Как назовем группу?',
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildGlassTextField(
              controller: _searchController,
              hint: 'Поиск участников...',
              icon: Icons.search,
              label: 'Найти друзей',
              onChanged: _searchUsers,
            ),
          ),

          const SizedBox(height: 16),

          if (_selectedUsers.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Участники: ',
                      style: TextStyle(color: Colors.white54, fontFamily: 'CascadiaCode', fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedUsers.map((user) {
                        final username = user['username'] ?? '?';
                        final firstLetter = username[0].toUpperCase();
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.2),
                                border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.blueAccent,
                                    child: Text(
                                      firstLetter,
                                      style: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'CascadiaCode'),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    username,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'CascadiaCode'),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _toggleUser(user),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Введите имя для поиска'
                              : 'Никто не найден',
                          style: TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'CascadiaCode'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final isSelected = _selectedUsers.any((u) => u['id'] == user['id']);
                      final username = user['username'] ?? 'Unknown';
                      final firstLetter = username[0].toUpperCase();

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggleUser(user),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.blueAccent.withOpacity(0.15) 
                                  : Colors.white.withOpacity(0.05),
                              border: Border.all(
                                color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                                width: isSelected ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isSelected ? Colors.blueAccent : Colors.white24,
                                  child: Text(
                                    firstLetter,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'CascadiaCode',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    username,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontFamily: 'CascadiaCode',
                                    ),
                                  ),
                                ),
                                Icon(
                                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                                  color: isSelected ? Colors.blueAccent : Colors.white54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1e293b).withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _isCreating
                ? const CircularProgressIndicator(color: Colors.blueAccent)
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'СОЗДАТЬ ГРУППУ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'CascadiaCode',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? label,
    ValueChanged<String>? onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'CascadiaCode'),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'CascadiaCode'),
              prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}