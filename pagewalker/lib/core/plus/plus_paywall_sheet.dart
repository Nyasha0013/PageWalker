import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/gradient_button.dart';
import 'pagewalker_plus_features.dart';
import 'pagewalker_plus_service.dart';

Future<void> showPlusPaywall(
  BuildContext context, {
  PagewalkerPlusFeature? highlight,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PlusPaywallSheet(highlight: highlight),
  );
}

class PlusPaywallSheet extends ConsumerWidget {
  final PagewalkerPlusFeature? highlight;

  const PlusPaywallSheet({super.key, this.highlight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.orangePrimary.withOpacity(0.35)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.orangePrimary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pagewalker Plus',
                style: AppText.display(26, context: context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Unlock the fun stuff — AI mood picks, wraps, bingo, personality, and unlimited clubs.',
                style: AppText.body(
                  14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  context: context,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PriceCard(
                      label: 'Monthly',
                      price: PagewalkerPlusCatalog.monthlyPriceLabel,
                      selected: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PriceCard(
                      label: 'Yearly',
                      price: PagewalkerPlusCatalog.yearlyPriceLabel,
                      badge: 'Save 33%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Included in Plus',
                style: AppText.display(16, context: context),
              ),
              const SizedBox(height: 10),
              ...PagewalkerPlusCatalog.plusFeatures.map((feature) {
                final isHighlight = feature.id == highlight;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isHighlight
                            ? AppColors.orangePrimary
                            : AppColors.orangePrimary.withOpacity(0.2),
                      ),
                    ),
                    tileColor: isHighlight
                        ? AppColors.orangePrimary.withOpacity(0.08)
                        : null,
                    leading: Icon(feature.icon, color: AppColors.orangePrimary),
                    title: Text(
                      feature.title,
                      style: AppText.body(14, context: context),
                    ),
                    subtitle: Text(
                      feature.subtitle,
                      style: AppText.body(
                        12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        context: context,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text(
                'Always free',
                style: AppText.display(16, context: context),
              ),
              const SizedBox(height: 8),
              ...PagewalkerPlusCatalog.freeHighlights.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✓ ', style: TextStyle(color: Colors.green)),
                      Expanded(
                        child: Text(
                          line,
                          style: AppText.body(13, context: context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Subscribe with Google Play',
                width: double.infinity,
                onPressed: () => _onSubscribe(context),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    await PagewalkerPlusService.instance.setDebugPlus(true);
                    ref.invalidate(pagewalkerPlusProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Debug: unlock Plus on this device'),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Subscriptions are processed by Google Play. Cancel anytime in Play Store → Subscriptions.',
                style: AppText.body(
                  11,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  context: context,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onSubscribe(BuildContext context) async {
    final uri = Uri.parse('https://pagewalker.org/plus');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Play subscriptions go live with your first Play Store release. '
            'We will enable in-app purchase in the next build.',
          ),
        ),
      );
    }
  }
}

class _PriceCard extends StatelessWidget {
  final String label;
  final String price;
  final bool selected;
  final String? badge;

  const _PriceCard({
    required this.label,
    required this.price,
    this.selected = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppColors.orangePrimary
              : AppColors.orangePrimary.withOpacity(0.25),
          width: selected ? 2 : 1,
        ),
        gradient: selected
            ? LinearGradient(
                colors: [
                  AppColors.orangePrimary.withOpacity(0.15),
                  AppColors.orangeDeep.withOpacity(0.08),
                ],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppText.body(12, context: context)),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.orangePrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: AppText.body(9, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(price, style: AppText.display(15, context: context)),
        ],
      ),
    );
  }
}
