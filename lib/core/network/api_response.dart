class ApiResponse<T> {
  final T? data;
  final String? message;
  final int? statusCode;

  const ApiResponse({
    this.data,
    this.message,
    this.statusCode,
  });

  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;

  @override
  String toString() => 'ApiResponse<$T>(statusCode: $statusCode, message: $message, data: $data)';
}
