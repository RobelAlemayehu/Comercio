
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'base.dart';
import 'cart.dart';
import 'network.dart';
import 'theme.dart';
import 'widgets.dart';

class RatingModel {
  final double rate;
  final int count;

  const RatingModel({
    required this.rate,
    required this.count,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rate': rate,
      'count': count,
    };
  }
}

class ProductModel {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final RatingModel rating;

  const ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.rating,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      rating: json['rating'] != null && json['rating'] is Map<String, dynamic>
          ? RatingModel.fromJson(json['rating'] as Map<String, dynamic>)
          : const RatingModel(rate: 0.0, count: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'image': image,
      'rating': rating.toJson(),
    };
  }
}

class ProductRepository extends BaseRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  Future<Result<List<ProductModel>>> getProducts() async {
    return safeApiCall(() async {
      final response = await _apiClient.get(ApiEndpoints.products);
      if (response is List) {
        return response
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Invalid products list format received from server');
    });
  }

  Future<Result<ProductModel>> getProduct(int id) async {
    return safeApiCall(() async {
      final response = await _apiClient.get(ApiEndpoints.productDetails(id));
      if (response is Map<String, dynamic>) {
        return ProductModel.fromJson(response);
      }
      throw Exception('Invalid product format received from server');
    });
  }

  Future<Result<List<String>>> getCategories() async {
    return safeApiCall(() async {
      final response = await _apiClient.get(ApiEndpoints.categories);
      if (response is List) {
        return response.map((item) => item.toString()).toList();
      }
      throw Exception('Invalid categories list format received from server');
    });
  }
}

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

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getCategories();
  return result.when(
    success: (categories) => categories,
    failure: (failure) => throw Exception(failure.message),
  );
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

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

