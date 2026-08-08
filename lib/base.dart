
import 'network.dart';

abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  String toString() => '$runtimeType: $message (code: $statusCode)';
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.statusCode,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.statusCode});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.statusCode,
  });
}

abstract class BaseRepository {
  Future<Result<T>> safeApiCall<T>(Future<T> Function() apiCall) async {
    try {
      final response = await apiCall();
      return Success(response);
    } on NetworkException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnexpectedFailure(message: e.toString()));
    }
  }
}

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isError   => this is Error<T>;

  T? get dataOrNull         => (this is Success<T>) ? (this as Success<T>).data    : null;
  Failure? get failureOrNull => (this is Error<T>)   ? (this as Error<T>).failure   : null;

  R when<R>({
    required R Function(T data)         success,
    required R Function(Failure failure) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else {
      return failure((this as Error<T>).failure);
    }
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}
