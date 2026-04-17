import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/core/config/api_config.dart';
import 'package:mobile/features/chat/data/models/message_api_response.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';
import 'package:mobile/features/chat/domain/entities/intent_prediction.dart';
import 'package:mobile/features/chat/domain/repositories/chat_repository.dart';

class RemoteChatRepository implements ChatRepository {
  RemoteChatRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<List<ChatMessage>> loadInitialMessages() async {
    return <ChatMessage>[
      ChatMessage(
        id: 'assistant-1',
        text: 'Hi! I am Sleep Helper. Tell me how your sleep was today.',
        author: MessageAuthor.assistant,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<IntentPrediction> predictIntent(String text) async {
    final uri = Uri.parse('$_baseUrl/messages');
    final response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'message': text}),
    );

    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed: ${response.statusCode} $decodedBody',
      );
    }

    final json = jsonDecode(decodedBody) as Map<String, dynamic>;
    final payload = MessageApiResponse.fromJson(json);

    return IntentPrediction(
      intentId: payload.intentId,
      intentName: payload.intentName,
      confidence: payload.confidence,
      responseText: payload.response,
    );
  }
}
