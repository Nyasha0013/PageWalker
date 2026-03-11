import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/sparkle_background.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.gradientHero,
          ),
        ),
        child: SparkleBackground(
          child: SafeArea(
            child: Center(
              child: Text(
                'Review details coming soon',
                style: AppText.body(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

