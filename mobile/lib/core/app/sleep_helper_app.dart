import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/screens/auth_page.dart';
import 'package:mobile/features/auth/presentation/screens/session_expired_page.dart';
import 'package:mobile/features/auth/presentation/state/auth_controller.dart';
import 'package:mobile/features/chat/presentation/screens/chat_page.dart';

class SleepHelperApp extends StatefulWidget {
  const SleepHelperApp({super.key});

  @override
  State<SleepHelperApp> createState() => _SleepHelperAppState();
}

class _SleepHelperAppState extends State<SleepHelperApp> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController()..initialize();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _authController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Sleep Helper',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (!_authController.isInitialized || _authController.isBusy) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_authController.sessionExpired) {
      return SessionExpiredPage(controller: _authController);
    }

    if (_authController.isAuthenticated) {
      return ChatPage(authController: _authController);
    }

    return AuthPage(controller: _authController);
  }
}
