import 'package:flutter/material.dart';
import 'package:mobile/features/auth/presentation/state/auth_controller.dart';

class SessionExpiredPage extends StatelessWidget {
  const SessionExpiredPage({
    required this.controller,
    super.key,
  });

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Сессия истекла',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Токен обновления тоже истек или недействителен. '
                    'Для продолжения работы войдите в аккаунт снова.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: controller.acknowledgeSessionExpired,
                    child: const Text('Войти снова'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
