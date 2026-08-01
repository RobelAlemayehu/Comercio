import 'package:dio/dio.dart';
import '../errors/failure.dart';

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
