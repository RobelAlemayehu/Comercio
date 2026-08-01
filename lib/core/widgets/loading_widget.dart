import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool isLinear;

  const LoadingWidget({
    super.key,
    this.message,
    this.isLinear = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLinear)
              const SizedBox(
                width: 180,
                child: LinearProgressIndicator(),
              )
            else
              const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
