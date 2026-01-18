import 'package:coisa_rapida/features/auth/models/auth_model.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthModel> login(String email, String senha) async {
    try {
      final response = await _dio.post(
        '/auth',
        data: {'email': email, 'senha': senha},
      );
      return AuthModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(
        '/auth/logout',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );
    } catch (e) {
      // Mesmo que falhe, continuamos com o logout local
    }
  }

  Future<AuthModel?> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      if (response.statusCode == 200) {
        return AuthModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
