import 'dart:math';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/services/reading_personality_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/book_cover_widget.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/themed_background.dart';
import '../../data/repositories/user_book_repository.dart';
import 'bingo_challenges.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _avatarGlowController;
  final GlobalKey _wrapKey = GlobalKey();
  int _periodIndex = 0;

  final _periods = const [
    'Monthly',
    'Quarterly',
    'Biannual',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();
    _avatarGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _avatarGlowController.dispose();
    super.dispose();
  }

  Future<void> _shareWrap() async {
    final renderObject = _wrapKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;
    final image = await renderObject.toImage(
      pixelRatio: 3,
    );
    final byteData = await image.toByteData(
      format: ImageByteFormat.png,
    );
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        name: 'pagewalker-wrap.png',
        mimeType: 'image/png',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _Header(controller: _avatarGlowController)
                  .animate()
                  .fadeIn(duration: 500.ms),
              const SizedBox(height: 16),
              _StatsRow().animate().fadeIn(
                    delay: 80.ms,
                  ),
              const SizedBox(height: 16),
              const _AchievementsPreview().animate().fadeIn(delay: 110.ms),
              const SizedBox(height: 16),
              _ReadingWrapSection(
                periods: _periods,
                periodIndex: _periodIndex,
                onPeriodChanged: (i) {
                  setState(() => _periodIndex = i);
                },
                repaintKey: _wrapKey,
                onShare: _shareWrap,
              ).animate().fadeIn(delay: 140.ms),
              const SizedBox(height: 16),
              _TierListSection().animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              _TropeDnaSection().animate().fadeIn(delay: 260.ms),
              const SizedBox(height: 16),
              _BingoSection().animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AnimationController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton(
                onPressed: () => context.push('/profile/settings'),
                icon: const Icon(Icons.settings_rounded),
                color: AppColors.orangePrimary,
              ),
            ],
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final value = controller.value;
              final glow = 0.6 + 0.4 * value;
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.logoMarkColor(context)
                          .withOpacity(glow * 0.6),
                      blurRadius: 30,
                    ),
                  ],
                  gradient: RadialGradient(
                    colors: AppColors.logoMarkRingGradient(context),
                  ),
                ),
                child: child,
              );
            },
            child: const _AvatarSection(),
          ),
          const SizedBox(height: 10),
          Consumer(
            builder: (context, ref, _) {
              final profile = ref.watch(profileProvider).valueOrNull;
              return Column(
                children: [
                  Text(
                    profile?.displayName.isNotEmpty == true
                        ? profile!.displayName
                        : 'Pagewalker Muse',
                    style: AppText.display(22, context: context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (profile?.username.isNotEmpty == true)
                        ? '@${profile!.username}'
                        : '@bookishdreamer',
                    style: AppText.body(
                      13,
                      context: context,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile?.bio?.isNotEmpty == true
                        ? profile!.bio!
                        : 'Collecting fictional heartbreaks and happily-ever-afters.',
                    style: AppText.body(13, context: context),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _AchievementsPreview extends ConsumerWidget {
  const _AchievementsPreview();

  Future<(int unlockedCount, List<Map<String, dynamic>> unlocked)> _load(
    String userId,
  ) async {
    final unlocked = await SupabaseConfig.client
        .from('user_achievements')
        .select('achievement_id, unlocked_at, achievements(icon, name)')
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);

    final list = (unlocked as List).cast<Map<String, dynamic>>();
    return (list.length, list);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder(
        future: _load(user.id),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final unlockedCount = data?.$1 ?? 0;
          final unlocked = data?.$2 ?? const <Map<String, dynamic>>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Achievements',
                      style: AppText.bodySemiBold(
                        15,
                        context: context,
                        color: AppColors.orangePrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/achievements'),
                    child: Text(
                      'See all →',
                      style: AppText.bodySemiBold(
                        12,
                        context: context,
                        color: AppColors.orangePrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$unlockedCount unlocked',
                style: AppText.body(
                  12,
                  context: context,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(
                  color: AppColors.orangePrimary,
                )
              else if (unlocked.isEmpty)
                Text(
                  'Your first badge is one good moment away.',
                  style: AppText.body(13, context: context),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: unlocked.take(6).map((row) {
                      final a = row['achievements'] as Map<String, dynamic>?;
                      final icon = (a?['icon'] as String?) ?? '🏅';
                      final name = (a?['name'] as String?) ?? 'Achievement';
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.darkCard,
                            border: Border.all(
                              color: AppColors.orangePrimary.withOpacity(0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.orangePrimary.withOpacity(0.12),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Tooltip(
                            message: name,
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AvatarSection extends ConsumerStatefulWidget {
  const _AvatarSection();

  @override
  ConsumerState<_AvatarSection> createState() => _AvatarSectionState();
}

class _AvatarSectionState extends ConsumerState<_AvatarSection> {
  bool _uploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await image.readAsBytes();
      final userId = SupabaseConfig.client.auth.currentUser!.id;
      final fileName = 'avatar_$userId.jpg';

      await SupabaseConfig.client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final url =
          SupabaseConfig.client.storage.from('avatars').getPublicUrl(fileName);

      await SupabaseConfig.client
          .from('profiles')
          .update({'avatar_url': url}).eq('id', userId);
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _pickAndUploadPhoto,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Avatar circle with orange glow border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.logoMarkRingGradient(context),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.logoMarkColor(context).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor:
                  isDark ? AppColors.darkCard : AppColors.lightCard,
              backgroundImage: profile?.avatarUrl != null
                  ? NetworkImage(profile!.avatarUrl!)
                  : null,
              child: _uploading
                  ? CircularProgressIndicator(
                      color: AppColors.logoMarkColor(context))
                  : profile?.avatarUrl == null
                      ? Text(
                          _getInitials(profile?.displayName ?? 'PW'),
                          style: AppText.display(24,
                              color: AppColors.logoMarkColor(context)),
                        )
                      : null,
            ),
          ),
          // Camera icon badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.logoMarkRingGradient(context),
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = [
      ('Books Read', '128'),
      ('Avg Rating', '4.3'),
      ('Streak', '27'),
      ('Pages Read', '42k'),
    ];

    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                child: Column(
                  children: [
                    Text(
                      s.$2,
                      style: AppText.display(18, context: context),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .tint(color: AppColors.orangeAmber),
                    const SizedBox(height: 2),
                    Text(
                      s.$1,
                      style: AppText.body(
                        11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReadingWrapSection extends StatelessWidget {
  final List<String> periods;
  final int periodIndex;
  final ValueChanged<int> onPeriodChanged;
  final GlobalKey repaintKey;
  final VoidCallback onShare;

  const _ReadingWrapSection({
    required this.periods,
    required this.periodIndex,
    required this.onPeriodChanged,
    required this.repaintKey,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Wraps',
          style: AppText.display(18, context: context),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(periods.length, (index) {
            final selected = periodIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => onPeriodChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: selected
                        ? const LinearGradient(
                            colors: AppColors.gradientOrange,
                          )
                        : null,
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppColors.orangePrimary.withOpacity(0.4),
                    ),
                    color: selected ? null : AppColors.darkCard,
                  ),
                  child: Center(
                    child: Text(
                      periods[index],
                      style: AppText.body(
                        12,
                        color: selected
                            ? Colors.white
                            : AppColors.darkTextSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        RepaintBoundary(
          key: repaintKey,
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    BookCoverWidget(
                      width: 50,
                      height: 75,
                    ),
                    SizedBox(width: 6),
                    BookCoverWidget(
                      width: 50,
                      height: 75,
                    ),
                    SizedBox(width: 6),
                    BookCoverWidget(
                      width: 50,
                      height: 75,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'This period in stories',
                  style: AppText.bodySemiBold(14, context: context),
                ),
                const SizedBox(height: 4),
                Text(
                  '9 books · 3,214 pages · 4.5 avg rating',
                  style: AppText.body(
                    12,
                    context: context,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GradientButton(
          label: 'Share my Wrap',
          width: double.infinity,
          onPressed: onShare,
        ),
      ],
    );
  }
}

class _TierListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiers = [
      ('God Tier', AppColors.tierGod),
      ('A Class', AppColors.tierA),
      ('✦ B Class', AppColors.tierB),
      ('C Class', AppColors.tierC),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tier List',
          style: AppText.display(18, context: context),
        ),
        const SizedBox(height: 8),
        ...tiers.map(
          (t) => ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              t.$1,
              style: AppText.bodySemiBold(14, context: context),
            ),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.drag_handle_rounded,
                            color: AppColors.darkTextMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Beloved book ${index + 1}',
                            style: AppText.body(13, context: context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TropeDnaSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TropeDnaSection> createState() => _TropeDnaSectionState();
}

class _TropeDnaSectionState extends ConsumerState<_TropeDnaSection> {
  final _bookRepo = UserBookRepository();
  String? _personalityText;
  bool _loading = true;

  static const _tropes = ['Romance', 'Angst', 'Magic', 'Joy'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _personalityText = 'Sign in to see your reading personality.';
        });
      }
      return;
    }
    final stats = await _bookRepo.getReadStats(uid);
    final text = await ReadingPersonalityService.instance.getDescription(
      userId: uid,
      topTropes: _tropes,
      booksRead: stats.readCount,
      avgRating: stats.avgRating <= 0 ? 4.0 : stats.avgRating,
    );
    if (mounted) {
      setState(() {
        _personalityText = text;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      PieChartSectionData(
        color: AppColors.orangePrimary,
        value: 35,
        title: '',
      ),
      PieChartSectionData(
        color: AppColors.orangeBright,
        value: 25,
        title: '',
      ),
      PieChartSectionData(
        color: AppColors.orangeDeep,
        value: 20,
        title: '',
      ),
      PieChartSectionData(
        color: AppColors.orangeAmber,
        value: 20,
        title: '',
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your reading personality',
            style: AppText.display(18, context: context),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _LegendDot(
                color: AppColors.orangePrimary,
                label: 'Romance',
              ),
              _LegendDot(
                color: AppColors.orangeBright,
                label: 'Angst',
              ),
              _LegendDot(
                color: AppColors.orangeDeep,
                label: 'Magic',
              ),
              _LegendDot(
                color: AppColors.orangeAmber,
                label: 'Joy',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const LinearProgressIndicator(
              color: AppColors.orangePrimary,
            )
          else
            Text(
              _personalityText ?? '',
              style: AppText.body(13, context: context),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppText.body(
            11,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _BingoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Bingo',
            style: AppText.display(18, context: context),
          ),
          const SizedBox(height: 6),
          Text(
            'A 5×5 grid of mini reading challenges (e.g. “a book set by the sea”). '
            'Squares light up as you complete prompts — full stats and prompts will tie into your library later.',
            style: AppText.body(
              12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              context: context,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 25,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final completed = index % 3 == 0;
              final label = index < kReadingBingoChallenges.length
                  ? kReadingBingoChallenges[index]
                  : '—';
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: completed
                      ? const LinearGradient(
                          colors: AppColors.gradientEmber,
                        )
                      : null,
                  border: Border.all(
                    color: completed
                        ? Colors.transparent
                        : AppColors.orangePrimary.withOpacity(0.4),
                  ),
                  color: completed
                      ? null
                      : (isDark ? AppColors.darkCard : AppColors.lightCard),
                ),
                padding: const EdgeInsets.all(4),
                child: Center(
                  child: completed
                      ? Text(
                          '✓',
                          style: AppText.body(12, color: Colors.white),
                        )
                      : Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            8,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
