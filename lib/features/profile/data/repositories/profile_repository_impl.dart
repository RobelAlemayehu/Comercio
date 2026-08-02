import '../../../../core/repositories/base_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/user_model.dart';

class ProfileRepositoryImpl extends BaseRepository implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<UserModel>> getUserProfile(int id) async {
    return safeApiCall(() => _remoteDataSource.getUserProfile(id));
  }
}
