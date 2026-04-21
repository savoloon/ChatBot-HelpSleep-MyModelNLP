import 'package:flutter/material.dart';
import 'package:mobile/features/auth/presentation/state/auth_controller.dart';
import 'package:mobile/features/chat/presentation/state/chat_controller.dart';
import 'package:mobile/features/chat/presentation/widgets/chat_input.dart';
import 'package:mobile/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:mobile/features/chat/presentation/widgets/chat_typing_indicator.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.authController,
    super.key,
  });

  final AuthController authController;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;
  final ScrollController _scrollController = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = ChatController(authController: widget.authController)
      ..initialize();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              widget.authController.email?.isNotEmpty == true
                  ? 'Sleep Chat (${widget.authController.email})'
                  : 'Sleep Chat',
            ),
            actions: [
              IconButton(
                tooltip: 'Logout',
                onPressed: () => widget.authController.logout(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Расскажи, как ты спал сегодня. История синхронизируется и кэшируется офлайн.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
              Expanded(
                child: _controller.isBootstrapping
                    ? const _ChatLoadingSkeleton()
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        children: _buildTimelineItems(context),
                      ),
              ),
              ChatInput(
                isSending: _controller.isLoading,
                onSend: _controller.sendMessage,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTimelineItems(BuildContext context) {
    final result = <Widget>[];
    final messages = _controller.messages;
    DateTime? previousDay;
    for (final message in messages) {
      final day = DateTime(
        message.createdAt.year,
        message.createdAt.month,
        message.createdAt.day,
      );
      if (previousDay == null || day != previousDay) {
        result.add(_DateDivider(date: message.createdAt));
        previousDay = day;
      }
      result.add(
        ChatMessageBubble(
          message: message,
          onRetry: () => _controller.retryFailedMessage(message.id),
        ),
      );
    }
    if (_controller.isAssistantTyping) {
      result.add(const ChatTypingIndicator());
    }
    return result;
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final currentCount = _controller.messages.length;
    if (currentCount != _lastCount || _controller.isAssistantTyping) {
      _lastCount = currentCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      });
    }
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final current = DateTime(date.year, date.month, date.day);
    String title;
    if (current == today) {
      title = 'Сегодня';
    } else if (current == yesterday) {
      title = 'Вчера';
    } else {
      title = '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(title, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class _ChatLoadingSkeleton extends StatelessWidget {
  const _ChatLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      children: const [
        _SkeletonLine(widthFactor: 0.36, alignRight: false),
        _SkeletonLine(widthFactor: 0.64, alignRight: true),
        _SkeletonLine(widthFactor: 0.58, alignRight: false),
        _SkeletonLine(widthFactor: 0.72, alignRight: true),
        _SkeletonLine(widthFactor: 0.48, alignRight: false),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, required this.alignRight});

  final double widthFactor;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: 54,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceVariant
                  .withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
