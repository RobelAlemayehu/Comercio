import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../providers/product_list_provider.dart';

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
        // Header with title and clear filter option
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

        // Horizontal circular category list
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
