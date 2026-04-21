import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/auth/data/models/token_pair.dart';
import 'package:mobile/features/auth/data/repositories/remote_auth_repository.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    AuthRepository? repository,
    FlutterSecureStorage? storage,
  })  : _repository = repository ?? RemoteAuthRepository(),
        _storage = storage ?? const FlutterSecureStorage();

  final AuthRepository _repository;
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _emailKey = 'auth_email';
  static const int _maxFailedLoginAttempts = 3;
  static const Duration _loginLockDuration = Duration(seconds: 30);

  bool _isBusy = false;
  bool _isInitialized = false;
  String? _accessToken;
  String? _refreshToken;
  String? _email;
  String? _error;
  bool _sessionExpired = false;
  int _failedLoginAttempts = 0;
  DateTime? _loginLockedUntil;
  Timer? _lockTicker;

  bool get isBusy => _isBusy;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated =>
      _accessToken != null &&
      _accessToken!.isNotEmpty &&
      _refreshToken != null &&
      _refreshToken!.isNotEmpty;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get email => _email;
  String? get error => _error;
  bool get sessionExpired => _sessionExpired;
  bool get isLoginLocked =>
      _loginLockedUntil != null && DateTime.now().isBefore(_loginLockedUntil!);
  int get loginLockSecondsLeft {
    if (!isLoginLocked) return 0;
    return _loginLockedUntil!.difference(DateTime.now()).inSeconds + 1;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isBusy = true;
    notifyListeners();
    try {
      _accessToken = await _storage.read(key: _accessTokenKey);
      _refreshToken = await _storage.read(key: _refreshTokenKey);
      _email = await _storage.read(key: _emailKey);
      _error = null;
    } finally {
      _isInitialized = true;
      _isBusy = false;
      _startLockTickerIfNeeded();
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    return _runAuthCall(() async {
      final result =
          await _repository.register(email: email, password: password);
      _email = result.email;
      await _saveTokens(result.tokens);
    });
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (isLoginLocked) {
      _error =
          'Слишком много неудачных попыток. Попробуй снова через $loginLockSecondsLeft сек.';
      notifyListeners();
      return false;
    }

    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.auth(email: email, password: password);
      _email = email.trim().toLowerCase();
      await _saveTokens(result.tokens);
      _failedLoginAttempts = 0;
      _loginLockedUntil = null;
      _sessionExpired = false;
      return true;
    } catch (err) {
      _failedLoginAttempts += 1;
      if (_failedLoginAttempts >= _maxFailedLoginAttempts) {
        _loginLockedUntil = DateTime.now().add(_loginLockDuration);
        _startLockTickerIfNeeded();
        _error =
            'Вход временно заблокирован на ${_loginLockDuration.inSeconds} сек. из-за частых неудачных попыток.';
      } else {
        _error = err.toString().replaceFirst('Exception: ', '');
      }
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> tryRefreshTokens() async {
    final token = _refreshToken;
    if (token == null || token.isEmpty) {
      await logout();
      return false;
    }

    try {
      final refreshed = await _repository.refresh(refreshToken: token);
      await _saveTokens(refreshed);
      _error = null;
      _sessionExpired = false;
      notifyListeners();
      return true;
    } catch (_) {
      _sessionExpired = true;
      _error = 'Сессия истекла. Войдите снова.';
      await logout(clearSessionExpired: false);
      return false;
    }
  }

  Future<void> logout({bool clearSessionExpired = true}) async {
    _accessToken = null;
    _refreshToken = null;
    _email = null;
    _error = clearSessionExpired ? null : _error;
    if (clearSessionExpired) {
      _sessionExpired = false;
    }
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _emailKey);
    notifyListeners();
  }

  void acknowledgeSessionExpired() {
    _sessionExpired = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> _runAuthCall(Future<void> Function() action) async {
    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (err) {
      _error = err.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _saveTokens(TokenPair pair) async {
    _accessToken = pair.accessToken;
    _refreshToken = pair.refreshToken;
    await _storage.write(key: _accessTokenKey, value: pair.accessToken);
    await _storage.write(key: _refreshTokenKey, value: pair.refreshToken);
    if (_email != null && _email!.isNotEmpty) {
      await _storage.write(key: _emailKey, value: _email!);
    }
  }

  void _startLockTickerIfNeeded() {
    _lockTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isLoginLocked) {
        _loginLockedUntil = null;
        _lockTicker?.cancel();
        _lockTicker = null;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    super.dispose();
  }
}
