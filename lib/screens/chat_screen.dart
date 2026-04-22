// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:async';
import 'dart:convert'; // Для jsonDecode
import 'dart:io';      // Для File и Process (PowerShell)
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для работы с клавиатурой (KeyDownEvent и т.д.)
import 'package:image_picker/image_picker.dart'; 
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; 
import 'package:audioplayers/audioplayers.dart';

import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../utils/date_formatter.dart';
import '../config/app_config.dart'; 
import 'group_members_screen.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final int currentUserId;
  final String chatName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.chatName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService(ApiService());
  final SignalRService _signalR = SignalRService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
  
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isConnected = false;
  bool _isUploadingImage = false;

  int? _targetUserId; // ID собеседника кому меняем имя
  String? _customName; // текущее кастом имя
  
  String? _typingUser;
  Timer? _typingTimer;
  
  // Анимации
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _initSignalR();
    
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    _audioPlayer.dispose();
    _signalR.disconnect();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initSignalR() async {
    try {
      await _signalR.connect();
      await _signalR.joinChat(widget.chatId);

      _signalR.onMessageReceived((data) {
        if (!mounted) return;
        final message = Message.fromJson(data);
        setState(() {
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
            if (message.senderId != widget.currentUserId) {
              _playNotificationSound();
            }
          }
        });
      });

      _signalR.onUserTyping((data) {
        if (!mounted) return;
        setState(() {
          _typingUser = data['Username'] ?? 'Кто-то';
        });
        Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _typingUser = null);
        });
      });

      if (mounted) setState(() => _isConnected = true);
      _loadMessages();
    } catch (e) {
      print('SignalR error: $e');
      _loadMessages();
    }
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/message.mp3'));
    } catch (e) {
      print('Sound error: $e');
    }
  }

  void _sendTypingStatus() {
    _signalR.sendTypingStatus(
      widget.chatId,
      widget.currentUserId,
      'User${widget.currentUserId}',
    );
  }

  void _onTextChanged(String text) {
    if (text.trim().isNotEmpty) {
      _sendTypingStatus();
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _typingUser = null);
      });
    }
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final messages = await _chatService.getMessages(widget.chatId);
    
    if (!mounted) return;
    
    // 1. Определяем собеседника
    if (_targetUserId == null && messages.isNotEmpty) {
      final otherMsg = messages.firstWhere(
        (m) => m.senderId != widget.currentUserId,
        orElse: () => messages.first,
      );
      if (otherMsg.senderId != widget.currentUserId) {
        setState(() {
          _targetUserId = otherMsg.senderId;
        });
        
        // 2. 👇 ЕСЛИ НАШЛИ СОБЕСЕДНИКА — СРАЗУ ГРУЗИМ ИМЯ
        _loadCustomName();
      }
    } else if (_targetUserId != null) {
       // Если собеседник уже определен (например, был ранее), но имя еще не грузили
       if (_customName == null) {
         _loadCustomName();
       }
    }

    setState(() {
      _messages = messages;
      _isLoading = false;
    });
  }

  // 👇 НОВЫЙ МЕТОД: Загрузка имени с сервера
  Future<void> _loadCustomName() async {
    if (_targetUserId == null) return;

    final name = await _chatService.getCustomName(widget.currentUserId, widget.chatId);
    
    if (mounted) {
      setState(() {
        _customName = name;
      });
      if (name != null) {
        print('✅ Загружено кастомное имя: $name');
      }
    }
  }
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    
    final text = _controller.text.trim();
    _controller.clear();

    try {
      await _signalR.sendMessage(
        widget.chatId,
        widget.currentUserId,
        text,
      );
    } catch (e) {
      print('Send error: $e');
      final message = await _chatService.sendMessage(
        widget.chatId,
        widget.currentUserId,
        text,
      );
      if (message != null && mounted) {
        setState(() => _messages.add(message));
      }
    }
  }

  // Отправка фото из галереи/камеры
  Future<void> _pickAndSendImage() async {
    print('📸 НАЧАЛО ЗАГРУЗКИ ФОТО');
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text('Выберите источник', style: TextStyle(color: Colors.white, fontFamily: 'CascadiaCode')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('📷 Камера', style: TextStyle(color: Colors.white)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('🖼️ Галерея', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (source == null) return;

    try {
      setState(() => _isUploadingImage = true);

      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/upload/image'), 
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String imageUrl = jsonResponse['url'];

        final newMessage = await _chatService.sendImageMessage(widget.chatId, widget.currentUserId, imageUrl);
        
        if (newMessage != null && mounted) {
          setState(() {
            _messages.add(newMessage);
          });
          try {
             await _signalR.sendMessage(widget.chatId, widget.currentUserId, ""); 
          } catch (e) {
             print('Не удалось отправить сигнал обновления: $e');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки: ${response.reasonPhrase}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('Image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // 👇 НОВЫЙ МЕТОД: Обработка Ctrl+V через PowerShell (Windows)
  Future<void> _handleClipboardImage() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}\\clipboard_${DateTime.now().millisecondsSinceEpoch}.png';

      // Команда PowerShell для сохранения картинки из буфера в файл
      final command = '''
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        \$image = [System.Windows.Forms.Clipboard]::GetImage()
        if (\$image -ne \$null) {
          \$image.Save('$filePath', [System.Drawing.Imaging.ImageFormat]::Png)
          \$image.Dispose()
          Write-Host "SUCCESS"
        } else {
          Write-Host "NO_IMAGE"
        }
      ''';

      final result = await Process.run('powershell', ['-Command', command]);
      
      if (result.stdout.toString().trim() == 'SUCCESS') {
        print('✅ Картинка сохранена в: $filePath');
        _sendImageFromFile(filePath);
      } else {
        print('ℹ️ В буфере нет картинки (только текст или пусто)');
      }
    } catch (e) {
      print('❌ Ошибка работы с буфером: $e');
    }
  }

  // 👇 НОВЫЙ МЕТОД: Отправка файла из пути
  Future<void> _sendImageFromFile(String filePath) async {
    if (!await File(filePath).exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл не найден'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      setState(() => _isUploadingImage = true);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/upload/image'),
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String imageUrl = jsonResponse['url'];

        final newMessage = await _chatService.sendImageMessage(widget.chatId, widget.currentUserId, imageUrl);
        
        if (newMessage != null && mounted) {
          setState(() => _messages.add(newMessage));
          try { await _signalR.sendMessage(widget.chatId, widget.currentUserId, ""); } catch(_) {}
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: ${response.reasonPhrase}'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      print('Error sending file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

    // Возвращает кастомное имя, если есть, иначе стандартное из виджета
  String _getDisplayName() {
    return _customName ?? widget.chatName;
  }

  // Диалог переименования
   void _showRenameDialog() {
    // 1. Пытаемся найти собеседника ПРЯМО СЕЙЧАС в текущем списке сообщений
    int? targetId = _targetUserId;

    if (targetId == null && _messages.isNotEmpty) {
      // Ищем первое сообщение не от меня
      final otherMsg = _messages.firstWhere(
        (m) => m.senderId != widget.currentUserId,
        orElse: () => _messages.first,
      );
      if (otherMsg.senderId != widget.currentUserId) {
        targetId = otherMsg.senderId;
        // Сохраняем найденный ID в переменную для будущего
        setState(() => _targetUserId = targetId); 
        print('🎯 Собеседник найден в сообщениях: $targetId');
      }
    }

    // 2. Если все еще null — значит чат пуст
    if (targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('👉 Сначала отправьте любое сообщение собеседнику, чтобы система могла его определить.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // 3. Если ID есть — открываем диалог
    final controller = TextEditingController(text: _getDisplayName());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Переименовать собеседника',
          style: TextStyle(color: Colors.white, fontFamily: 'CascadiaCode', fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontFamily: 'CascadiaCode'),
          decoration: const InputDecoration(
            hintText: 'Новое имя (только для вас)',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.white54, fontFamily: 'CascadiaCode')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final newName = controller.text.trim();
              
              print('💾 Сохраняем имя для User ID: $targetId');
              
              final success = await _chatService.renameContact(
                widget.currentUserId,
                widget.chatId,
                targetId!, // Теперь точно не null
                newName,
              );

              if (success && mounted) {
                setState(() {
                  _customName = newName.isEmpty ? null : newName;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newName.isEmpty ? 'Имя сброшено' : 'Имя изменено на "$newName"'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ошибка сохранения имени'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Сохранить', style: TextStyle(color: Colors.white, fontFamily: 'CascadiaCode')),
          ),
        ],
      ),
    );
  }
  void _deleteMessage(int messageId) {
    setState(() {
      _messages.removeWhere((m) => m.id == messageId);
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Сообщение удалено', style: Theme.of(context).textTheme.bodyLarge),
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
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.groups, color: Colors.blueAccent, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                  GestureDetector(
                  onTap: _showRenameDialog, // <-- Вызываем наш диалог
                  child: Tooltip(
                    message: 'Нажмите, чтобы переименовать',
                    child: Text(
                      _getDisplayName(), // <-- Используем кастомное имя
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'CascadiaCode',
                        letterSpacing: 0.5,
                        decoration: TextDecoration.underline, // Подчеркивание, что можно нажать
                        decorationColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isConnected ? 'Онлайн' : 'Оффлайн',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                        fontFamily: 'CascadiaCode',
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
        actions: [
          if (widget.chatName.toLowerCase().contains('группа'))
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupMembersScreen(
                      chatId: widget.chatId,
                      currentUserId: widget.currentUserId,
                      groupName: widget.chatName,
                    ),
                  ),
                );
              },
              tooltip: 'Инфо о группе',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/backgrounds/chat_background.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                const Color(0xFF0f172a).withOpacity(0.85),
                BlendMode.srcATop,
              ),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: _isLoading && _messages.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == widget.currentUserId;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
              ),
              
              if (_typingUser != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$_typingUser печатает...',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontFamily: 'CascadiaCode',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          if (!_isUploadingImage)
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.white54),
              onPressed: _pickAndSendImage,
              tooltip: 'Прикрепить фото',
            )
          else
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
            ),
          
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) async {
                // Обработка Ctrl+V
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.keyV &&
                    HardwareKeyboard.instance.isControlPressed) {
                  
                  print('📋 Нажат Ctrl+V! Пробуем получить картинку...');
                  await _handleClipboardImage();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'CascadiaCode',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Сообщение...',
                    hintStyle: TextStyle(
                      color: Colors.white38,
                      fontFamily: 'CascadiaCode',
                      fontSize: 14,
                    ),
                  ),
                  onChanged: _onTextChanged,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
              tooltip: 'Отправить',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    return GestureDetector(
      onLongPress: () => _showDeleteMessageDialog(msg.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? LinearGradient(
                              colors: [
                                Colors.blueAccent.withOpacity(0.8),
                                Colors.blue.shade700.withOpacity(0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                      border: Border.all(
                        color: isMe ? Colors.blueAccent.withOpacity(0.5) : Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe && msg.senderName != null && msg.senderName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              msg.senderName!,
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'CascadiaCode',
                              ),
                            ),
                          ),
                        
                        if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  msg.imageUrl!,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 200,
                                      height: 150,
                                      color: Colors.white10,
                                      child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 200,
                                      height: 150,
                                      color: Colors.redAccent.withOpacity(0.2),
                                      child: const Icon(Icons.broken_image, color: Colors.white54),
                                    );
                                  },
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),

                        if (msg.text.isNotEmpty)
                          Text(
                            msg.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'CascadiaCode',
                              height: 1.4,
                            ),
                          ),
                        
                        const SizedBox(height: 4),
                        
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      DateFormatter.formatFull(msg.createdAt),
                                      style: const TextStyle(fontFamily: 'CascadiaCode', fontSize: 12),
                                    ),
                                    backgroundColor: Colors.black87,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Text(
                                DateFormatter.formatSmart(msg.createdAt),
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.white54,
                                  fontSize: 10,
                                  fontFamily: 'CascadiaCode',
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.done_all, 
                                size: 12, 
                                color: Colors.greenAccent.withOpacity(0.8),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteMessageDialog(int messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Удалить сообщение?',
          style: TextStyle(color: Colors.white, fontFamily: 'CascadiaCode', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Это действие нельзя отменить.',
          style: TextStyle(color: Colors.white70, fontFamily: 'CascadiaCode'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.white54, fontFamily: 'CascadiaCode')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Удалить', style: TextStyle(color: Colors.white, fontFamily: 'CascadiaCode')),
          ),
        ],
      ),
    );
  }
}