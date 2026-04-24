import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/book_cover_widget.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/themed_background.dart';
import '../../core/widgets/star_rating_widget.dart';
import '../../data/models/profile.dart';
import '../../data/models/review.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../book_club/book_clubs_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  bool _requireAuth(String action) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sign in required to $action.')),
    );
    context.push('/auth/login');
    return false;
  }

  void _openWriteReview() {
    if (!_requireAuth('write reviews')) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _WriteReviewSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.webLogoOrange.withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: 'social_write_review',
            backgroundColor: AppColors.webLogoOrange,
            elevation: 8,
            onPressed: _openWriteReview,
            child:
                const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: ThemedBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  labelColor: AppColors.webLogoOrange,
                  unselectedLabelColor: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  indicatorColor: AppColors.webLogoOrange,
                  tabs: const [
                    Tab(text: 'Reviews'),
                    Tab(text: 'Book clubs'),
                  ],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      _ReviewsByBookTab(),
                      BookClubsScreen(embedded: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookReviewGroup {
  final String bookId;
  final String? bookTitle;
  final String? bookAuthor;
  final String? bookCoverUrl;
  final List<Review> reviews;

  const _BookReviewGroup({
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookCoverUrl,
    required this.reviews,
  });
}

List<_BookReviewGroup> _groupReviewsByBook(
  List<Review> reviews, {
  int maxBooks = 24,
  int maxReviewsPerBook = 8,
}) {
  final map = <String, List<Review>>{};
  final order = <String>[];

  for (final r in reviews) {
    if (!map.containsKey(r.bookId)) {
      if (map.length >= maxBooks) continue;
      map[r.bookId] = [];
      order.add(r.bookId);
    }
    final list = map[r.bookId]!;
    if (list.length < maxReviewsPerBook) {
      list.add(r);
    }
  }

  return order.map((id) {
    final list = map[id]!;
    final first = list.first;
    return _BookReviewGroup(
      bookId: id,
      bookTitle: first.bookTitle,
      bookAuthor: first.bookAuthor,
      bookCoverUrl: first.bookCoverUrl,
      reviews: list,
    );
  }).toList();
}

class _ReviewsByBookTab extends StatefulWidget {
  const _ReviewsByBookTab();

  @override
  State<_ReviewsByBookTab> createState() => _ReviewsByBookTabState();
}

class _ReviewsByBookTabState extends State<_ReviewsByBookTab> {
  final _reviewRepo = ReviewRepository();
  final _profileRepo = ProfileRepository();
  late Future<_SocialFeedData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<_SocialFeedData> _load() async {
    final reviews = await _reviewRepo.getRecentReviews(limit: 160);
    final groups = _groupReviewsByBook(reviews);
    final userIds = reviews.map((r) => r.userId).toSet().toList();
    final profiles = await _profileRepo.getProfilesByIds(userIds);
    return _SocialFeedData(groups: groups, profiles: profiles);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SocialFeedData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.webLogoOrange),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load activity.',
                style: AppText.body(14, context: context),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          color: AppColors.webLogoOrange,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community',
                            style: AppText.bodySemiBold(14, context: context),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reviews are grouped by book. Find readers from a review, or jump into a club.',
                            style: AppText.body(12, context: context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    PopupMenuButton<String>(
                      tooltip: 'Readers',
                      offset: const Offset(0, 44),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: AppColors.gradientOrange,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'find':
                          case 'following':
                          case 'search':
                            context.push('/readers');
                            break;
                          case 'discover':
                            context.push('/discover');
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'find',
                          child: Text('Find readers'),
                        ),
                        PopupMenuItem(
                          value: 'following',
                          child: Text('Following'),
                        ),
                        PopupMenuItem(
                          value: 'discover',
                          child: Text('Discover books'),
                        ),
                        PopupMenuItem(
                          value: 'search',
                          child: Text('Search by username'),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
              if (data.groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 48,
                        color: AppColors.logoMarkColor(context)
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No reviews yet',
                        style: AppText.display(18, context: context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When readers post reviews, they will show up here under each book.',
                        style: AppText.body(13, context: context),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        label: 'Discover books',
                        onPressed: () => context.push('/discover'),
                      ),
                    ],
                  ),
                )
              else
                ...data.groups.asMap().entries.map((entry) {
                  final i = entry.key;
                  final g = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BookWithReviewsCard(
                      group: g,
                      profiles: data.profiles,
                    )
                        .animate()
                        .fadeIn(delay: (i * 40).ms, duration: 400.ms)
                        .slideY(begin: 0.06, end: 0),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _SocialFeedData {
  final List<_BookReviewGroup> groups;
  final Map<String, Profile> profiles;

  const _SocialFeedData({
    required this.groups,
    required this.profiles,
  });
}

class _BookWithReviewsCard extends StatelessWidget {
  final _BookReviewGroup group;
  final Map<String, Profile> profiles;

  const _BookWithReviewsCard({
    required this.group,
    required this.profiles,
  });

  String get _title =>
      (group.bookTitle != null && group.bookTitle!.trim().isNotEmpty)
          ? group.bookTitle!.trim()
          : 'Book';

  String get _subtitle =>
      (group.bookAuthor != null && group.bookAuthor!.trim().isNotEmpty)
          ? group.bookAuthor!.trim()
          : 'Open for details';

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push(
                '/book/${Uri.encodeComponent(group.bookId)}',
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    BookCoverWidget(
                      width: 48,
                      height: 72,
                      title: _title,
                      coverUrl: group.bookCoverUrl,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: AppText.bodySemiBold(15, context: context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subtitle,
                            style: AppText.body(
                              12,
                              context: context,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${group.reviews.length} review${group.reviews.length == 1 ? '' : 's'} · tap for book',
                            style: AppText.label(
                              10,
                              context: context,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.logoMarkColor(context)
                          .withValues(alpha: 0.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 20),
          ...group.reviews.map(
            (r) => _SocialReviewTile(
              review: r,
              profile: profiles[r.userId],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialReviewTile extends StatefulWidget {
  final Review review;
  final Profile? profile;

  const _SocialReviewTile({
    required this.review,
    required this.profile,
  });

  @override
  State<_SocialReviewTile> createState() => _SocialReviewTileState();
}

class _SocialReviewTileState extends State<_SocialReviewTile>
    with SingleTickerProviderStateMixin {
  final _reviewRepo = ReviewRepository();
  bool _liked = false;
  int _likesCount = 0;
  bool _showSpoiler = false;
  late AnimationController _likeController;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.review.likesCount;
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.9,
      upperBound: 1.1,
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  Future<void> _onLike() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in required to like reviews.')),
      );
      context.push('/auth/login');
      return;
    }
    final next = !_liked;
    setState(() {
      _liked = next;
      _likesCount = (_likesCount + (next ? 1 : -1)).clamp(0, 1 << 30);
    });
    _likeController
      ..reset()
      ..forward();
    try {
      await _reviewRepo.toggleLike(widget.review.id, next);
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = !next;
          _likesCount += next ? -1 : 1;
        });
      }
    }
  }

  String get _handle {
    final u = widget.profile?.username;
    if (u != null && u.isNotEmpty) return '@$u';
    return 'Reader';
  }

  String get _tagline => widget.profile?.displayName.isNotEmpty == true
      ? widget.profile!.displayName
      : '';

  String _twoChars(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return 'PW';
    final upper = s.toUpperCase();
    if (upper.length >= 2) return upper.substring(0, 2);
    return '$upper•'.substring(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.review;
    final initials = _tagline.isNotEmpty
        ? _twoChars(_tagline)
        : _twoChars(_handle.replaceAll('@', ''));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.profile == null
                  ? null
                  : () => context.push('/reader/${widget.review.userId}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: AppColors.logoMarkRingGradient(context),
                        ),
                        border: Border.all(
                          color: AppColors.logoMarkColor(context)
                              .withValues(alpha: 0.75),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _handle,
                            style: AppText.bodySemiBold(13, context: context),
                          ),
                          if (_tagline.isNotEmpty)
                            Text(
                              _tagline,
                              style: AppText.body(11, context: context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (r.starRating != null && r.starRating! > 0) ...[
            StarRatingWidget(
              rating: r.starRating!,
              size: 16,
              interactive: false,
            ),
            const SizedBox(height: 6),
          ],
          if (r.containsSpoilers)
            GestureDetector(
              onTap: () => setState(() => _showSpoiler = !_showSpoiler),
              child: AnimatedOpacity(
                opacity: _showSpoiler ? 1 : 0.35,
                duration: const Duration(milliseconds: 250),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          r.content,
                          style: AppText.body(13, context: context),
                        ),
                      ),
                      if (!_showSpoiler)
                        Positioned.fill(
                          child: Container(
                            color: (isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard)
                                .withValues(alpha: 0.82),
                            alignment: Alignment.center,
                            child: Text(
                              'Tap to reveal spoilers',
                              style: AppText.body(11, context: context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            Text(
              r.content,
              style: AppText.body(13, context: context),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              ScaleTransition(
                scale: _likeController.drive(
                  Tween(begin: 0.9, end: 1.1),
                ),
                child: GestureDetector(
                  onTap: _onLike,
                  child: Icon(
                    _liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _liked
                        ? AppColors.orangeBright
                        : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$_likesCount',
                style: AppText.body(11, context: context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet();

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  final _bookController = TextEditingController();
  final _reviewController = TextEditingController();
  double _rating = 0;
  bool _spoiler = false;

  @override
  void dispose() {
    _bookController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return GlassCard(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share your review',
                style: AppText.display(18, context: context),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bookController,
                decoration: const InputDecoration(
                  labelText: 'Search book',
                ),
                style: AppText.body(14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your rating',
                    style: AppText.bodySemiBold(13),
                  ),
                  StarRatingWidget(
                    rating: _rating,
                    size: 24,
                    onRatingChanged: (value) {
                      setState(() => _rating = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Your thoughts',
                ),
                style: AppText.body(14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Contains spoilers',
                    style: AppText.body(13),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: _spoiler,
                    onChanged: (v) {
                      setState(() => _spoiler = v);
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Share Review',
                width: double.infinity,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
