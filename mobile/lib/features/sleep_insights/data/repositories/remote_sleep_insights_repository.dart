import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/core/config/api_config.dart';
import 'package:mobile/features/auth/presentation/state/auth_controller.dart';
import 'package:mobile/features/sleep_insights/data/models/sleep_info_api_item.dart';
import 'package:mobile/features/sleep_insights/domain/entities/sleep_insight.dart';

class RemoteSleepInsightsRepository {
  RemoteSleepInsightsRepository({
    required AuthController authController,
    http.Client? client,
    String? baseUrl,
  })  : _authController = authController,
        _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final AuthController _authController;
  final http.Client _client;
  final String _baseUrl;

  Future<List<SleepInsight>> loadInsights({
    required String period,
  }) async {
    final uri = Uri.parse('$_baseUrl/sleep-info/history?period=$period');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 401) {
      final refreshed = await _authController.tryRefreshTokens();
      if (refreshed) {
        return loadInsights(period: period);
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load sleep insights: ${response.statusCode}');
    }

    final decodedBody = utf8.decode(response.bodyBytes);
    final json = jsonDecode(decodedBody) as Map<String, dynamic>;
    final items = (json['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(SleepInfoApiItem.fromJson)
        .where((item) => item.duration != null)
        .map(
          (item) => SleepInsight(
            id: item.id,
            date: item.date,
            duration: item.duration!,
            schedule: item.schedule,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return items;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = _authController.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
