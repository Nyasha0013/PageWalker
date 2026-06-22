import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'pagewalker_plus_features.dart';
import 'pagewalker_plus_service.dart';
import 'plus_paywall_sheet.dart';

class PlusGate extends ConsumerWidget {
  final PagewalkerPlusFeature feature;
  final Widget child;
  final double blurSigma;

  const PlusGate({
    super.key,
    required this.feature,
    required this.child,
    this.blurSigma = 6,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plusAsync = ref.watch(pagewalkerPlusProvider);
    final isPlus = plusAsync.value ?? false;
    if (isPlus) return child;

    final info = PagewalkerPlusCatalog.plusFeatures
        .firstWhere((f) => f.id == feature);

    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: AbsorbPointer(child: child),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.black.withOpacity(0.35),
            child: InkWell(
              onTap: () => showPlusPaywall(context, highlight: feature),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: AppColors.gradientOrange,
                          ),
                        ),
                        child: Icon(info.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pagewalker Plus',
                        style: AppText.display(18, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        info.title,
                        style: AppText.body(14, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () =>
                            showPlusPaywall(context, highlight: feature),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orangePrimary,
                        ),
                        child: const Text('Unlock Plus'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PlusBadge extends ConsumerWidget {
  const PlusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlus = ref.watch(pagewalkerPlusProvider).value ?? false;
    if (!isPlus) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientOrange),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Plus',
        style: AppText.body(10, color: Colors.white),
      ),
    );
  }
}
