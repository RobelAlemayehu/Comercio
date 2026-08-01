import '../../../../core/repositories/base_repository.dart';

abstract class AuthRepository {
  Future<Result<String>> login({
    required String username,
    required String password,
  });

  Future<void> logout();

  String? getSavedToken();

  bool isAuthenticated();
}
