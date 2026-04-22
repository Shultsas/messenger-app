// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui'; // Для эффекта размытия (BackdropFilter)
import '../models/user.dart';  
import '../services/auth_service.dart';
import 'chat_list_screen.dart';
// Если register_screen отдельный, раскомментируй импорт ниже, если нет - удали
// import 'register_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;
  
  // Анимации
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Заполните все поля');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    User? user;
    if (_isLogin) {
      user = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      user = await _authService.register(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatListScreen(currentUserId: user!.id),
        ),
      );
    } else {
      setState(() => _error = _isLogin 
          ? 'Неверный логин или пароль' 
          : 'Пользователь с таким именем уже существует');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. ТВОЯ КАРТИНКА НА ФОНЕ
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_background.png'), // Твоя картинка
                fit: BoxFit.cover,
              ),
            ),
            // Синее затемнение, чтобы текст читался
            child: Container(
              color: Colors.blue.shade900.withOpacity(0.5),
            ),
          ),
          
          // 2. ОСНОВНОЙ КОНТЕНТ С АНИМАЦИЕЙ
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 3. СТЕКЛЯННАЯ ПЛАШКА (Вместо пиксельной сетки)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: 400,
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Логотип (Текстовый, минимализм)
                                const Text(
                                  'PIXAR',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'CascadiaCode', // НОВЫЙ ШРИФТ
                                    letterSpacing: 4,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 0),
                                        blurRadius: 10,
                                        color: Colors.blueAccent,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isLogin ? 'ВХОД В СИСТЕМУ' : 'РЕГИСТРАЦИЯ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueAccent,
                                    fontFamily: 'CascadiaCode',
                                    letterSpacing: 2,
                                  ),
                                ),
                                
                                const SizedBox(height: 40),
                                
                                // Поля ввода
                                _buildModernTextField(
                                  controller: _usernameController,
                                  hint: 'username',
                                  icon: Icons.person_outline,
                                ),
                                
                                const SizedBox(height: 20),
                                
                                _buildModernTextField(
                                  controller: _passwordController,
                                  hint: 'password',
                                  icon: Icons.lock_outline,
                                  obscureText: true,
                                ),
                                
                                if (_error != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.redAccent, width: 1),
                                    ),
                                    child: Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                        fontFamily: 'CascadiaCode',
                                      ),
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 30),
                                
                                // Кнопка
                                _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: _submit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueAccent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            _isLogin ? 'ВОЙТИ' : 'СОЗДАТЬ АККАУНТ',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'CascadiaCode',
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                
                                const SizedBox(height: 20),
                                
                                // Переключатель
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _error = null;
                                    });
                                  },
                                  child: Text(
                                    _isLogin
                                        ? "Нет аккаунта? Зарегистрироваться"
                                        : "Есть аккаунт? Войти",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontFamily: 'CascadiaCode',
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Современное поле ввода (Стекло + Cascadia)
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'CascadiaCode', // НОВЫЙ ШРИФТ
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontFamily: 'CascadiaCode',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}