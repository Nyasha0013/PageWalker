import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/themed_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import 'book_club_models.dart';

class BookClubsScreen extends StatefulWidget {
  /// When true (e.g. Social tab), omits [Scaffold] back affordance — parent owns navigation.
  final bool embedded;

  const BookClubsScreen({super.key, this.embedded = false});

  @override
  State<BookClubsScreen> createState() => _BookClubsScreenState();
}

class _BookClubsScreenState extends State<BookClubsScreen> {
  Future<List<BookClub>> _load() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return [];

    // Best-effort: try a join via book_club_members -> book_clubs relationship.
    try {
      final rows = await SupabaseConfig.client
          .from('book_club_members')
          .select('club_id, book_clubs(*)')
          .eq('user_id', user.id);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map((r) => r['book_clubs'])
          .whereType<Map<String, dynamic>>()
          .map(BookClub.fromSupabase)
          .toList();
    } catch (_) {
      // Fallback: two-step query.
      final memberRows = await SupabaseConfig.client
          .from('book_club_members')
          .select('club_id')
          .eq('user_id', user.id);
      final clubIds =
          (memberRows as List).map((r) => r['club_id'] as String).toList();
      if (clubIds.isEmpty) return [];
      final clubRows = await SupabaseConfig.client
          .from('book_clubs')
          .select()
          .inFilter('id', clubIds);
      return (clubRows as List)
          .cast<Map<String, dynamic>>()
          .map(BookClub.fromSupabase)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = ThemedBackground(
      child: SafeArea(
        child: FutureBuilder<List<BookClub>>(
          future: _load(),
          builder: (context, snapshot) {
            final clubs = snapshot.data ?? const <BookClub>[];
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: !widget.embedded,
                  leading: widget.embedded
                      ? null
                      : IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppColors.orangePrimary,
                        ),
                  title: Text(
                    'Book Clubs',
                    style: AppText.display(22, context: context),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => context.push('/clubs/join'),
                      icon: const Icon(Icons.vpn_key_rounded),
                      color: AppColors.orangePrimary,
                      tooltip: 'Join with code',
                    ),
                    IconButton(
                      onPressed: () => context.push('/clubs/create'),
                      icon: const Icon(Icons.add_circle_rounded),
                      color: AppColors.orangePrimary,
                      tooltip: 'Create club',
                    ),
                  ],
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.orangePrimary,
                      ),
                    ),
                  )
                else if (clubs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📚', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'No book clubs yet',
                            style: AppText.display(20, context: context),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Start one with your friends or join with an invite code.',
                            style: AppText.body(13, context: context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          GradientButton(
                            label: 'Create a Club',
                            width: double.infinity,
                            onPressed: () => context.push('/clubs/create'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => context.push('/clubs/join'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.orangePrimary,
                              side: BorderSide(
                                color:
                                    AppColors.orangePrimary.withOpacity(0.45),
                              ),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Join with Code'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: clubs.length,
                    itemBuilder: (context, i) {
                      final c = clubs[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                        child: GestureDetector(
                          onTap: () => context.push('/clubs/${c.id}'),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Text(c.coverEmoji,
                                    style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name,
                                        style: AppText.bodySemiBold(
                                          15,
                                          context: context,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.description?.isNotEmpty == true
                                            ? c.description!
                                            : 'Reading together ✦',
                                        style: AppText.body(
                                          12,
                                          context: context,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white.withOpacity(0.35),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (i * 60).ms, duration: 380.ms)
                            .slideY(begin: 0.08, end: 0),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(body: body);
  }
}
