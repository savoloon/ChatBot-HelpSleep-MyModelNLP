import 'package:flutter/material.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/core/theme/app_theme.dart';

class SleepHelperApp extends StatelessWidget {
  const SleepHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Helper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.chatRoute,
    );
  }
}
