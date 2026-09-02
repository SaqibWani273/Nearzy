import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../common/animations/entrance.dart';

class EmptyCartScreen extends StatelessWidget {
  const EmptyCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line, width: 1.5),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 34,
                color: AppColors.sage,
              ),
            ).animateEntrance(),
            const SizedBox(height: 20),
            Text('Your bag is empty', style: AppTextStyles.heading2)
                .animateEntrance(index: 1),
            const SizedBox(height: 8),
            Text(
              'Browse shops near you and add something worth the walk.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ).animateEntrance(index: 2),
          ],
        ),
      ),
    );
  }
}
