import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../data/datasources/product_remote_data_source.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductRemoteDataSourceImpl(apiClient);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final remoteDataSource = ref.watch(productRemoteDataSourceProvider);
  return ProductRepositoryImpl(remoteDataSource);
});

final productListProvider =
    StateNotifierProvider<ProductListNotifier, AsyncValue<List<ProductModel>>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductListNotifier(repository);
});

class ProductListNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ProductRepository _repository;

  ProductListNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    state = const AsyncValue.loading();
    final result = await _repository.getProducts();

    if (result is Success<List<ProductModel>>) {
      state = AsyncValue.data(result.data);
    } else if (result is Error<List<ProductModel>>) {
      state = AsyncValue.error(
        result.failure.message,
        StackTrace.current,
      );
    }
  }

  Future<void> refresh() async {
    final result = await _repository.getProducts();

    if (result is Success<List<ProductModel>>) {
      state = AsyncValue.data(result.data);
    } else if (result is Error<List<ProductModel>>) {
      state = AsyncValue.error(
        result.failure.message,
        StackTrace.current,
      );
    }
  }
}

// ─── Category Providers ────────────────────────────────────────────────────────

/// Provider for fetching categories list
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getCategories();
  if (result is Success<List<String>>) {
    return result.data;
  } else if (result is Error<List<String>>) {
    throw Exception(result.failure.message);
  }
  return [];
});

/// Holds currently selected category. Null represents "All" (no filter).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Provides filtered products based on currently selected category.
final filteredProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productListProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return productsAsync.whenData((products) {
    if (selectedCategory == null || selectedCategory.isEmpty) {
      return products;
    }
    return products
        .where((p) => p.category.toLowerCase() == selectedCategory.toLowerCase())
        .toList();
  });
});
