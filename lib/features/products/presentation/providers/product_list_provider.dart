import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductRepository(apiClient);
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
    await refresh();
  }

  Future<void> refresh() async {
    final result = await _repository.getProducts();
    state = result.when(
      success: (products) => AsyncValue.data(products),
      failure: (failure) => AsyncValue.error(failure.message, StackTrace.current),
    );
  }
}

// ─── Category & Search Providers ──────────────────────────────────────────────

/// Provider for fetching categories list
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getCategories();
  return result.when(
    success: (categories) => categories,
    failure: (failure) => throw Exception(failure.message),
  );
});

/// Holds currently selected category. Null represents "All" (no filter).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Holds current product search query string.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provides home products filtered by category only (no search).
final homeProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productListProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return productsAsync.whenData((products) {
    return products.where((p) {
      return selectedCategory == null ||
          selectedCategory.isEmpty ||
          p.category.toLowerCase() == selectedCategory.toLowerCase();
    }).toList();
  });
});

/// Provides products filtered by search query only.
final searchProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productListProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

  return productsAsync.whenData((products) {
    if (searchQuery.isEmpty) {
      return const <ProductModel>[];
    }

    return products
        .where((p) => p.title.toLowerCase().contains(searchQuery))
        .toList();
  });
});

/// Provides filtered products based on currently selected category and search query.
final filteredProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productListProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

  return productsAsync.whenData((products) {
    return products.where((p) {
      final matchesCategory = selectedCategory == null ||
          selectedCategory.isEmpty ||
          p.category.toLowerCase() == selectedCategory.toLowerCase();

      final matchesSearch = searchQuery.isEmpty ||
          p.title.toLowerCase().contains(searchQuery);

      return matchesCategory && matchesSearch;
    }).toList();
  });
});
