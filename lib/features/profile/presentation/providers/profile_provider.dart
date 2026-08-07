import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient);
});

/// Fetches user profile for a given user ID (defaults to ID 1)
final userProfileProvider = FutureProvider.family<UserModel, int>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getUserProfile(userId);
  return result.when(
    success: (user) => user,
    failure: (failure) => throw Exception(failure.message),
  );
});
