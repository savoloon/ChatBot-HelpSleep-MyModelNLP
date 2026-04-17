import 'package:flutter/material.dart';
import 'package:mobile/features/chat/presentation/screens/chat_page.dart';

class AppRouter {
  const AppRouter._();

  static const String chatRoute = '/chat';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case chatRoute:
        return MaterialPageRoute<void>(
          builder: (_) => const ChatPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const ChatPage(),
          settings: settings,
        );
    }
  }
}
