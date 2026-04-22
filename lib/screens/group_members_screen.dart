// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../services/group_service.dart';

class GroupMembersScreen extends StatefulWidget {
  final int chatId;
  final int currentUserId;
  final String groupName;

  const GroupMembersScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.groupName,
  });

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final GroupService _groupService = GroupService();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await _groupService.getGroupMembers(widget.chatId);
    if (!mounted) return;
    setState(() {
      _members = members;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        elevation: 0,
        title: Text(
          'Участники: ${widget.groupName}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'PressStart2P',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _members.isEmpty
              ? const Center(
                  child: Text(
                    'Нет участников',
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'PressStart2P',
                      fontSize: 10,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final isCreator = member['id'] == _members.first['id'];
                    final isMe = member['id'] == widget.currentUserId;
                    
                    return _buildMemberTile(member, isCreator, isMe);
                  },
                ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member, bool isCreator, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // Аватар
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF0f3460),
            backgroundImage: const AssetImage('assets/images/avatars/default_avatar.png'),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member['username'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'PressStart2P',
                        fontSize: 12,
                      ),
                    ),
                    if (isMe)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFe94560),
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'ВЫ',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'PressStart2P',
                            fontSize: 6,
                          ),
                        ),
                      ),
                    if (isCreator && !isMe)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0f3460),
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'СОЗДАТЕЛЬ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'PressStart2P',
                            fontSize: 6,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isMe ? '🟢 Онлайн' : '🟡 В сети',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontFamily: 'PressStart2P',
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          
          const Icon(Icons.chat, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}