import 'package:mobile/features/auth/data/models/token_pair.dart';

class AuthResult {
  const AuthResult({
    required this.userId,
    required this.email,
    required this.tokens,
  });

  final int userId;
  final String email;
  final TokenPair tokens;

  factory AuthResult.fromRegisterJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    final tokensJson = json['tokens'] as Map<String, dynamic>;
    return AuthResult(
      userId: userJson['id'] as int,
      email: userJson['email'] as String,
      tokens: TokenPair.fromJson(tokensJson),
    );
  }

  factory AuthResult.fromAuthJson(Map<String, dynamic> json) {
    return AuthResult(
      userId: 0,
      email: '',
      tokens: TokenPair.fromJson(json),
    );
  }
}
