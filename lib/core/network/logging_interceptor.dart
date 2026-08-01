import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--------------------------------------------------');
      debugPrint('🌐 REQUEST [${options.method.toUpperCase()}] => ${options.uri}');
      debugPrint('Headers: ${options.headers}');
      if (options.data != null) {
        debugPrint('Payload: ${options.data}');
      }
      debugPrint('--------------------------------------------------');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--------------------------------------------------');
      debugPrint('✅ RESPONSE [${response.statusCode}] <= ${response.requestOptions.uri}');
      debugPrint('Data: ${response.data}');
      debugPrint('--------------------------------------------------');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--------------------------------------------------');
      debugPrint('❌ ERROR [${err.response?.statusCode}] <= ${err.requestOptions.uri}');
      debugPrint('Message: ${err.message}');
      if (err.response?.data != null) {
        debugPrint('Error Data: ${err.response?.data}');
      }
      debugPrint('--------------------------------------------------');
    }
    super.onError(err, handler);
  }
}
