import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

typedef AuthFailureCallback = void Function();

class ApiClient {
  late final Dio _dio;
  final SecureStorage _storage;
  AuthFailureCallback? onAuthFailure;

  String get baseUrl => _dio.options.baseUrl;

  ApiClient({required SecureStorage storage}) : _storage = storage {
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.0.17:3000/v1',
      ),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    print('[ApiClient] Request to ${options.path}, token: ${token != null ? 'present (${token.substring(0, 20)}...)' : 'null'}');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // Skip refresh logic if this IS the refresh request (avoid infinite loop)
    final isRefreshRequest = error.requestOptions.path.contains('/auth/refresh');

    if (error.response?.statusCode == 401 && !isRefreshRequest) {
      // Token expired, try to refresh
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await _dio.post(
            '/consumer/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final newAccessToken = response.data['data']['tokens']['accessToken'];
          final newRefreshToken = response.data['data']['tokens']['refreshToken'];

          await _storage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // Retry the original request
          final options = error.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await _dio.fetch(options);
          return handler.resolve(retryResponse);
        } catch (_) {
          await _storage.clearTokens();
          // Trigger auth failure callback to redirect to login
          onAuthFailure?.call();
        }
      } else {
        // No refresh token, clear everything and redirect
        await _storage.clearTokens();
        onAuthFailure?.call();
      }
    } else if (error.response?.statusCode == 401 && isRefreshRequest) {
      // Refresh failed, clear tokens and redirect to login
      await _storage.clearTokens();
      onAuthFailure?.call();
    }
    handler.next(error);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}
