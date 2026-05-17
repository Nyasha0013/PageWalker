import 'package:flutter/material.dart';

import '../../core/theme/app_text.dart';
import '../../core/widgets/themed_background.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: Center(
            child: Text(
              'Review details coming soon',
              style: AppText.body(14, context: context),
            ),
          ),
        ),
      ),
    );
  }
}

