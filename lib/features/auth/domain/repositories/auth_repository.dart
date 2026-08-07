import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/models/login_request_model.dart';

class AuthRepository extends BaseRepository {
  final ApiClient _apiClient;
  final LocalStorageService _storageService;

  AuthRepository(this._apiClient, this._storageService);

  Future<Result<String>> login({
    required String username,
    required String password,
  }) async {
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

  Future<void> logout() async {
    await _storageService.clearAuthToken();
  }

  String? getSavedToken() {
    return _storageService.getAuthToken();
  }

  bool isAuthenticated() {
    final token = getSavedToken();
    return token != null && token.isNotEmpty;
  }
}
