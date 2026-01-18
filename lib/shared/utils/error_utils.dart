import 'package:dio/dio.dart';

/// Utilitário para extração de mensagens de erro de forma padronizada
class ErrorUtils {
  ErrorUtils._();

  static String extractErrorMessage(
    Object? error, [
    String defaultMessage = 'Erro desconhecido',
  ]) {
    if (error == null) return defaultMessage;

    if (error is DioException) {
      // A mensagem pode estar em error.error (interceptor coloca lá)
      if (error.error != null && error.error is String) {
        return error.error.toString();
      }

      // Ou diretamente em response.data['message']
      if (error.response?.data is Map<String, dynamic>) {
        final data = error.response!.data as Map<String, dynamic>;
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
      }

      // Fallback para mensagem padrão do Dio
      return error.message ?? defaultMessage;
    }

    // Se for Exception genérica, remove o prefixo "Exception: "
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    // Qualquer outro tipo de erro
    return error.toString();
  }
}
