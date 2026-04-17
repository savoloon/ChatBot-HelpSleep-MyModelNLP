import 'package:mobile/features/chat/domain/entities/chat_message.dart';
import 'package:mobile/features/chat/domain/entities/intent_prediction.dart';
import 'package:mobile/features/chat/domain/repositories/chat_repository.dart';

class InMemoryChatRepository implements ChatRepository {
  final List<ChatMessage> _messages = <ChatMessage>[
    ChatMessage(
      id: 'assistant-1',
      text: 'Hi! I am Sleep Helper. Tell me how your sleep was today.',
      author: MessageAuthor.assistant,
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<ChatMessage>> loadInitialMessages() async {
    return List<ChatMessage>.unmodifiable(_messages);
  }

  @override
  Future<IntentPrediction> predictIntent(String text) async {
    final lowered = text.toLowerCase();
    final intentName = lowered.contains('sleep') || lowered.contains('сон')
        ? 'sleep_duration_report'
        : 'other';
    final intentId = intentName == 'sleep_duration_report' ? 1 : 4;

    return IntentPrediction(
      intentId: intentId,
      intentName: intentName,
      confidence: 0.5,
      responseText: 'Ответ модели: $intentName',
    );
  }
}
