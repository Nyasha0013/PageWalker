import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/dynamic_sky_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/services/achievement_service.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/follow_repository.dart';
import '../../data/repositories/profile_repository.dart';

class ReadersScreen extends StatefulWidget {
  const ReadersScreen({super.key});

  @override
  State<ReadersScreen> createState() => _ReadersScreenState();
}

class _ReadersScreenState extends State<ReadersScreen>
    with TickerProviderStateMixin {
  final _profilesRepo = ProfileRepository();
  final _followRepo = FollowRepository();

  int _tab = 0;
  final _tabs = const ['Following', 'Discover'];

  final _searchController = TextEditingController();
  bool _loading = false;
  List<Profile> _discover = [];
  List<Profile> _following = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_tab != 1) return;
    _loadDiscover(query: _searchController.text);
  }

  Future<void> _load() async {
    await Future.wait([
      _loadDiscover(),
      _loadFollowing(),
    ]);
  }

  Future<void> _loadDiscover({String? query}) async {
    setState(() => _loading = true);
    try {
      final profiles = await _profilesRepo.searchPublicProfiles(query: query);
      if (!mounted) return;
      setState(() => _discover = profiles);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFollowing() async {
    setState(() => _loading = true);
    try {
      final ids = await _followRepo.getFollowingIds();
      final profiles = <Profile>[];
      for (final id in ids) {
        final p = await _profilesRepo.getProfileById(id);
        if (p != null) profiles.add(p);
      }
      if (!mounted) return;
      setState(() => _following = profiles);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DynamicSkyBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.orangePrimary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Find Readers',
                        style: AppText.display(22, context: context),
                      ),
                    ),
                    IconButton(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppColors.orangePrimary,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard.withOpacity(0.8)
                      : AppColors.lightCard.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.orangePrimary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: _tabs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final label = entry.value;
                    final selected = _tab == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.orangePrimary.withOpacity(0.85)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppText.bodySemiBold(
                              13,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_tab == 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by @username',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.orangePrimary,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.orangePrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          itemCount: (_tab == 0 ? _following : _discover).length,
                          itemBuilder: (context, index) {
                            final p = (_tab == 0 ? _following : _discover)[index];
                            return _ReaderCard(
                              profile: p,
                              onTap: () => context.push('/reader/${p.id}'),
                            )
                                .animate()
                                .fadeIn(delay: (index * 40).ms, duration: 350.ms)
                                .slideY(begin: 0.06, end: 0);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderCard extends StatefulWidget {
  final Profile profile;
  final VoidCallback onTap;

  const _ReaderCard({
    required this.profile,
    required this.onTap,
  });

  @override
  State<_ReaderCard> createState() => _ReaderCardState();
}

class _ReaderCardState extends State<_ReaderCard> {
  final _followRepo = FollowRepository();

  bool _loading = false;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final isFollowing = await _followRepo.isFollowing(widget.profile.id);
    if (!mounted) return;
    setState(() => _following = isFollowing);
  }

  Future<void> _toggleFollow() async {
    setState(() => _loading = true);
    try {
      if (_following) {
        await _followRepo.unfollow(widget.profile.id);
      } else {
        await _followRepo.follow(widget.profile.id);
        final user = SupabaseConfig.client.auth.currentUser;
        if (user != null) {
          await AchievementService().checkAchievements(
            userId: user.id,
            followedSomeone: true,
          );
        }
      }
      if (!mounted) return;
      setState(() => _following = !_following);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.profile;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: AppColors.gradientOrange),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orangePrimary.withOpacity(0.3),
                  blurRadius: 18,
                )
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              (p.displayName.isNotEmpty ? p.displayName[0] : 'P')
                  .toUpperCase(),
              style: AppText.bodySemiBold(16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.displayName.isEmpty ? '@${p.username}' : p.displayName,
                    style: AppText.bodySemiBold(14, context: context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${p.username}',
                    style: AppText.body(
                      12,
                      context: context,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  if ((p.location ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      p.location!,
                      style: AppText.body(
                        11,
                        context: context,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: _following
                ? OutlinedButton(
                    onPressed: _loading ? null : _toggleFollow,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.orangePrimary.withOpacity(0.55),
                      ),
                      foregroundColor: AppColors.orangePrimary,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.orangePrimary,
                            ),
                          )
                        : const Text('Following ✓'),
                  )
                : GradientButton(
                    label: _loading ? '...' : 'Follow',
                    width: 112,
                    onPressed: _loading ? null : _toggleFollow,
                  ),
          ),
        ],
      ),
    );
  }
}

