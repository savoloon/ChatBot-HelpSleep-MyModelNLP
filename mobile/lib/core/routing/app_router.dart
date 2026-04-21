import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter._();

  static const String rootRoute = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text('Routing is handled by SleepHelperApp home widget.'),
        ),
      ),
      settings: settings,
    );
  }
}
