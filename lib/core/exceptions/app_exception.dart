/// Exceção base para toda a aplicação
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  AppException({required this.message, this.code, this.originalException});

  @override
  String toString() => message;
}

/// Exceção de rede/conectividade
class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    Exception? originalException,
  }) : super(
         message: message,
         code: code ?? 'NETWORK_ERROR',
         originalException: originalException,
       );
}

/// Exceção de servidor (5xx)
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    String? code,
    this.statusCode,
    Exception? originalException,
  }) : super(
         message: message,
         code: code ?? 'SERVER_ERROR',
         originalException: originalException,
       );
}

/// Exceção de cliente (4xx)
class ClientException extends AppException {
  final int? statusCode;

  ClientException({
    required String message,
    String? code,
    this.statusCode,
    Exception? originalException,
  }) : super(
         message: message,
         code: code ?? 'CLIENT_ERROR',
         originalException: originalException,
       );
}

/// Exceção de validação
class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  ValidationException({
    required String message,
    String? code,
    this.errors,
    Exception? originalException,
  }) : super(
         message: message,
         code: code ?? 'VALIDATION_ERROR',
         originalException: originalException,
       );
}

/// Exceção genérica
class UnknownException extends AppException {
  UnknownException({
    required String message,
    String? code,
    Exception? originalException,
  }) : super(
         message: message,
         code: code ?? 'UNKNOWN_ERROR',
         originalException: originalException,
       );
}
