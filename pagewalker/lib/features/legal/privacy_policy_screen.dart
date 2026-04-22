import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/themed_background.dart';
import '../../core/widgets/glass_card.dart';
import 'legal_documents.dart';

List<String> _privacyParagraphs(String s) {
  return s
      .split('\n\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static final Uri _privacyUri = Uri.parse('https://pagewalker.org/privacy');

  Future<void> _openOnline(BuildContext context) async {
    final opened = await launchUrl(
      _privacyUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open privacy page online.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.orangePrimary,
                  ),
                  Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: AppText.display(22, context: context),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_rounded),
                    color: AppColors.orangePrimary,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: LegalDocuments.privacyFullText),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      }
                    },
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _openOnline(context),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('View online'),
                ),
              ),
              Text(
                'Last updated: ${LegalDocuments.lastUpdated}',
                style: AppText.bodySemiBold(14, context: context).copyWith(
                  color: AppColors.orangePrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Effective date: ${LegalDocuments.lastUpdated}',
                style: AppText.body(12, color: secondary, context: context),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: AppText.bodySemiBold(15, context: context)
                          .copyWith(color: AppColors.orangePrimary),
                    ),
                    const Divider(height: 24),
                    ..._privacyParagraphs(LegalDocuments.privacyFullText).map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          p,
                          style: AppText.body(
                            14,
                            color: secondary,
                            context: context,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '© ${Env.copyrightYear} Pagewalker. All rights reserved.',
                        style: AppText.body(
                          12,
                          color: AppColors.darkTextMuted,
                          context: context,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
