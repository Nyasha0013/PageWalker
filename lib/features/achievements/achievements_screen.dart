import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/dynamic_sky_background.dart';
import '../../core/widgets/glass_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _filter = 'all';
  bool _loading = true;
  List<Map<String, dynamic>> _definitions = [];
  Set<String> _unlocked = {};
  Map<String, DateTime> _unlockedAt = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final defs = await SupabaseConfig.client
          .from('achievements')
          .select()
          .order('category')
          .order('threshold');

      final user = SupabaseConfig.client.auth.currentUser;
      final unlockedRows = user == null
          ? <dynamic>[]
          : await SupabaseConfig.client
              .from('user_achievements')
              .select('achievement_id, unlocked_at')
              .eq('user_id', user.id);

      final unlockedIds = <String>{};
      final unlockedAt = <String, DateTime>{};
      for (final row in unlockedRows) {
        final id = row['achievement_id'] as String;
        unlockedIds.add(id);
        final parsed = DateTime.tryParse(row['unlocked_at'] as String? ?? '');
        if (parsed != null) unlockedAt[id] = parsed;
      }

      if (!mounted) return;
      setState(() {
        _definitions = (defs as List).cast<Map<String, dynamic>>();
        _unlocked = unlockedIds;
        _unlockedAt = unlockedAt;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _definitions;
    return _definitions
        .where((a) => (a['category'] as String?) == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _definitions.length;
    final unlockedCount = _unlocked.length;

    return Scaffold(
      body: DynamicSkyBackground(
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.orangePrimary,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.orangePrimary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: AppColors.orangePrimary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Your Achievements',
                              style: AppText.display(22, context: context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$unlockedCount / $total unlocked',
                              style: AppText.bodySemiBold(
                                14,
                                context: context,
                                color: AppColors.orangePrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : unlockedCount / total,
                                minHeight: 10,
                                backgroundColor: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.lightCard,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.orangePrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 350.ms),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _filter == 'all',
                              onTap: () => setState(() => _filter = 'all'),
                            ),
                            _FilterChip(
                              label: 'Reading',
                              selected: _filter == 'reading',
                              onTap: () => setState(() => _filter = 'reading'),
                            ),
                            _FilterChip(
                              label: 'Streak',
                              selected: _filter == 'streak',
                              onTap: () => setState(() => _filter = 'streak'),
                            ),
                            _FilterChip(
                              label: 'Social',
                              selected: _filter == 'social',
                              onTap: () => setState(() => _filter = 'social'),
                            ),
                            _FilterChip(
                              label: 'Special',
                              selected: _filter == 'special',
                              onTap: () => setState(() => _filter = 'special'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemBuilder: (context, index) {
                          final a = _filtered[index];
                          final id = a['id'] as String;
                          final isUnlocked = _unlocked.contains(id);
                          final icon = (a['icon'] as String?) ?? '🏅';
                          final name = (a['name'] as String?) ?? 'Achievement';
                          final desc =
                              (a['description'] as String?) ?? '';

                          return _AchievementCard(
                            icon: icon,
                            name: name,
                            description: isUnlocked ? desc : '???',
                            unlockedAt: isUnlocked ? _unlockedAt[id] : null,
                            unlocked: isUnlocked,
                          )
                              .animate()
                              .fadeIn(
                                delay: (index * 30).ms,
                                duration: 320.ms,
                              )
                              .slideY(begin: 0.06, end: 0);
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.orangePrimary.withOpacity(0.85)
                : (isDark
                    ? AppColors.darkCard.withOpacity(0.8)
                    : AppColors.lightCard.withOpacity(0.8)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.orangePrimary.withOpacity(0.25),
            ),
          ),
          child: Text(
            label,
            style: AppText.bodySemiBold(
              12,
              context: context,
              color: selected ? Colors.white : AppColors.orangePrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String icon;
  final String name;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;

  const _AchievementCard({
    required this.icon,
    required this.name,
    required this.description,
    required this.unlocked,
    required this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = unlocked
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 42,
              color: unlocked ? null : fg.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: AppText.bodySemiBold(13, context: context, color: fg),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppText.body(11, context: context, color: fg),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (unlockedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Unlocked ${unlockedAt!.toLocal().toIso8601String().split('T').first}',
              style: AppText.body(
                10,
                context: context,
                color: fg.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

