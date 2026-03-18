import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/book_cover_widget.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/dynamic_sky_background.dart';
import '../../core/widgets/trope_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  bool _showWrappedBanner = false;
  int _wrappedYear = DateTime.now().year;

  final _moods = const [
    'Make me cry',
    'Dark & twisted',
    'Cozy',
    'Chaos',
    'Slow burn',
    'Magic',
    'Light & funny',
  ];

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkWrappedBanner();
  }

  Future<void> _checkWrappedBanner() async {
    final now = DateTime.now();
    final isWrappedSeason = now.month == 12 || now.month == 1;
    if (!isWrappedSeason) return;

    // Show the wrapped for the year that just ended (in January) or current year (in December).
    final year = now.month == 1 ? now.year - 1 : now.year;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('wrapped_${year}_seen') ?? false;
    if (!mounted) return;
    setState(() {
      _wrappedYear = year;
      _showWrappedBanner = !seen;
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greeting();
    const name = 'Reader'; // Could be wired to profile later
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DynamicSkyBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              if (_showWrappedBanner)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: GestureDetector(
                      onTap: () async {
                        await HapticFeedback.lightImpact();
                        if (!mounted) return;
                        context.push('/wrapped/$_wrappedYear');
                        setState(() => _showWrappedBanner = false);
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: AppColors.gradientOrange,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.orangePrimary.withOpacity(0.25),
                                    blurRadius: 22,
                                  )
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '✦',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your $_wrappedYear Wrapped is ready!',
                                    style: AppText.bodySemiBold(
                                      14,
                                      color: AppColors.orangePrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Tap to see your year in books',
                                    style: AppText.body(
                                      12,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .scale(begin: const Offset(0.98, 0.98)),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    '$greeting, $name ✦',
                    style: AppText.display(30, context: context),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.1, end: 0),
                ),
              ),
              // Currently reading
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const BookCoverWidget(
                          width: 70,
                          height: 105,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No current read',
                                style: AppText.bodySemiBold(16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Start something magical from your TBR.',
                                style: AppText.body(
                                  13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: 0.2,
                                  minHeight: 6,
                                  backgroundColor: isDark
                                      ? AppColors.darkSurface
                                      : AppColors.lightSurface,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.orangePrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 500.ms)
                      .slideY(begin: 0.1, end: 0),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              // TBR Spin
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedBuilder(
                    animation: _breathingController,
                    builder: (context, child) {
                      final opacity = 0.6 + 0.4 * _breathingController.value;
                      return Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orangeBright
                                  .withOpacity(opacity * 0.4),
                              blurRadius: 30,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: GradientButton(
                      label: 'Spin my TBR ✦',
                      icon: const Text('✦'),
                      width: double.infinity,
                      onPressed: () => context.go('/library'),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 160.ms, duration: 500.ms)
                      .slideY(begin: 0.1, end: 0),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
              // Mood strip
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What’s your vibe today?',
                        style: AppText.bodySemiBold(15),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _moods.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final label = _moods[index];
                            return TropeChip(
                              label: label,
                              onTap: () {
                                context.push(
                                  '/discover',
                                  extra: {'mood': label},
                                );
                              },
                            )
                                .animate()
                                .fadeIn(
                                  delay: (220 + index * 60).ms,
                                  duration: 300.ms,
                                )
                                .slideY(
                                  begin: 0.1,
                                  end: 0,
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
              // Recently added
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Recently Added',
                    style: AppText.display(20, context: context),
                  ).animate().fadeIn(delay: 260.ms, duration: 400.ms),
                ),
              ),
              SliverList.builder(
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      4,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const BookCoverWidget(
                            width: 52,
                            height: 78,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Untitled adventure',
                                  style: AppText.bodySemiBold(15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'TBR',
                                  style: AppText.label(11,
                                      color: AppColors.orangeAmber),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                              border: Border.all(
                                color: AppColors.orangePrimary.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              'Just added',
                              style: AppText.body(
                                11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: (320 + index * 60).ms,
                          duration: 400.ms,
                        )
                        .slideY(begin: 0.1, end: 0),
                  );
                },
                itemCount: 5,
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
