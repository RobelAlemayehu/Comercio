import '../../../../core/repositories/base_repository.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request_model.dart';

class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final LocalStorageService _storageService;

  AuthRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  Future<Result<String>> login({
    required String username,
    required String password,
  }) async {
    return await safeApiCall(() async {
      final token = await _remoteDataSource.login(
        LoginRequestModel(username: username, password: password),
      );
      await _storageService.saveAuthToken(token);
      return token;
    });
  }

  @override
  Future<void> logout() async {
    await _storageService.clearAuthToken();
  }

  @override
  String? getSavedToken() {
    return _storageService.getAuthToken();
  }

  @override
  bool isAuthenticated() {
    final token = getSavedToken();
    return token != null && token.isNotEmpty;
  }
}
