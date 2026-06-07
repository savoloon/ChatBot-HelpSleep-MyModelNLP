import 'package:flutter/material.dart';
import 'package:mobile/features/auth/presentation/state/auth_controller.dart';
import 'package:mobile/features/chat/presentation/screens/chat_page.dart';
import 'package:mobile/features/sleep_insights/presentation/screens/sleep_insights_page.dart';
import 'package:mobile/features/sleep_insights/presentation/state/sleep_insights_controller.dart';

class AuthenticatedShell extends StatefulWidget {
  const AuthenticatedShell({required this.authController, super.key});

  final AuthController authController;

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<AuthenticatedShell> {
  int _tabIndex = 0;
  late final SleepInsightsController _insightsController;

  @override
  void initState() {
    super.initState();
    _insightsController =
        SleepInsightsController(authController: widget.authController)
          ..initialize();
  }

  @override
  void dispose() {
    _insightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          ChatPage(
            authController: widget.authController,
            onOpenInsights: () => setState(() => _tabIndex = 1),
          ),
          SleepInsightsPage(controller: _insightsController),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (value) => setState(() => _tabIndex = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
