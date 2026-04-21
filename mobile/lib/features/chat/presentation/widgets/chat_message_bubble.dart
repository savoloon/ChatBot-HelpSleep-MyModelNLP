import 'package:flutter/material.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.author == MessageAuthor.user;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isUser
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.88),
                      ],
                    )
                  : null,
              color: isUser ? null : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isUser
                        ? theme.colorScheme.onPrimary.withOpacity(0.82)
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.72),
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(height: 2),
                  _StatusLabel(
                    status: message.status,
                    isUser: isUser,
                    onRetry: message.status == ChatMessageStatus.failed
                        ? onRetry
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    required this.status,
    required this.isUser,
    this.onRetry,
  });

  final ChatMessageStatus status;
  final bool isUser;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final baseColor = isUser
        ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.84)
        : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8);

    switch (status) {
      case ChatMessageStatus.pending:
        return Text(
          'Отправляется...',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: baseColor),
        );
      case ChatMessageStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: Text(
            'Не отправлено. Нажми, чтобы повторить.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.orange.shade200,
                  decoration: TextDecoration.underline,
                ),
          ),
        );
      case ChatMessageStatus.sent:
        return Text(
          'Отправлено',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: baseColor),
        );
    }
  }
}
