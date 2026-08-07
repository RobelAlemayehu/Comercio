import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../data/models/user_model.dart';

class ProfileRepository extends BaseRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<Result<UserModel>> getUserProfile(int id) async {
    return safeApiCall(() async {
      final response = await _apiClient.get(ApiEndpoints.userProfile(id));
      if (response is Map<String, dynamic>) {
        return UserModel.fromJson(response);
      }
      throw Exception('Invalid profile data format received from server');
    });
  }
}