final productDetailProvider =
    FutureProvider.family<ProductModel?, int>((ref, id) async {
  final listAsync = ref.read(productListProvider);
  if (listAsync.hasValue) {
    final cached = listAsync.value?.cast<ProductModel?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
    if (cached != null) return cached;
  }

  final repository = ref.read(productRepositoryProvider);
  final result = await repository.getProduct(id);
  return result.when(
    success: (product) => product,
    failure: (failure) => throw Exception(failure.message),
  );
});

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                child: Hero(
                  tag: 'product-image-${product.id}',
                  child: CachedNetworkImage(
                    imageUrl: product.image,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const ShimmerBox(
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.borderXs,
                    ),
                    child: Text(
                      product.category.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.secondaryLight : AppColors.priceTag,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.ratingStar,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.rate.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '(${product.rating.count})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategorySelector extends ConsumerWidget {
  const CategorySelector({super.key});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices_rounded;
      case 'jewelery':
      case 'jewelry':
        return Icons.diamond_rounded;
      case "men's clothing":
      case 'men clothing':
        return Icons.checkroom_rounded;
      case "women's clothing":
      case 'women clothing':
        return Icons.woman_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  String _formatCategoryName(String category) {
    if (category.isEmpty) return '';
    return category
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: selectedCategory != null ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: selectedCategory == null,
                  child: InkWell(
                    borderRadius: AppRadius.borderSm,
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = null;
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Clear filter',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 86,
          child: categoriesAsync.when(
            loading: () => const CategoryChipsSkeleton(),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  const Text(
                    'Failed to load categories',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  TextButton(
                    onPressed: () => ref.invalidate(categoriesProvider),
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            data: (categories) {
              final allChips = ['All', ...categories];

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                scrollDirection: Axis.horizontal,
                itemCount: allChips.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final category = allChips[index];
                  final isAll = index == 0;
                  final isSelected = isAll
                      ? selectedCategory == null
                      : selectedCategory?.toLowerCase() ==
                          category.toLowerCase();

                  return _CategoryItem(
                    label: isAll ? 'All' : _formatCategoryName(category),
                    icon: isAll ? Icons.grid_view_rounded : _getCategoryIcon(category),
                    isSelected: isSelected,
                    onTap: () {
                      if (isAll || isSelected) {
                        ref.read(selectedCategoryProvider.notifier).state = null;
                      } else {
                        ref.read(selectedCategoryProvider.notifier).state = category;
                      }
                    },
                    isDark: isDark,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeCircleBg = AppColors.primary;
    final activeIconColor = Colors.white;
    final inactiveCircleBg = isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9);
    final inactiveIconColor = isDark ? AppColors.textSecondaryDark : const Color(0xFF475569);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? activeCircleBg : inactiveCircleBg,
              border: isSelected
                  ? Border.all(color: AppColors.secondary, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: isSelected ? activeIconColor : inactiveIconColor,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.secondary : AppColors.primary)
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductSearchBar extends ConsumerStatefulWidget {
  final bool autofocus;

  const ProductSearchBar({
    super.key,
    this.autofocus = false,
  });

  @override
  ConsumerState<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends ConsumerState<ProductSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = query;
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final query = ref.watch(searchQueryProvider);

    if (query.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        decoration: InputDecoration(
          hintText: 'Search products by title...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.secondary,
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                  ),
                  tooltip: 'Clear search',
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(
              color: AppColors.secondary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProductState = ref.watch(homeProductsProvider);
    final productListState = ref.watch(productListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    int crossAxisCount = 2;
    if (width > 900) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    }

    final isFilteringCategory = selectedCategory != null;
    final isLoadingProducts = productListState is AsyncLoading;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Comercio',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Consumer(
              builder: (context, ref, child) {
                final cartItemCount = ref.watch(cartTotalItemCountProvider);
                return Badge(
                  isLabelVisible: cartItemCount > 0,
                  label: Text(
                    '$cartItemCount',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.secondary,
                  textColor: AppColors.primaryDark,
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                );
              },
            ),
            tooltip: 'Shopping Cart',
            onPressed: () => context.go(AppRoutes.cart),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.borderXl,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'New Collection',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Discover\nThe Best\nProducts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 34,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(selectedCategoryProvider.notifier).state =
                                  'electronics';
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.primaryDark,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Shop Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.headphones_rounded,
                      size: 64,
                      color: AppColors.secondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedContent(
            child: isLoadingProducts
                ? const CategoryChipsSkeleton()
                : const CategorySelector(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: filteredProductState.when(
              loading: () => ProductGridSkeleton(crossAxisCount: crossAxisCount),
              error: (error, stackTrace) {
                final isNetworkError = error.toString().toLowerCase().contains('socket') ||
                    error.toString().toLowerCase().contains('network') ||
                    error.toString().toLowerCase().contains('connection');
                return ErrorStateWidget(
                  message: error.toString(),
                  type: isNetworkError ? ErrorStateType.network : ErrorStateType.generic,
                  onRetry: () {
                    ref.read(productListProvider.notifier).fetchProducts();
                    ref.invalidate(categoriesProvider);
                  },
                );
              },
              data: (products) {
                if (products.isEmpty) {
                  String emptyTitle = 'No Products Available';
                  String emptyMessage = 'Check back later for new inventory.';

                  if (isFilteringCategory) {
                    emptyTitle =
                        'No products in "${selectedCategory[0].toUpperCase()}${selectedCategory.substring(1)}"';
                    emptyMessage = 'Try selecting another category or clear the filter.';
                  }

                  return RefreshIndicator(
                    color: AppColors.secondary,
                    onRefresh: () async {
                      await ref.read(productListProvider.notifier).refresh();
                      ref.invalidate(categoriesProvider);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: EmptyStateWidget(
                            title: emptyTitle,
                            message: emptyMessage,
                            icon: Icons.inventory_2_outlined,
                            action: isFilteringCategory
                                ? AppButton(
                                    text: 'Clear Category Filter',
                                    icon: Icons.filter_alt_off_rounded,
                                    variant: AppButtonVariant.outline,
                                    width: 200,
                                    onPressed: () {
                                      ref.read(selectedCategoryProvider.notifier).state = null;
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.secondary,
                  onRefresh: () async {
                    await ref.read(productListProvider.notifier).refresh();
                    ref.invalidate(categoriesProvider);
                    if (context.mounted) {
                      AppSnackbar.success(context, 'Products refreshed!');
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: GridView.builder(
                      key: ValueKey(selectedCategory ?? 'all'),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: products.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return FadeSlideIn(
                          delay: Duration(milliseconds: (index * 40).clamp(0, 400)),
                          child: ProductCard(
                            product: product,
                            onTap: () {
                              context.push(AppRoutes.productDetail(product.id));
                            },
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  bool _addedToCart = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handleAddToCart(ProductModel product) {
    ref.read(cartNotifierProvider.notifier).addItem(product, quantity: _quantity);
    setState(() => _addedToCart = true);
    AppSnackbar.success(
      context,
      '${product.title.split(' ').take(3).join(' ')}… added to cart',
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _addedToCart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productAsync =
        ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: productAsync.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => _buildError(e.toString()),
        data: (product) {
          if (product == null) return _buildError('Product not found.');
          return _buildContent(context, theme, isDark, product);
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        const ShimmerBox(width: double.infinity, height: 360),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(width: 100, height: 24),
              const SizedBox(height: AppSpacing.sm),
              const ShimmerBox(width: double.infinity, height: 28),
              const SizedBox(height: AppSpacing.xs),
              const ShimmerBox(width: 200, height: 28),
              const SizedBox(height: AppSpacing.md),
              const ShimmerBox(width: 120, height: 20),
              const SizedBox(height: AppSpacing.lg),
              const ShimmerBox(width: double.infinity, height: 16),
              const SizedBox(height: AppSpacing.xs),
              const ShimmerBox(width: double.infinity, height: 16),
              const SizedBox(height: AppSpacing.xs),
              const ShimmerBox(width: 240, height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    final isNetworkError = message.toLowerCase().contains('socket') ||
        message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('connection');
    return ErrorStateWidget(
      message: message,
      type: isNetworkError ? ErrorStateType.network : ErrorStateType.generic,
      onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isDark,
      ProductModel product) {
    final screenHeight = MediaQuery.of(context).size.height;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: screenHeight * 0.42,
          pinned: true,
          backgroundColor:
              isDark ? AppColors.backgroundDark : Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _CircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => context.pop(),
              isDark: isDark,
            ),
          ),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final cartItemCount = ref.watch(cartTotalItemCountProvider);
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Badge(
                    isLabelVisible: cartItemCount > 0,
                    label: Text('$cartItemCount'),
                    backgroundColor: AppColors.secondary,
                    textColor: AppColors.primaryDark,
                    offset: const Offset(-2, 2),
                    child: _CircleButton(
                      icon: Icons.shopping_cart_outlined,
                      onTap: () => context.go(AppRoutes.cart),
                      isDark: isDark,
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _CircleButton(
                icon: Icons.share_rounded,
                onTap: () {},
                isDark: isDark,
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: Hero(
                tag: 'product-image-${product.id}',
                child: CachedNetworkImage(
                  imageUrl: product.image,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        product.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      product.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.secondaryLight
                                : AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs + 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: AppRadius.borderLg,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.ratingStar, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                product.rating.rate.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${product.rating.count})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.65,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove_rounded,
                                onTap: _quantity > 1
                                    ? () =>
                                        setState(() => _quantity--)
                                    : null,
                                isDark: isDark,
                              ),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '$_quantity',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              _QtyButton(
                                icon: Icons.add_rounded,
                                onTap: () => setState(() => _quantity++),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            text: _addedToCart ? 'Added ✓' : 'Add to Cart',
                            icon: _addedToCart
                                ? null
                                : Icons.shopping_cart_outlined,
                            variant: AppButtonVariant.primary,
                            onPressed: _addedToCart
                                ? null
                                : () => _handleAddToCart(product),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _QtyButton({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 44,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? (isDark ? AppColors.textSecondaryDark : AppColors.borderLight)
              : (isDark ? AppColors.textPrimaryDark : AppColors.primary),
        ),
      ),
    );
  }
}

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchProductsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    int crossAxisCount = 2;
    if (width > 900) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    }

    final hasQuery = searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Search',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          const ProductSearchBar(autofocus: true),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: searchResults.when(
              loading: () => ProductGridSkeleton(crossAxisCount: crossAxisCount),
              error: (error, _) {
                final isNetworkError = error.toString().toLowerCase().contains('socket') ||
                    error.toString().toLowerCase().contains('network') ||
                    error.toString().toLowerCase().contains('connection');
                return ErrorStateWidget(
                  message: error.toString(),
                  type: isNetworkError ? ErrorStateType.network : ErrorStateType.generic,
                  onRetry: () => ref.read(productListProvider.notifier).fetchProducts(),
                );
              },
              data: (products) {
                if (!hasQuery) {
                  return const Center(
                    child: EmptyStateWidget(
                      title: 'Search Products',
                      message: 'Type a product name to find what you\'re looking for.',
                      icon: Icons.search_rounded,
                    ),
                  );
                }

                if (products.isEmpty) {
                  return Center(
                    child: EmptyStateWidget(
                      title: 'No results for "$searchQuery"',
                      message: 'Check your spelling or try another search term.',
                      icon: Icons.search_off_rounded,
                      action: AppButton(
                        text: 'Clear Search',
                        icon: Icons.close_rounded,
                        variant: AppButtonVariant.outline,
                        width: 200,
                        onPressed: () {
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: (index * 40).clamp(0, 400)),
                      child: ProductCard(
                        product: product,
                        onTap: () {
                          context.push(AppRoutes.searchProductDetail(product.id));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
