import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/animated_widgets.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../providers/product_list_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/product_search_bar.dart';

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
