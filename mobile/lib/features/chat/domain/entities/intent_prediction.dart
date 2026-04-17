class IntentPrediction {
  IntentPrediction({
    required this.intentId,
    required this.intentName,
    required this.confidence,
    required this.responseText,
  });

  final int intentId;
  final String intentName;
  final double confidence;
  final String responseText;
}
