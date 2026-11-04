import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 160, radius: AppRadii.lg),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(height: 84, radius: AppRadii.lg),
          SizedBox(height: AppSpacing.lg),
          SkeletonBox(height: 72, radius: AppRadii.md),
          SizedBox(height: AppSpacing.lg),
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
        ],
      ),
    );
  }
}
