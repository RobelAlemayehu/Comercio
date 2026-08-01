import '../../../../core/errors/failure.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? token;
  final Failure? failure;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
    this.failure,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    Failure? failure,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      failure: failure ?? this.failure,
    );
  }

  @override
  String toString() => 'AuthState(status: $status, token: $token, failure: $failure)';
}
