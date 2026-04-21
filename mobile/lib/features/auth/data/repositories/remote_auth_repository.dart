import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/core/config/api_config.dart';
import 'package:mobile/features/auth/data/models/auth_result.dart';
import 'package:mobile/features/auth/data/models/token_pair.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/register');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );
    final json = _decodeBody(response);
    _throwIfFailed(response.statusCode, json);
    return AuthResult.fromRegisterJson(json);
  }

  @override
  Future<AuthResult> auth({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );
    final json = _decodeBody(response);
    _throwIfFailed(response.statusCode, json);
    return AuthResult.fromAuthJson(json);
  }

  @override
  Future<TokenPair> refresh({required String refreshToken}) async {
    final uri = Uri.parse('$_baseUrl/refresh');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(<String, dynamic>{'refresh_token': refreshToken}),
    );
    final json = _decodeBody(response);
    _throwIfFailed(response.statusCode, json);
    return TokenPair.fromJson(json);
  }

  Map<String, String> get _headers => const <String, String>{
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _decodeBody(http.Response response) {
    final decoded = utf8.decode(response.bodyBytes);
    final json = jsonDecode(decoded);
    if (json is Map<String, dynamic>) return json;
    throw const FormatException('Unexpected API response format.');
  }

  void _throwIfFailed(int statusCode, Map<String, dynamic> body) {
    if (statusCode >= 200 && statusCode < 300) return;
    final detail = body['detail'] as String? ?? 'Auth request failed.';
    throw Exception(detail);
  }
}
