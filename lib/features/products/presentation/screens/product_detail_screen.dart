import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/models/product_model.dart';
import '../providers/product_detail_provider.dart';

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

    // Start content fade-in after hero lands
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

  // ─── Skeleton loading ────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return Column(
      children: [
        // Image skeleton
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

  // ─── Error state ──────────────────────────────────────────────────────────────

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

  // ─── Main content ─────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, ThemeData theme, bool isDark,
      ProductModel product) {
    final screenHeight = MediaQuery.of(context).size.height;

    return CustomScrollView(
      slivers: [
        // ── Collapsing app bar with Hero image ─────────────────────────────
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
                      onTap: () => context.push(AppRoutes.cart),
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

        // ── Details panel ──────────────────────────────────────────────────
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
                    // ── Category badge ──────────────────────────────────────
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

                    // ── Title ───────────────────────────────────────────────
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

                    // ── Price + Rating row ──────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
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
                        // Rating pill
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

                    // ── Description header ──────────────────────────────────
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

                    // ── Quantity selector + Add to cart ─────────────────────
                    Row(
                      children: [
                        // Quantity selector
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

                        // Add to cart button
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

// ─── Small helpers ────────────────────────────────────────────────────────────

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


