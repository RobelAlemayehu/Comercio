import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return AuthRepositoryImpl(remoteDataSource, localStorage);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState()) {
    checkAuthStatus();
  }

  void checkAuthStatus() {
    final token = _authRepository.getSavedToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        token: null,
      );
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, failure: null);

    final result = await _authRepository.login(
      username: username.trim(),
      password: password.trim(),
    );

    if (result is Success<String>) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: result.data,
      );
      return true;
    } else if (result is Error<String>) {
      state = state.copyWith(
        status: AuthStatus.error,
        failure: result.failure,
      );
      return false;
    }
    return false;
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
