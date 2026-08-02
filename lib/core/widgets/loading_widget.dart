import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A polished, animated page-level loading widget.
///
/// Shows a branded circular progress indicator with optional subtitle message.
class LoadingWidget extends StatefulWidget {
  final String? message;
  final bool isLinear;

  const LoadingWidget({
    super.key,
    this.message,
    this.isLinear = false,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLinear)
                SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    backgroundColor: (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              else
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    backgroundColor: (isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.secondary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              if (widget.message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
