import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/chat_list_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const PixarApp());
}

class PixarApp extends StatefulWidget {
  const PixarApp({super.key});

  @override
  State<PixarApp> createState() => _PixarAppState();
}

class _PixarAppState extends State<PixarApp> {
  final AuthService _authService = AuthService();
  
  // Экран по умолчанию (загрузка)
  Widget _initialScreen = const Scaffold(
    body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
  );

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // Проверка: залогинен пользователь или нет
  Future<void> _checkAuth() async {
    final user = await _authService.checkAuth();
    if (!mounted) return;
    
    setState(() {
      _initialScreen = user != null
          ? ChatListScreen(currentUserId: user.id)
          : const LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixar Messenger',
      debugShowCheckedModeBanner: false,
      
      // 🎨 НАСТРОЙКИ ТЕМЫ (ДОБАВЛЕНО)
      theme: ThemeData(
        // 1. Базовый темный фон
        scaffoldBackgroundColor: const Color(0xFF0f172a),
        
        // 2. Шрифт Cascadia Code везде
        fontFamily: 'CascadiaCode',
        
        // 3. Цветовая схема
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.lightBlueAccent,
          surface: const Color(0xFF1e293b),
          background: const Color(0xFF0f172a),
          error: Colors.redAccent,
        ),

        // 4. Стиль верхней панели (AppBar)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1e293b),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'CascadiaCode',
            letterSpacing: 1.5,
          ),
          iconTheme: IconThemeData(color: Colors.blueAccent),
        ),

        // 5. Стиль кнопок
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'CascadiaCode',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 6. Стиль полей ввода
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontFamily: 'CascadiaCode',
          ),
          labelStyle: const TextStyle(
            color: Colors.blueAccent,
            fontFamily: 'CascadiaCode',
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),

        // 7. Стиль текста
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontFamily: 'CascadiaCode'),
          bodyMedium: TextStyle(color: Colors.white70, fontFamily: 'CascadiaCode'),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'CascadiaCode'),
          labelLarge: TextStyle(color: Colors.white, fontFamily: 'CascadiaCode'),
        ),
        
        // 8. Стиль карточек
        cardTheme: CardThemeData(
          color: const Color(0xFF1e293b).withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      // КОНЕЦ НАСТРОЕК ТЕМЫ

      home: _initialScreen,
    );
  }
}