import 'dart:convert';
import 'package:coisa_rapida/core/config/config.dart';
import 'package:coisa_rapida/core/services/logger_service.dart';
import 'package:coisa_rapida/features/auth/models/auth_model.dart';
import 'package:coisa_rapida/features/auth/repositories/auth_repository.dart';
import 'package:coisa_rapida/shared/providers/secure_storage_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(ref) {
  final dio = ref.read(authDioProvider);
  return AuthRepository(dio);
}

@riverpod
class Auth extends _$Auth {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _authDataKey = 'auth_data';

  @override
  Future<String?> build() async {
    final secureStorage = ref.read(secureStorageProvider);
    final authDataString = await secureStorage.read(key: _authDataKey);

    if (authDataString != null) {
      try {
        final jsonData = jsonDecode(authDataString) as Map<String, dynamic>;
        final authModel = AuthModel.fromJson(jsonData);

        if (!authModel.estaExpirado) {
          return authModel.accessToken;
        } else {
          // Token expirado, tentar refresh
          final authRepository = ref.read(authRepositoryProvider);
          final novoAuthModel = await authRepository.refreshToken(
            authModel.refreshToken,
          );
          if (novoAuthModel != null) {
            await setAuthModelSecure(novoAuthModel);
            return novoAuthModel.accessToken;
          } else {
            await limparToken();
            return null;
          }
        }
      } catch (e) {
        await limparToken();
        return null;
      }
    }

    return null;
  }

  Future<void> login(String email, String senha) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      final authModel = await authRepository.login(email, senha);
      await setAuthModelSecure(authModel);
      return authModel.accessToken;
    });
  }

  Future<void> logout() async {
    try {
      final secureStorage = ref.read(secureStorageProvider);
      final authDataString = await secureStorage.read(key: _authDataKey);

      String? refreshToken;
      if (authDataString != null) {
        try {
          final jsonData = jsonDecode(authDataString) as Map<String, dynamic>;
          final authModel = AuthModel.fromJson(jsonData);
          refreshToken = authModel.refreshToken;
        } catch (e) {
          // Erro ao decodificar, continua sem token
        }
      }
      logger.i('Fazendo logout com refresh token: $refreshToken');
      final authRepository = ref.read(authRepositoryProvider);
      if (refreshToken != null) {
        await authRepository.logout(refreshToken);
      }
    } finally {
      await limparToken();
    }
  }

  Future<void> limparToken() async {
    final storage = ref.read(secureStorageProvider);
    await Future.wait([
      storage.delete(key: _accessTokenKey),
      storage.delete(key: _refreshTokenKey),
      storage.delete(key: _authDataKey),
    ]);
    state = const AsyncValue.data(null);
  }

  Future<void> setAuthModelSecure(AuthModel authModel) async {
    final storage = ref.read(secureStorageProvider);
    final authDataString = jsonEncode(authModel.toJson());

    await storage.write(key: _authDataKey, value: authDataString);
    state = AsyncValue.data(authModel.accessToken);
  }
}

/// Dio separado para autenticação, sem interceptors para evitar dependência circular
@riverpod
Dio authDio(Ref ref) {
  return Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      headers: {'Accept': 'application/json'},
      validateStatus: (status) => status != null && status < 400,
    ),
  );
}
