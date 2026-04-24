import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/book_cover_widget.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/themed_background.dart';
import '../../core/widgets/trope_chip.dart';
import '../../data/models/book.dart';
import '../../data/repositories/user_book_repository.dart';
import '../profile/profile_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _breathingController;
  final _userBookRepo = UserBookRepository();
  List<Book> _recentBooks = [];
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
    WidgetsBinding.instance.addObserver(this);
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecent());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _loadRecent();
    }
  }

  Future<void> _loadRecent() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    final books = await _userBookRepo.getRecentBooks(user.id, limit: 5);
    if (mounted) setState(() => _recentBooks = books);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breathingController.dispose();
    super.dispose();
  }

  /// Device local clock (PDF bands).
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 18) return 'Good afternoon';
    if (hour >= 18 && hour < 23) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final profile = ref.watch(profileProvider).valueOrNull;
    final name = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'Reader';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    '$greeting, $name ✦',
                    key: ValueKey(greeting + name),
                    style: AppText.display(30, context: context),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.1, end: 0),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        BookCoverWidget(
                          width: 70,
                          height: 105,
                          title: 'Discover',
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Discover books',
                                style: AppText.bodySemiBold(16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Search, discuss, and track — reading happens elsewhere.',
                                style: AppText.body(
                                  13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GradientButton(
                                label: 'Open search',
                                width: double.infinity,
                                onPressed: () => context.push('/search'),
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
              if (_recentBooks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_library_outlined,
                            size: 40,
                            color: AppColors.logoMarkColor(context)
                                .withValues(alpha: 0.85),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your library is empty',
                            style: AppText.bodySemiBold(16, context: context),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search for books and add them to your TBR to get started!',
                            textAlign: TextAlign.center,
                            style: AppText.body(
                              13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GradientButton(
                            label: 'Search books',
                            width: double.infinity,
                            onPressed: () => context.push('/search'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemBuilder: (context, index) {
                    final b = _recentBooks[index];
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
                            BookCoverWidget(
                              width: 52,
                              height: 78,
                              title: b.title,
                              coverUrl: b.coverUrl,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.title,
                                    style: AppText.bodySemiBold(15),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    b.author,
                                    style: AppText.label(
                                      11,
                                      color: AppColors.orangeAmber,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                  color: AppColors.logoMarkColor(context)
                                      .withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                'Recent',
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
                  itemCount: _recentBooks.length,
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
