import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
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
  final localStorage = ref.watch(localStorageServiceProvider);
  return AuthNotifier(authRepository, localStorage, ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final LocalStorageService _localStorage;
  final Ref _ref;

  AuthNotifier(this._authRepository, this._localStorage, this._ref)
      : super(const AuthState()) {
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
    await _localStorage.clearCartData();
    _ref.read(cartNotifierProvider.notifier).emptyCart();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
