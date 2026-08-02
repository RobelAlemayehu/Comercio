import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/product_list_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/product_card.dart';
import '../widgets/product_search_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProductState = ref.watch(filteredProductsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    if (width > 900) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    }

    final isSearching = searchQuery.trim().isNotEmpty;
    final isFilteringCategory = selectedCategory != null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            const Text('Comercio'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.xs),
          // Search Bar
          const ProductSearchBar(),
          const SizedBox(height: AppSpacing.xs),
          // Horizontal Category Chips
          const CategorySelector(),
          const SizedBox(height: AppSpacing.xs),
          // Product Grid with smooth transition & empty state handling
          Expanded(
            child: filteredProductState.when(
              loading: () => const LoadingWidget(
                message: 'Loading products...',
              ),
              error: (error, stackTrace) => ErrorStateWidget(
                message: error.toString(),
                onRetry: () {
                  ref.read(productListProvider.notifier).fetchProducts();
                  ref.invalidate(categoriesProvider);
                },
              ),
              data: (products) {
                if (products.isEmpty) {
                  String emptyTitle = 'No Products Available';
                  String emptyMessage = 'Check back later for new inventory.';

                  if (isSearching && isFilteringCategory) {
                    emptyTitle = 'No results for "$searchQuery"';
                    emptyMessage =
                        'No matching products found in "${selectedCategory[0].toUpperCase()}${selectedCategory.substring(1)}".';
                  } else if (isSearching) {
                    emptyTitle = 'No results for "$searchQuery"';
                    emptyMessage = 'Check your spelling or try another search term.';
                  } else if (isFilteringCategory) {
                    emptyTitle =
                        'No products in "${selectedCategory[0].toUpperCase()}${selectedCategory.substring(1)}"';
                    emptyMessage = 'Try selecting another category or clear the filter.';
                  }

                  return RefreshIndicator(
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
                            icon: isSearching ? Icons.search_off_rounded : Icons.inventory_2_outlined,
                            action: (isSearching || isFilteringCategory)
                                ? OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.secondary,
                                      side: const BorderSide(color: AppColors.secondary),
                                    ),
                                    onPressed: () {
                                      ref.read(searchQueryProvider.notifier).state = '';
                                      ref.read(selectedCategoryProvider.notifier).state = null;
                                    },
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: Text(
                                      isSearching && isFilteringCategory
                                          ? 'Clear All Filters'
                                          : isSearching
                                              ? 'Clear Search'
                                              : 'Clear Category Filter',
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(productListProvider.notifier).refresh();
                    ref.invalidate(categoriesProvider);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: GridView.builder(
                      key: ValueKey(
                        '${selectedCategory ?? "all"}_${searchQuery.trim()}',
                      ),
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
                        return ProductCard(
                          product: product,
                          onTap: () {
                            context.push(AppRoutes.productDetail(product.id));
                          },
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
