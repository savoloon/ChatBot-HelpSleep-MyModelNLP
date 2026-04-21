import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/core/config/api_config.dart';
import 'package:mobile/features/auth/presentation/state/auth_controller.dart';
import 'package:mobile/features/chat/data/models/chat_history_api_item.dart';
import 'package:mobile/features/chat/data/models/message_api_response.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';
import 'package:mobile/features/chat/domain/entities/intent_prediction.dart';
import 'package:mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteChatRepository implements ChatRepository {
  RemoteChatRepository({
    http.Client? client,
    String? baseUrl,
    AuthController? authController,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _authController = authController;

  final http.Client _client;
  final String _baseUrl;
  final AuthController? _authController;
  static const Duration _cacheRetention = Duration(days: 2);
  static const String _cacheKeyPrefix = 'chat_cache_v1_';

  @override
  Future<List<ChatMessage>> loadInitialMessages() async {
    final cached = await _loadCachedMessages();
    try {
      final remote = await _loadRemoteHistory();
      if (remote.isNotEmpty) {
        await _saveCachedMessages(remote);
        return remote;
      }
    } catch (_) {
      if (cached.isNotEmpty) return cached;
      return _fallbackMessages();
    }

    if (cached.isNotEmpty) return cached;
    return _fallbackMessages();
  }

  @override
  Future<IntentPrediction> predictIntent(String text) async {
    final uri = Uri.parse('$_baseUrl/messages');
    final response = await _client.post(
      uri,
      headers: _buildHeaders(),
      body: jsonEncode(<String, dynamic>{'message': text}),
    );

    if (response.statusCode == 401 && _authController != null) {
      final refreshed = await _authController.tryRefreshTokens();
      if (refreshed) {
        return _retryPredict(uri, text);
      }
    }

    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed: ${response.statusCode} $decodedBody',
      );
    }

    final json = jsonDecode(decodedBody) as Map<String, dynamic>;
    final payload = MessageApiResponse.fromJson(json);
    await _appendMessagePairToCache(
        userText: text, assistantText: payload.response);

    return IntentPrediction(
      intentId: payload.intentId,
      intentName: payload.intentName,
      confidence: payload.confidence,
      responseText: payload.response,
    );
  }

  Future<IntentPrediction> _retryPredict(Uri uri, String text) async {
    final retriedResponse = await _client.post(
      uri,
      headers: _buildHeaders(),
      body: jsonEncode(<String, dynamic>{'message': text}),
    );
    final decodedBody = utf8.decode(retriedResponse.bodyBytes);
    if (retriedResponse.statusCode < 200 || retriedResponse.statusCode >= 300) {
      throw Exception(
        'Request failed: ${retriedResponse.statusCode} $decodedBody',
      );
    }
    final json = jsonDecode(decodedBody) as Map<String, dynamic>;
    final payload = MessageApiResponse.fromJson(json);
    await _appendMessagePairToCache(
        userText: text, assistantText: payload.response);
    return IntentPrediction(
      intentId: payload.intentId,
      intentName: payload.intentName,
      confidence: payload.confidence,
      responseText: payload.response,
    );
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = _authController?.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<ChatMessage>> _loadRemoteHistory() async {
    final uri = Uri.parse('$_baseUrl/chat/history?days=15&limit=200');
    final response = await _client.get(uri, headers: _buildHeaders());

    if (response.statusCode == 401 && _authController != null) {
      final refreshed = await _authController.tryRefreshTokens();
      if (refreshed) {
        return _loadRemoteHistory();
      }
      throw Exception('Unauthorized');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('History request failed: ${response.statusCode}');
    }

    final decodedBody = utf8.decode(response.bodyBytes);
    final json = jsonDecode(decodedBody) as Map<String, dynamic>;
    final items = (json['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    return items
        .map(ChatHistoryApiItem.fromJson)
        .map(_mapHistoryItemToMessage)
        .where((message) => _isWithinCacheWindow(message.createdAt))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  ChatMessage _mapHistoryItemToMessage(ChatHistoryApiItem item) {
    final author =
        item.role == 'user' ? MessageAuthor.user : MessageAuthor.assistant;
    return ChatMessage(
      id: 'server-${item.id}',
      text: item.text,
      author: author,
      createdAt: item.date,
    );
  }

  Future<List<ChatMessage>> _loadCachedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_cacheKey());
    if (encoded == null || encoded.isEmpty) {
      return <ChatMessage>[];
    }

    final list = jsonDecode(encoded) as List<dynamic>;
    final messages = list
        .cast<Map<String, dynamic>>()
        .map((item) {
          final authorRaw = item['author'] as String? ?? 'assistant';
          final author = authorRaw == 'user'
              ? MessageAuthor.user
              : MessageAuthor.assistant;
          return ChatMessage(
            id: item['id'] as String,
            text: item['text'] as String,
            author: author,
            createdAt: DateTime.parse(item['date'] as String).toLocal(),
          );
        })
        .where((message) => _isWithinCacheWindow(message.createdAt))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    await _saveCachedMessages(messages);
    return messages;
  }

  Future<void> _saveCachedMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = messages
        .where((m) => _isWithinCacheWindow(m.createdAt))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final encoded = jsonEncode(
      filtered
          .map(
            (m) => <String, dynamic>{
              'id': m.id,
              'text': m.text,
              'author': m.author == MessageAuthor.user ? 'user' : 'assistant',
              'date': m.createdAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
    );
    await prefs.setString(_cacheKey(), encoded);
  }

  Future<void> _appendMessagePairToCache({
    required String userText,
    required String assistantText,
  }) async {
    final current = await _loadCachedMessages();
    final now = DateTime.now();
    current.addAll([
      ChatMessage(
        id: 'local-user-${now.microsecondsSinceEpoch}',
        text: userText.trim(),
        author: MessageAuthor.user,
        createdAt: now,
      ),
      ChatMessage(
        id: 'local-assistant-${now.microsecondsSinceEpoch + 1}',
        text: assistantText.trim(),
        author: MessageAuthor.assistant,
        createdAt: now.add(const Duration(milliseconds: 1)),
      ),
    ]);
    await _saveCachedMessages(current);
  }

  bool _isWithinCacheWindow(DateTime date) {
    return date.isAfter(DateTime.now().subtract(_cacheRetention));
  }

  String _cacheKey() {
    final emailPart = (_authController?.email ?? 'anonymous')
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '$_cacheKeyPrefix$emailPart';
  }

  List<ChatMessage> _fallbackMessages() {
    return <ChatMessage>[
      ChatMessage(
        id: 'assistant-1',
        text:
            'Привет! Я Sleep Helper. Напиши, как ты спал сегодня, и я помогу.',
        author: MessageAuthor.assistant,
        createdAt: DateTime.now(),
      ),
    ];
  }
}
