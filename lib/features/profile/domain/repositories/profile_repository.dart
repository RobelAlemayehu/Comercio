import '../../../../core/repositories/base_repository.dart';
import '../../data/models/user_model.dart';

abstract class ProfileRepository {
  Future<Result<UserModel>> getUserProfile(int id);
}
