import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import 'product_list_provider.dart';

/// Fetches or resolves a single product by ID.
/// Checks the local in-memory catalog cache first; if unavailable, calls the repository.
final productDetailProvider =
    FutureProvider.family<ProductModel?, int>((ref, id) async {
  // Check if product list is already loaded in memory
  final listAsync = ref.read(productListProvider);
  if (listAsync.hasValue) {
    final cached = listAsync.value?.cast<ProductModel?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
    if (cached != null) return cached;
  }

  // Fallback to remote fetching via repository
  final repository = ref.read(productRepositoryProvider);
  final result = await repository.getProduct(id);
  return result.when(
    success: (product) => product,
    failure: (failure) => throw Exception(failure.message),
  );
});
