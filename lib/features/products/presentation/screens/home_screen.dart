import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/product_list_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProductState = ref.watch(filteredProductsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    if (width > 900) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    }

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
          // Horizontal Category Chips
          const CategorySelector(),
          const SizedBox(height: AppSpacing.xs),
          // Product Grid with smooth transition
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
                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(productListProvider.notifier).refresh();
                      ref.invalidate(categoriesProvider);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: Center(
                          child: EmptyStateWidget(
                            title: selectedCategory != null
                                ? 'No products in "${selectedCategory[0].toUpperCase()}${selectedCategory.substring(1)}"'
                                : 'No Products Available',
                            message: selectedCategory != null
                                ? 'Try selecting another category or clear the filter.'
                                : 'Check back later for new inventory.',
                            icon: Icons.inventory_2_outlined,
                            action: selectedCategory != null
                                ? OutlinedButton.icon(
                                    onPressed: () {
                                      ref.read(selectedCategoryProvider.notifier).state = null;
                                    },
                                    icon: const Icon(Icons.close_rounded, size: 16),
                                    label: const Text('Clear Filter'),
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
                      key: ValueKey(selectedCategory ?? 'all_products'),
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
