import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/glass_card.dart';
import '../bingo_challenges.dart';

class BingoCardWidget extends StatelessWidget {
  const BingoCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 25,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final completed = index % 3 == 0;
          final label = index < kReadingBingoChallenges.length
              ? kReadingBingoChallenges[index]
              : '—';
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: completed
                  ? const LinearGradient(
                      colors: AppColors.gradientOrange,
                    )
                  : null,
              border: Border.all(
                color: completed
                    ? Colors.transparent
                    : AppColors.orangePrimary.withOpacity(0.4),
              ),
              color: completed ? null : AppColors.darkCard,
            ),
            padding: const EdgeInsets.all(4),
            child: Center(
              child: completed
                  ? Text(
                      '✓',
                      style: AppText.body(12, color: Colors.white),
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        8,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

