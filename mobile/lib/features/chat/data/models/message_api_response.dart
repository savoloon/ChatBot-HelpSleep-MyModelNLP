class MessageApiResponse {
  MessageApiResponse({
    required this.response,
    required this.intentId,
    required this.intentName,
    required this.confidence,
  });

  final String response;
  final int intentId;
  final String intentName;
  final double confidence;

  factory MessageApiResponse.fromJson(Map<String, dynamic> json) {
    return MessageApiResponse(
      response: json['response'] as String,
      intentId: json['intent_id'] as int,
      intentName: json['intent_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}
