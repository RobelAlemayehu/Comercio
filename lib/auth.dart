
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'base.dart';
import 'cart.dart';
import 'network.dart';
import 'storage.dart';
import 'theme.dart';
import 'widgets.dart';

class LoginRequestModel {
  final String username;
  final String password;

  const LoginRequestModel({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? token;
  final Failure? failure;

  const AuthState({this.status = AuthStatus.initial, this.token, this.failure});

  AuthState copyWith({AuthStatus? status, String? token, Failure? failure}) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      failure: failure ?? this.failure,
    );
  }

  @override
  String toString() => 'AuthState(status: $status, token: $token, failure: $failure)';
}

class AuthRepository extends BaseRepository {
  final ApiClient _apiClient;
  final LocalStorageService _storageService;

  AuthRepository(this._apiClient, this._storageService);

  Future<Result<String>> login({required String username, required String password}) async {
    return safeApiCall(() async {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: LoginRequestModel(username: username, password: password).toJson(),
      );
      if (response is Map && response.containsKey('token')) {
        final token = response['token'].toString();
        await _storageService.saveAuthToken(token);
        return token;
      }
      throw Exception('Invalid token response from server');
    });
  }

  Future<void> logout() async => await _storageService.clearAuthToken();

  String? getSavedToken() => _storageService.getAuthToken();

  bool isAuthenticated() {
    final token = getSavedToken();
    return token != null && token.isNotEmpty;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return AuthRepository(apiClient, localStorage);
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

  AuthNotifier(this._authRepository, this._localStorage, this._ref) : super(const AuthState()) {
    checkAuthStatus();
  }

  void checkAuthStatus() {
    final token = _authRepository.getSavedToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(status: AuthStatus.authenticated, token: token);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated, token: null);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, failure: null);

    final result = await _authRepository.login(
      username: username.trim(),
      password: password.trim(),
    );

    if (result is Success<String>) {
      state = state.copyWith(status: AuthStatus.authenticated, token: result.data);
      return true;
    } else if (result is Error<String>) {
      state = state.copyWith(status: AuthStatus.error, failure: result.failure);
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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(authNotifierProvider.notifier).login(
          _usernameController.text,
          _passwordController.text,
        );

    if (mounted) {
      if (success) {
        AppSnackbar.success(context, 'Login successful! Welcome to Comercio.');
        context.go(AppRoutes.home);
      } else {
        final failure = ref.read(authNotifierProvider).failure;
        AppSnackbar.error(context, failure?.message ?? 'Login failed. Please check your credentials.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.authenticating;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FadeSlideIn(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderXl,
                    side: BorderSide(
                      color: theme.brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.shopping_bag_rounded, size: 44, color: theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text('Comercio', textAlign: TextAlign.center, style: theme.textTheme.displaySmall),
                          const SizedBox(height: AppSpacing.xxs),
                          Text('Sign in to access your e-commerce dashboard', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: AppSpacing.xl),
                          AppTextField(
                            controller: _usernameController,
                            label: 'Username',
                            hint: 'Enter your username',
                            prefixIcon: Icons.person_outline_rounded,
                            enabled: !isLoading,
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Username is required' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            enabled: !isLoading,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Password is required' : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(text: 'Sign In', isLoading: isLoading, onPressed: _submitLogin),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.05),
                              borderRadius: AppRadius.borderMd,
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Demo Credentials', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: AppSpacing.xs),
                                Text('Username: mor_2314', style: theme.textTheme.bodySmall),
                                Text('Password: 83r5^_', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
