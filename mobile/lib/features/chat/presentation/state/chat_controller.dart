import 'package:flutter/material.dart';
import 'package:mobile/features/chat/data/repositories/in_memory_chat_repository.dart';
import 'package:mobile/features/chat/data/repositories/remote_chat_repository.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';
import 'package:mobile/features/chat/domain/repositories/chat_repository.dart';

class ChatController extends ChangeNotifier {
  ChatController({ChatRepository? repository, bool useRemote = true})
      : _repository = repository ??
            (useRemote ? RemoteChatRepository() : InMemoryChatRepository());

  final ChatRepository _repository;
  final List<ChatMessage> _messages = <ChatMessage>[];

  bool _isBootstrapping = false;
  bool _isAssistantTyping = false;
  int _counter = 1;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get isLoading => _isBootstrapping || _isAssistantTyping;
  bool get isAssistantTyping => _isAssistantTyping;

  Future<void> initialize() async {
    _isBootstrapping = true;
    notifyListeners();

    final initialMessages = await _repository.loadInitialMessages();
    _messages
      ..clear()
      ..addAll(initialMessages);

    _isBootstrapping = false;
    _counter = _messages.length + 1;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = ChatMessage(
      id: 'user-${_counter++}',
      text: trimmed,
      author: MessageAuthor.user,
      createdAt: DateTime.now(),
    );
    _messages.add(userMessage);
    _isAssistantTyping = true;
    notifyListeners();

    try {
      final prediction = await _repository.predictIntent(trimmed);
      final assistantMessage = ChatMessage(
        id: 'assistant-${_counter++}',
        text: prediction.responseText,
        author: MessageAuthor.assistant,
        createdAt: DateTime.now(),
      );
      _messages.add(assistantMessage);
    } catch (_) {
      _messages.add(
        ChatMessage(
          id: 'assistant-${_counter++}',
          text:
              'Не удалось получить ответ от сервера. Проверь, что backend запущен.',
          author: MessageAuthor.assistant,
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      _isAssistantTyping = false;
    }
    notifyListeners();
  }
}
