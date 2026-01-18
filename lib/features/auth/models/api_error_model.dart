class ApiError {
  final int statusCode;
  final String message;
  final String error;

  ApiError({
    required this.statusCode,
    required this.message,
    required this.error,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      statusCode: json['statusCode'] ?? 500,
      message: json['message'] ?? 'Erro desconhecido',
      error: json['error'] ?? 'Internal Server Error',
    );
  }

  @override
  String toString() => message;
}
