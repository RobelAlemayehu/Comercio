import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../errors/failure.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ),
  );

  return dio;
});

Failure handleDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      String message = 'Server returned code $statusCode';

      if (responseData is Map && responseData.containsKey('message')) {
        message = responseData['message'].toString();
      } else if (error.response?.statusMessage != null) {
        message = error.response!.statusMessage!;
      }

      if (statusCode == 401 || statusCode == 403) {
        return AuthFailure(message: message, statusCode: statusCode);
      }
      return ServerFailure(message: message, statusCode: statusCode);
    case DioExceptionType.cancel:
      return const ServerFailure(message: 'Request was cancelled');
    default:
      return UnexpectedFailure(
        message: error.message ?? 'An unknown network error occurred.',
      );
  }
}
