import 'package:mobile/features/chat/domain/entities/chat_message.dart';
import 'package:mobile/features/chat/domain/entities/intent_prediction.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> loadInitialMessages();
  Future<IntentPrediction> predictIntent(String text);
}
