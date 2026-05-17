import 'package:flutter/material.dart';

import '../theme/pagewalker_theme_extension.dart';

class ThemedBackground extends StatelessWidget {
  final Widget child;

  const ThemedBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<PagewalkerThemeExtension>();
    final colors = ext?.scaffoldGradient ??
        [
          Theme.of(context).scaffoldBackgroundColor,
          Theme.of(context).scaffoldBackgroundColor,
        ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
