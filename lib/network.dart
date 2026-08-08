
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'base.dart';
import 'storage.dart';

abstract class ApiEndpoints {
  static const String baseUrl = 'https://fakestoreapi.com';

  static const String login = '/auth/login';

  static const String products = '/products';
  static String productDetails(int id) => '/products/$id';
  static const String categories = '/products/categories';
  static String categoryProducts(String category) => '/products/category/$category';

  static const String carts = '/carts';
  static String userCart(int userId) => '/carts/user/$userId';

  static const String users = '/users';
  static String userProfile(int id) => '/users/$id';
}

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  const NetworkException({required this.message, this.statusCode});

  factory NetworkException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Connection timed out. Please check your network.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String message = 'Server error status code: $statusCode';

        if (data is Map && data.containsKey('message')) {
          message = data['message'].toString();
        } else if (data is String && data.isNotEmpty) {
          message = data;
        } else if (error.response?.statusMessage != null) {
          message = error.response!.statusMessage!;
        }

        return NetworkException(message: message, statusCode: statusCode);
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');
      default:
        return NetworkException(
          message: error.message ?? 'An unexpected network error occurred.',
        );
    }
  }

  Failure toFailure() {
    if (statusCode == 401 || statusCode == 403) {
      return AuthFailure(message: message, statusCode: statusCode);
    }
    if (statusCode != null && statusCode! >= 500) {
      return ServerFailure(message: message, statusCode: statusCode);
    }
    if (statusCode == null) {
      return NetworkFailure(message: message);
    }
    return ServerFailure(message: message, statusCode: statusCode);
  }

  @override
  String toString() => 'NetworkException: $message (statusCode: $statusCode)';
}

abstract class ApiClient {
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, Options? options});
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options});
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options});
  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options});
}

class DioApiClient implements ApiClient {
  final Dio _dio;
  DioApiClient(this._dio);

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters, options: options);
      return response.data;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
      return response.data;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  @override
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
      return response.data;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  @override
  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
      return response.data;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }
}

class AppLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('REQUEST [${options.method.toUpperCase()}] => ${options.uri}');
      debugPrint('Headers: ${options.headers}');
      if (options.data != null) debugPrint('Payload: ${options.data}');
      debugPrint('--------------------------------------------------');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('RESPONSE [${response.statusCode}] <= ${response.requestOptions.uri}');
      debugPrint('Data: ${response.data}');
      debugPrint('--------------------------------------------------');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('ERROR [${err.response?.statusCode}] <= ${err.requestOptions.uri}');
      debugPrint('Message: ${err.message}');
      if (err.response?.data != null) debugPrint('Error Data: ${err.response?.data}');
      debugPrint('--------------------------------------------------');
    }
    super.onError(err, handler);
  }
}

class AuthInterceptor extends Interceptor {
  final LocalStorageService _storageService;
  AuthInterceptor(this._storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}

final dioProvider = Provider<Dio>((ref) {
  final storageService = ref.watch(localStorageServiceProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(storageService),
    AppLoggingInterceptor(),
  ]);

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return DioApiClient(dio);
});
