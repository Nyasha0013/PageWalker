import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/shimmer_loader.dart';

/// Magical loading state for the Gutenberg reader (animated book + shimmer).
class WalkingBookLoader extends StatelessWidget {
  final String? title;

  const WalkingBookLoader({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 72,
              color: AppColors.logoMarkColor(context).withValues(alpha: 0.95),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(
                  begin: -10,
                  end: 10,
                  duration: 1400.ms,
                  curve: Curves.easeInOut,
                )
                .shake(
                  hz: 2,
                  duration: 1400.ms,
                ),
            const SizedBox(height: 20),
            Text(
              title != null && title!.isNotEmpty
                  ? 'Opening $title...'
                  : 'Opening your story...',
              style: AppText.displayItalic(18, context: context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Loading your story ✦',
              style: AppText.body(
                13,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 20),
            const ShimmerLoader(width: 180, height: 6),
          ],
        ),
      ),
    );
  }
}
