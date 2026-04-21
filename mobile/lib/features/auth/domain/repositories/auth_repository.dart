import 'package:mobile/features/auth/data/models/auth_result.dart';
import 'package:mobile/features/auth/data/models/token_pair.dart';

abstract class AuthRepository {
  Future<AuthResult> register({
    required String email,
    required String password,
  });

  Future<AuthResult> auth({
    required String email,
    required String password,
  });

  Future<TokenPair> refresh({
    required String refreshToken,
  });
}
