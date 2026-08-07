import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/animated_widgets.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/product_list_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/product_card.dart';

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

          // Hero Promotional Banner Card (Matching Design Spec)
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

                    // Headphones Illustration / Image Container
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

          // Category chips — skeleton while products are loading
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
