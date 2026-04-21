import 'package:flutter/material.dart';
import 'package:mobile/features/auth/presentation/state/auth_controller.dart';
import 'package:mobile/features/chat/data/repositories/in_memory_chat_repository.dart';
import 'package:mobile/features/chat/data/repositories/remote_chat_repository.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';
import 'package:mobile/features/chat/domain/repositories/chat_repository.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    ChatRepository? repository,
    bool useRemote = true,
    AuthController? authController,
  }) : _repository = repository ??
            (useRemote
                ? RemoteChatRepository(authController: authController)
                : InMemoryChatRepository());

  final ChatRepository _repository;
  final List<ChatMessage> _messages = <ChatMessage>[];

  bool _isBootstrapping = false;
  bool _isAssistantTyping = false;
  int _counter = 1;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get isLoading => _isBootstrapping || _isAssistantTyping;
  bool get isAssistantTyping => _isAssistantTyping;
  bool get isBootstrapping => _isBootstrapping;

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
    await _sendMessageInternal(trimmed);
  }

  Future<void> _sendMessageInternal(String trimmed,
      {String? existingMessageId}) async {
    final userMessageId = existingMessageId ?? 'user-${_counter++}';
    if (existingMessageId == null) {
      final userMessage = ChatMessage(
        id: userMessageId,
        text: trimmed,
        author: MessageAuthor.user,
        createdAt: DateTime.now(),
        status: ChatMessageStatus.pending,
      );
      _messages.add(userMessage);
    } else {
      _setMessageStatus(userMessageId, ChatMessageStatus.pending);
    }
    _isAssistantTyping = true;
    notifyListeners();

    try {
      final prediction = await _repository.predictIntent(trimmed);
      _setMessageStatus(userMessageId, ChatMessageStatus.sent);
      final assistantMessage = ChatMessage(
        id: 'assistant-${_counter++}',
        text: prediction.responseText,
        author: MessageAuthor.assistant,
        createdAt: DateTime.now(),
      );
      _messages.add(assistantMessage);
    } catch (_) {
      _setMessageStatus(userMessageId, ChatMessageStatus.failed);
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

  Future<void> retryFailedMessage(String messageId) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final candidate = _messages[idx];
    if (candidate.author != MessageAuthor.user ||
        candidate.status != ChatMessageStatus.failed) {
      return;
    }
    await _sendMessageInternal(candidate.text, existingMessageId: candidate.id);
  }

  void _setMessageStatus(String messageId, ChatMessageStatus status) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    _messages[idx] = _messages[idx].copyWith(status: status);
  }
}
