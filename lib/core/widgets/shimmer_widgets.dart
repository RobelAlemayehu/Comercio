import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A shimmer-animated placeholder block for skeleton loading screens.
///
/// Usage:
/// ```dart
/// ShimmerBox(width: double.infinity, height: 20)
/// ShimmerBox(width: 80, height: 80, borderRadius: BorderRadius.circular(40))
/// ```
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBaseLight;
    final highlight = isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlightLight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          color: Color.lerp(base, highlight, _animation.value),
        ),
      ),
    );
  }
}

/// A full skeleton layout for the product grid (loading state).
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.68,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) => const _ProductCardSkeleton(),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: ShimmerBox(width: double.infinity, height: double.infinity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 12),
                const SizedBox(height: 6),
                ShimmerBox(width: 100, height: 12),
                const SizedBox(height: 10),
                ShimmerBox(width: 64, height: 16, borderRadius: BorderRadius.circular(4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for the category chips row.
class CategoryChipsSkeleton extends StatelessWidget {
  const CategoryChipsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ShimmerBox(
          width: index == 0 ? 56 : 96,
          height: 36,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Skeleton for a user profile page.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Avatar circle
          Center(
            child: ShimmerBox(
              width: 100,
              height: 100,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Center(child: ShimmerBox(width: 160, height: 22)),
          const SizedBox(height: 8),
          // Username badge
          Center(child: ShimmerBox(width: 90, height: 16, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 32),
          // Info cards
          for (int i = 0; i < 3; i++) ...[
            _InfoCardSkeleton(),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 24),
          // Button
          ShimmerBox(width: double.infinity, height: 50, borderRadius: BorderRadius.circular(12)),
        ],
      ),
    );
  }
}

class _InfoCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          ShimmerBox(width: 40, height: 40, borderRadius: BorderRadius.circular(10)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 60, height: 11),
                const SizedBox(height: 6),
                ShimmerBox(width: 160, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a single cart item card.
class CartItemSkeleton extends StatelessWidget {
  const CartItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          ShimmerBox(width: 75, height: 75, borderRadius: BorderRadius.circular(12)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 13),
                const SizedBox(height: 6),
                ShimmerBox(width: 160, height: 13),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 60, height: 18, borderRadius: BorderRadius.circular(4)),
                    ShimmerBox(width: 88, height: 30, borderRadius: BorderRadius.circular(8)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
