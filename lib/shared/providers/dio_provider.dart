import 'package:coisa_rapida/core/config/config.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'user_agent_provider.dart';

part 'dio_provider.g.dart';

@riverpod
Future<Dio> dio(ref) async {
  final userAgentValue = await ref.watch(userAgentProvider.future);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      headers: {'Accept': 'application/json', 'User-Agent': userAgentValue},
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final tokenAsync = ref.read(authProvider);
        final token = await tokenAsync.when(
          data: (token) => token,
          loading: () => null,
          error: (_, __) => null,
        );

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          ref.read(authProvider.notifier).clearToken();
        }
        return handler.next(error);
      },
    ),
  );

  //logging (apenas em debug)
  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (object) => print('DIO: $object'),
    ),
  );

  return dio;
}
