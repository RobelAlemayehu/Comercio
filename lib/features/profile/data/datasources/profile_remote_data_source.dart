import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getUserProfile(int id);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserModel> getUserProfile(int id) async {
    final response = await _apiClient.get(ApiEndpoints.userProfile(id));
    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw Exception('Invalid profile data format received from server');
  }
}
