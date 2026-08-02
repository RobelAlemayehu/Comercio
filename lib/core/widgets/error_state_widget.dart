import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// A polished, reusable error state widget with optional retry.
///
/// Differentiates between network and generic errors via [type].
enum ErrorStateType { generic, network, notFound, timeout }

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final ErrorStateType type;
  final String? retryLabel;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.type = ErrorStateType.generic,
    this.retryLabel,
  });

  /// Convenience constructor for network-specific errors.
  const ErrorStateWidget.network({
    super.key,
    String? message,
    this.onRetry,
    this.retryLabel,
  })  : message = message ?? 'No internet connection. Check your network and try again.',
        type = ErrorStateType.network;

  /// Convenience constructor for timeout errors.
  const ErrorStateWidget.timeout({
    super.key,
    String? message,
    this.onRetry,
    this.retryLabel,
  })  : message = message ?? 'The request took too long. Please try again.',
        type = ErrorStateType.timeout;

  IconData get _icon {
    switch (type) {
      case ErrorStateType.network:
        return Icons.wifi_off_rounded;
      case ErrorStateType.notFound:
        return Icons.search_off_rounded;
      case ErrorStateType.timeout:
        return Icons.timer_off_rounded;
      case ErrorStateType.generic:
        return Icons.error_outline_rounded;
    }
  }

  String get _title {
    switch (type) {
      case ErrorStateType.network:
        return 'No Connection';
      case ErrorStateType.notFound:
        return 'Not Found';
      case ErrorStateType.timeout:
        return 'Request Timed Out';
      case ErrorStateType.generic:
        return 'Something Went Wrong';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container with subtle error tint
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: type == ErrorStateType.network
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon,
                size: 52,
                color: type == ErrorStateType.network
                    ? AppColors.warning
                    : AppColors.error,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 28),
              AppButton(
                text: retryLabel ?? 'Try Again',
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                width: 180,
                variant: AppButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact inline error banner — useful for snackbars or embedded errors.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}
