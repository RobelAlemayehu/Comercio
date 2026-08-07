import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/animated_widgets.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  final int userId;

  const ProfileScreen({
    super.key,
    this.userId = 1,
  });

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Choose Appearance',
              style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            RadioGroup<ThemeMode>(
              groupValue: currentMode,
              onChanged: (mode) async {
                if (mode == null) return;
                await ref.read(themeModeProvider.notifier).setThemeMode(mode);
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                }
              },
              child: Column(
                children: ThemeMode.values.map((mode) {
                  return RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(themeModeLabel(mode)),
                    secondary: Icon(
                      mode == ThemeMode.light
                          ? Icons.light_mode_outlined
                          : mode == ThemeMode.dark
                              ? Icons.dark_mode_outlined
                              : Icons.brightness_auto_outlined,
                      color: AppColors.primary,
                    ),
                    activeColor: AppColors.secondary,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic user) {
    AppSnackbar.info(context, 'Edit Profile requested for ${user.name.fullName}');
  }

  void _showAddressesDialog(BuildContext context, dynamic user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: const [
                Icon(Icons.location_on_outlined, color: AppColors.primary),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'Saved Delivery Address',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.address.formattedAddress,
                    style: const TextStyle(color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${user.phone}',
                    style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeIcon = switch (themeMode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(themeIcon, color: Colors.white),
            tooltip: 'Change theme',
            onPressed: () => _showThemePicker(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const SingleChildScrollView(child: ProfileSkeleton()),
        error: (error, stackTrace) {
          final isNetworkError = error.toString().toLowerCase().contains('socket') ||
              error.toString().toLowerCase().contains('network') ||
              error.toString().toLowerCase().contains('connection');
          return ErrorStateWidget(
            message: error.toString(),
            type: isNetworkError ? ErrorStateType.network : ErrorStateType.generic,
            onRetry: () => ref.invalidate(userProfileProvider(userId)),
          );
        },
        data: (user) => FadeSlideIn(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // ─── Profile Header Card ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md + 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: AppRadius.borderXl,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar placeholder
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.person_rounded,
                          size: 42,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // User Info & Edit Profile Button
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name.fullName.isNotEmpty
                                  ? user.name.fullName
                                  : 'John Doe',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email.isNotEmpty
                                  ? user.email
                                  : 'john.doe@email.com',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                onPressed: () => _showEditProfileDialog(context, user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.borderMd,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('Edit Profile'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Menu Options Card List ────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: AppRadius.borderXl,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.inventory_2_outlined,
                        title: 'My Orders',
                        isDark: isDark,
                        onTap: () {
                          AppSnackbar.info(context, 'My Orders screen');
                        },
                      ),
                      _buildDivider(isDark),
                      _ProfileMenuItem(
                        icon: Icons.shopping_cart_outlined,
                        title: 'My Cart',
                        isDark: isDark,
                        onTap: () => context.go(AppRoutes.cart),
                      ),
                      _buildDivider(isDark),
                      _ProfileMenuItem(
                        icon: Icons.favorite_border_rounded,
                        title: 'Wishlist',
                        isDark: isDark,
                        onTap: () {
                          AppSnackbar.info(context, 'Wishlist screen');
                        },
                      ),
                      _buildDivider(isDark),
                      _ProfileMenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'Addresses',
                        isDark: isDark,
                        onTap: () => _showAddressesDialog(context, user),
                      ),
                      _buildDivider(isDark),
                      _ProfileMenuItem(
                        icon: Icons.payment_outlined,
                        title: 'Payment Methods',
                        isDark: isDark,
                        onTap: () {
                          AppSnackbar.info(context, 'Payment Methods screen');
                        },
                      ),
                      _buildDivider(isDark),
                      _ProfileMenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        isDark: isDark,
                        isDestructive: true,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Confirm Logout'),
                              content: const Text(
                                  'Are you sure you want to log out of your account?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error),
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    ref
                                        .read(authNotifierProvider.notifier)
                                        .logout();
                                  },
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.isDark,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.textPrimaryDark : const Color(0xFF1C1C1C));

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderLg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md - 2,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: isDestructive
                  ? AppColors.error
                  : (isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
