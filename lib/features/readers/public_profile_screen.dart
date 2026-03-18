import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/dynamic_sky_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/follow_repository.dart';
import '../../data/repositories/profile_repository.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _profilesRepo = ProfileRepository();
  final _followRepo = FollowRepository();

  Profile? _profile;
  bool _loading = true;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _profilesRepo.getProfileById(widget.userId);
      final isFollowing = await _followRepo.isFollowing(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _following = isFollowing;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_following) {
      await _followRepo.unfollow(widget.userId);
    } else {
      await _followRepo.follow(widget.userId);
    }
    if (!mounted) return;
    setState(() => _following = !_following);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DynamicSkyBackground(
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.orangePrimary,
                  ),
                )
              : (_profile == null)
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Reader not found.',
                              style: AppText.body(14, context: context),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            GradientButton(
                              label: 'Back',
                              onPressed: () => context.pop(),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.orangePrimary,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
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
                                  'Reader Profile',
                                  style: AppText.display(20, context: context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Container(
                                  width: 82,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: AppColors.gradientOrange,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.orangePrimary
                                            .withOpacity(0.35),
                                        blurRadius: 24,
                                      )
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    (_profile!.displayName.isNotEmpty
                                            ? _profile!.displayName[0]
                                            : 'P')
                                        .toUpperCase(),
                                    style: AppText.display(
                                      32,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _profile!.displayName.isEmpty
                                      ? '@${_profile!.username}'
                                      : _profile!.displayName,
                                  style: AppText.display(20, context: context),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@${_profile!.username}',
                                  style: AppText.body(
                                    13,
                                    context: context,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                if ((_profile!.bio ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    _profile!.bio!,
                                    style:
                                        AppText.body(13, context: context),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if ((_profile!.location ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _profile!.location!,
                                    style: AppText.body(
                                      12,
                                      context: context,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                _following
                                    ? OutlinedButton(
                                        onPressed: _toggleFollow,
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: AppColors.orangePrimary
                                                .withOpacity(0.55),
                                          ),
                                          foregroundColor:
                                              AppColors.orangePrimary,
                                        ),
                                        child: const Text('Following ✓'),
                                      )
                                    : GradientButton(
                                        label: 'Follow',
                                        width: double.infinity,
                                        onPressed: _toggleFollow,
                                      ),
                                const SizedBox(height: 10),
                                Text(
                                  'Send a message (coming soon)',
                                  style: AppText.body(
                                    12,
                                    context: context,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.06, end: 0),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

