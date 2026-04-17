import 'package:flutter/material.dart';
import 'package:mobile/features/chat/presentation/state/chat_controller.dart';
import 'package:mobile/features/chat/presentation/widgets/chat_input.dart';
import 'package:mobile/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:mobile/features/chat/presentation/widgets/chat_typing_indicator.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatController()..initialize();
  }

  @override
  void dispose() {
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
            title: const Text('Sleep Chat'),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: _controller.messages.length +
                      (_controller.isAssistantTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_controller.isAssistantTyping && index == 0) {
                      return const ChatTypingIndicator();
                    }

                    final offset = _controller.isAssistantTyping ? 1 : 0;
                    final reverseIndex =
                        _controller.messages.length - 1 - (index - offset);
                    final message = _controller.messages[reverseIndex];
                    return ChatMessageBubble(message: message);
                  },
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
}
