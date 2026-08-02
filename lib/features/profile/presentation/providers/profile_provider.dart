import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRemoteDataSourceImpl(apiClient);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDataSource = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(remoteDataSource);
});

/// Fetches user profile for a given user ID (defaults to ID 1)
final userProfileProvider = FutureProvider.family<UserModel, int>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getUserProfile(userId);
  if (result is Success<UserModel>) {
    return result.data;
  } else if (result is Error<UserModel>) {
    throw Exception(result.failure.message);
  }
  throw Exception('Unknown error loading profile');
});
