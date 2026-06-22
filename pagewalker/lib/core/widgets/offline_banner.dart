import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../plus/plus_paywall_sheet.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityStatusProvider).value ?? true;
    if (online) return const SizedBox.shrink();

    final top = MediaQuery.paddingOf(context).top;

    return Material(
      elevation: 4,
      color: const Color(0xFF3A1A00),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, top + 8, 14, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.orangeAmber,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You’re offline',
                    style: AppText.body(13, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Search, discover, mood picks, clubs, and sync need internet. '
                    'Your saved library may still open.',
                    style: AppText.body(11, color: Colors.white70),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => showPlusPaywall(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.orangeAmber,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Plus'),
            ),
          ],
        ),
      ),
    );
  }
}
