import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/book_cover_widget.dart';
import '../../core/widgets/themed_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/star_rating_widget.dart';
import '../../data/models/catalog_book.dart';
import '../../data/models/profile.dart';
import '../../data/models/review.dart';
import '../../data/models/user_book.dart';
import '../../data/repositories/catalog_book_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/review_repository.dart';

/// IMDB-style book page: metadata, external links, library, discussion — no reader.
class CatalogBookDetailScreen extends StatefulWidget {
  final String bookId;

  const CatalogBookDetailScreen({super.key, required this.bookId});

  @override
  State<CatalogBookDetailScreen> createState() =>
      _CatalogBookDetailScreenState();
}

class _CatalogBookDetailScreenState extends State<CatalogBookDetailScreen> {
  final _repo = CatalogBookRepository();
  final _reviewsRepo = ReviewRepository();
  final _profilesRepo = ProfileRepository();
  final _commentCtrl = TextEditingController();

  CatalogBook? _book;
  bool _loading = true;
  String? _error;

  List<Review> _reviews = [];
  Map<String, Profile> _profiles = {};
  bool _reviewsLoading = true;
  bool _sortByLikes = false;

  bool _descExpanded = false;
  bool _spoiler = false;
  double _draftRating = 0;
  bool _posting = false;
  double _userRating = 0;
  BookStatus _selectedStatus = BookStatus.tbr;

  bool _ensureSignedIn({String action = 'continue'}) {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sign in required to $action.')),
    );
    context.push('/auth/login');
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final extra = GoRouterState.of(context).extra;
      if (extra is CatalogBook) {
        setState(() {
          _book = extra;
          _loading = false;
        });
        _loadMyStatus();
        _loadReviews();
      } else {
        _fetchBook();
      }
    });
  }

  Future<void> _fetchBook() async {
    final id = Uri.decodeComponent(widget.bookId);
    final b = await _repo.getByCatalogId(id);
    if (!mounted) return;
    setState(() {
      _book = b;
      _loading = false;
      if (b == null) _error = 'Could not load this book.';
    });
    if (b != null) {
      _loadMyStatus();
      _loadReviews();
    }
  }

  String get _reviewBookId {
    final id = Uri.decodeComponent(widget.bookId);
    if (id.startsWith('gutenberg_') ||
        id.startsWith('google_') ||
        id.startsWith('openlibrary_')) {
      return id;
    }
    return 'gutenberg_$id';
  }

  Future<void> _loadReviews() async {
    setState(() => _reviewsLoading = true);
    final reviews = await _reviewsRepo.getReviewsForBook(
      _reviewBookId,
      sortByLikes: _sortByLikes,
    );
    final ids = reviews.map((r) => r.userId).toSet().toList();
    final profiles = await _profilesRepo.getProfilesByIds(ids);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _profiles = profiles;
      _reviewsLoading = false;
    });
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    if (!_ensureSignedIn(action: 'post a review')) return;
    final user = SupabaseConfig.client.auth.currentUser!;
    setState(() => _posting = true);
    try {
      final review = Review(
        id: const Uuid().v4(),
        userId: user.id,
        bookId: _reviewBookId,
        content: text,
        containsSpoilers: _spoiler,
        likesCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        starRating: _draftRating > 0 ? _draftRating : null,
      );
      await _reviewsRepo.addReview(review);
      _commentCtrl.clear();
      setState(() {
        _spoiler = false;
        _draftRating = 0;
      });
      await _loadReviews();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not post. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _toggleLike(Review r) async {
    if (!_ensureSignedIn(action: 'like reviews')) return;
    try {
      await _reviewsRepo.toggleLike(r.id, true);
      await _loadReviews();
    } catch (_) {}
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveUserRating(double r) async {
    if (!_ensureSignedIn(action: 'rate books')) return;
    final user = SupabaseConfig.client.auth.currentUser!;
    setState(() => _userRating = r);
    try {
      await _reviewsRepo.addReview(
        Review(
          id: const Uuid().v4(),
          userId: user.id,
          bookId: _reviewBookId,
          content: 'Quick rating',
          containsSpoilers: false,
          likesCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          starRating: r,
        ),
      );
      await _loadReviews();
    } catch (_) {}
  }

  Future<void> _addToTbr(CatalogBook b) async {
    if (!_ensureSignedIn(action: 'add books to TBR')) return;
    final user = SupabaseConfig.client.auth.currentUser!;
    try {
      await SupabaseConfig.client.from('books').upsert(b.toSupabaseBook());
      await SupabaseConfig.client.from('user_books').upsert({
        'user_id': user.id,
        'book_id': b.id,
        'status': BookStatus.tbr.name,
      });
      if (mounted) {
        setState(() => _selectedStatus = BookStatus.tbr);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to TBR.')),
        );
      }
    } catch (_) {}
  }

  Future<void> _loadMyStatus() async {
    final user = SupabaseConfig.client.auth.currentUser;
    final b = _book;
    if (user == null || b == null) return;
    try {
      final rows = await SupabaseConfig.client
          .from('user_books')
          .select('status')
          .eq('user_id', user.id)
          .eq('book_id', b.id)
          .limit(1);
      if (!mounted) return;
      if (rows.isNotEmpty) {
        final raw = (rows.first)['status'] as String?;
        BookStatus? parsed;
        for (final s in BookStatus.values) {
          if (s.name == raw) {
            parsed = s;
            break;
          }
        }
        if (parsed != null) {
          final BookStatus parsedValue = parsed;
          setState(() => _selectedStatus = parsedValue);
        }
      }
    } catch (_) {}
  }

  Future<void> _setStatus(BookStatus status) async {
    final b = _book;
    if (b == null) return;
    if (!_ensureSignedIn(action: 'update library status')) return;
    final user = SupabaseConfig.client.auth.currentUser!;
    try {
      await SupabaseConfig.client.from('books').upsert(b.toSupabaseBook());
      await SupabaseConfig.client.from('user_books').upsert({
        'user_id': user.id,
        'book_id': b.id,
        'status': status.name,
      });
      if (!mounted) return;
      setState(() => _selectedStatus = status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Status updated to ${status.name.toUpperCase()}.')),
      );
      if (status == BookStatus.read) {
        await _promptFinishReview();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update status. Try again.')),
      );
    }
  }

  Future<void> _promptFinishReview() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    double rating = 0;
    final reviewCtrl = TextEditingController();
    bool spoiler = false;
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('You finished this book!'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rate and review it for Pagewalker readers.'),
                    const SizedBox(height: 10),
                    StarRatingWidget(
                      rating: rating,
                      size: 28,
                      onRatingChanged: (v) => setLocal(() => rating = v),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reviewCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'What did you think?',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Contains spoilers'),
                        const Spacer(),
                        Switch(
                          value: spoiler,
                          onChanged: (v) => setLocal(() => spoiler = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Later'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Post review'),
                ),
              ],
            );
          },
        );
      },
    );
    if (submit != true) return;
    final text = reviewCtrl.text.trim();
    if (text.isEmpty && rating <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a rating or short review first.')),
        );
      }
      return;
    }
    try {
      await _reviewsRepo.addReview(
        Review(
          id: const Uuid().v4(),
          userId: user.id,
          bookId: _reviewBookId,
          content: text.isEmpty ? 'Finished this book.' : text,
          containsSpoilers: spoiler,
          likesCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          starRating: rating > 0 ? rating : null,
        ),
      );
      if (!mounted) return;
      setState(() => _userRating = rating);
      await _loadReviews();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review posted.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not post review.')),
        );
      }
    }
  }

  (_RatingAgg, List<int>) _aggregateRatings() {
    final withStars = _reviews
        .where((r) => r.starRating != null && r.starRating! > 0)
        .toList();
    if (withStars.isEmpty) {
      return (_RatingAgg(0, 0), const [0, 0, 0, 0, 0]);
    }
    double sum = 0;
    final buckets = [0, 0, 0, 0, 0];
    for (final r in withStars) {
      final s = r.starRating!.clamp(1.0, 5.0);
      sum += s;
      final b = s.round().clamp(1, 5) - 1;
      buckets[b]++;
    }
    final avg = sum / withStars.length;
    return (_RatingAgg(avg, withStars.length), buckets);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: ThemedBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null || _book == null) {
      return Scaffold(
        body: ThemedBackground(
          child: SafeArea(
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
                Expanded(child: Center(child: Text(_error ?? 'Error'))),
              ],
            ),
          ),
        ),
      );
    }

    final b = _book!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (agg, buckets) = _aggregateRatings();

    return Scaffold(
      body: ThemedBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (b.coverUrl != null)
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Image.network(
                          b.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.gradientEmber,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.gradientEmber,
                          ),
                        ),
                      ),
                    Center(
                      child: BookCoverWidget(
                        width: 140,
                        height: 210,
                        coverUrl: b.coverUrl,
                        title: b.title,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${b.author}',
                      style: AppText.body(
                        15,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        context: context,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${b.publishedYear ?? '—'}  |  ${b.pageCount ?? '—'} pages',
                      style: AppText.body(13, context: context),
                    ),
                    if (b.genres.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: b.genres.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            return Chip(
                              label: Text(
                                b.genres[i],
                                style: AppText.body(11, context: context),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _communityCard(context, b, agg, buckets)),
            SliverToBoxAdapter(child: _aboutCard(context, b)),
            SliverToBoxAdapter(child: _whereCard(context, b)),
            SliverToBoxAdapter(child: _libraryCard(context, b)),
            SliverToBoxAdapter(
              child: _discussionSection(
                context,
                b,
                isDark,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Widget _communityCard(
    BuildContext context,
    CatalogBook b,
    _RatingAgg agg,
    List<int> buckets,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = agg.count;
    final avg = agg.average;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagewalker rating',
              style: AppText.display(18, context: context),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  total == 0 ? '—' : avg.toStringAsFixed(1),
                  style: AppText.display(48, context: context),
                ),
                const SizedBox(width: 12),
                if (total > 0)
                  StarRatingWidget(
                    rating: avg,
                    size: 28,
                    interactive: false,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              total == 0
                  ? 'No ratings yet'
                  : 'Based on $total Pagewalker ${total == 1 ? 'reader' : 'readers'}',
              style: AppText.body(
                13,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                context: context,
              ),
            ),
            const SizedBox(height: 12),
            for (var star = 5; star >= 1; star--)
              _starBar(context, star, buckets[star - 1], total),
            const SizedBox(height: 16),
            Text(
              'Rate this book',
              style: AppText.bodySemiBold(13, context: context),
            ),
            const SizedBox(height: 8),
            StarRatingWidget(
              rating: _userRating,
              size: 32,
              onRatingChanged: _saveUserRating,
            ),
          ],
        ),
      ),
    );
  }

  Widget _starBar(BuildContext context, int stars, int count, int total) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$stars★', style: AppText.body(12, context: context)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor:
                    AppColors.orangePrimary.withValues(alpha: 0.12),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.orangePrimary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(pct * 100).round()}%',
            style: AppText.body(11, context: context),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(BuildContext context, CatalogBook b) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = b.description?.trim();
    final body = text != null && text.isNotEmpty
        ? text
        : (b.genres.isNotEmpty ? b.genres.join(', ') : 'No description yet.');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: AppText.bodySemiBold(15, context: context).copyWith(
                color: AppColors.orangePrimary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Text(
                body,
                maxLines: _descExpanded ? null : 4,
                overflow: _descExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
            if ((b.description?.length ?? 0) > 200)
              TextButton(
                onPressed: () => setState(() => _descExpanded = !_descExpanded),
                child: Text(_descExpanded ? 'Show less ▲' : 'Read more ▼'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _whereCard(BuildContext context, CatalogBook b) {
    final t = Uri.encodeComponent(b.title);
    final a = Uri.encodeComponent(b.author);
    final qTa = Uri.encodeQueryComponent('${b.title} ${b.author}');

    Future<void> open(String url) => _openExternal(url);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Where to find this book',
              style: AppText.bodySemiBold(15, context: context).copyWith(
                color: AppColors.orangePrimary,
              ),
            ),
            const SizedBox(height: 12),
            _OutlinedLinkButton(
              label: 'Find at local library',
              onPressed: () => open(
                'https://www.worldcat.org/search?q=$qTa',
              ),
            ),
            if (b.gutenbergNumericId != null) ...[
              const SizedBox(height: 10),
              GradientButton(
                label: 'Read free on Project Gutenberg',
                width: double.infinity,
                onPressed: () => open(
                  'https://www.gutenberg.org/ebooks/${b.gutenbergNumericId}',
                ),
              ),
            ],
            const SizedBox(height: 10),
            _OutlinedLinkButton(
              label: 'Read free on Standard Ebooks',
              onPressed: () => open(
                'https://standardebooks.org/ebooks?query=$t',
              ),
            ),
            const SizedBox(height: 10),
            _OutlinedLinkButton(
              label: 'Buy on Amazon',
              onPressed: () => open(
                'https://www.amazon.com/s?k=$t+$a',
              ),
            ),
            const SizedBox(height: 10),
            _OutlinedLinkButton(
              label: 'Read on Google Play Books',
              onPressed: () => open(
                'https://play.google.com/store/search?q=$t&c=books',
              ),
            ),
            if (b.externalPreviewUrl != null) ...[
              const SizedBox(height: 10),
              _OutlinedLinkButton(
                label: 'Preview on Google Books',
                onPressed: () => open(b.externalPreviewUrl!),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              "Pagewalker doesn't sell books. These links take you to external stores.",
              style: AppText.body(
                11,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
                context: context,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _libraryCard(BuildContext context, CatalogBook b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My status', style: AppText.display(18, context: context)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: 'TBR',
                  selected: _selectedStatus == BookStatus.tbr,
                  onTap: () => _setStatus(BookStatus.tbr),
                ),
                _StatusChip(
                  label: 'Reading',
                  selected: _selectedStatus == BookStatus.reading,
                  onTap: () => _setStatus(BookStatus.reading),
                ),
                _StatusChip(
                  label: 'Read',
                  selected: _selectedStatus == BookStatus.read,
                  onTap: () => _setStatus(BookStatus.read),
                ),
                _StatusChip(
                  label: 'DNF',
                  selected: _selectedStatus == BookStatus.dnf,
                  onTap: () => _setStatus(BookStatus.dnf),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Add to TBR ✦',
              width: double.infinity,
              onPressed: () => _addToTbr(b),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(
                '/book/${Uri.encodeComponent(_reviewBookId)}/room',
              ),
              icon: const Icon(Icons.forum_rounded),
              label: const Text('Open discussion room'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _discussionSection(
    BuildContext context,
    CatalogBook b,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discussion',
            style: AppText.display(22, context: context),
          ),
          const SizedBox(height: 4),
          Text(
            '${_reviews.length} ${_reviews.length == 1 ? 'reader' : 'readers'} talking about this',
            style: AppText.body(
              13,
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              context: context,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Most recent'),
                selected: !_sortByLikes,
                onSelected: (v) {
                  if (v) {
                    setState(() => _sortByLikes = false);
                    _loadReviews();
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Most liked'),
                selected: _sortByLikes,
                onSelected: (v) {
                  if (v) {
                    setState(() => _sortByLikes = true);
                    _loadReviews();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _commentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'What did you think? Share your hot take...',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Rating (optional)',
                      style: AppText.bodySemiBold(12, context: context),
                    ),
                    const SizedBox(width: 8),
                    StarRatingWidget(
                      rating: _draftRating,
                      size: 22,
                      onRatingChanged: (v) => setState(() => _draftRating = v),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('Spoiler', style: AppText.body(13, context: context)),
                    Switch(
                      value: _spoiler,
                      onChanged: (v) => setState(() => _spoiler = v),
                      activeTrackColor:
                          AppColors.orangePrimary.withValues(alpha: 0.45),
                      thumbColor:
                          WidgetStateProperty.all(AppColors.orangePrimary),
                    ),
                  ],
                ),
                GradientButton(
                  label: 'Post ✦',
                  width: double.infinity,
                  isLoading: _posting,
                  onPressed: _posting ? null : _postComment,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_reviewsLoading)
            const Center(child: CircularProgressIndicator())
          else if (_reviews.isEmpty)
            _EmptyDiscussion(title: b.title)
          else
            ..._reviews.asMap().entries.map((e) {
              final r = e.value;
              final p = _profiles[r.userId];
              return _DiscussionTile(
                review: r,
                username: p?.username ?? 'reader',
                onLike: () => _toggleLike(r),
              ).animate().fadeIn(delay: (e.key * 40).ms, duration: 350.ms);
            }),
        ],
      ),
    );
  }
}

class _OutlinedLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlinedLinkButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.orangePrimary),
          foregroundColor: AppColors.orangePrimary,
        ),
        child: Text(label),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.orangePrimary.withValues(alpha: 0.2),
      side: BorderSide(
        color: selected
            ? AppColors.orangePrimary
            : AppColors.orangePrimary.withValues(alpha: 0.35),
      ),
    );
  }
}

class _RatingAgg {
  final double average;
  final int count;

  _RatingAgg(this.average, this.count);
}

class _DiscussionTile extends StatefulWidget {
  final Review review;
  final String username;
  final VoidCallback onLike;

  const _DiscussionTile({
    required this.review,
    required this.username,
    required this.onLike,
  });

  @override
  State<_DiscussionTile> createState() => _DiscussionTileState();
}

class _DiscussionTileState extends State<_DiscussionTile> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.review;
    final blur = r.containsSpoilers && !_revealed;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.orangePrimary, width: 2),
                ),
                child: Center(
                  child: Text(
                    widget.username.isNotEmpty
                        ? widget.username[0].toUpperCase()
                        : '?',
                    style: AppText.bodySemiBold(14, context: context),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${widget.username}',
                      style: AppText.bodySemiBold(14, context: context),
                    ),
                    Text(
                      DateFormat.yMMMd().add_jm().format(r.createdAt),
                      style: AppText.body(
                        11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        context: context,
                      ),
                    ),
                  ],
                ),
              ),
              if (r.starRating != null && r.starRating! > 0)
                StarRatingWidget(
                  rating: r.starRating!,
                  size: 16,
                  interactive: false,
                ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: blur ? () => setState(() => _revealed = true) : null,
            child: blur
                ? Text(
                    'Spoiler — tap to reveal',
                    style: AppText.displayItalic(14, context: context),
                  )
                : Text(
                    r.content.trim(),
                    style: AppText.body(14, context: context),
                  ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.onLike,
            icon: const Icon(Icons.favorite_border_rounded, size: 18),
            label: Text('${r.likesCount}'),
          ),
        ],
      ),
    );
  }
}

class _EmptyDiscussion extends StatelessWidget {
  final String title;

  const _EmptyDiscussion({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 48,
            color: AppColors.logoMarkColor(context).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),
          Text(
            'No one has talked about this book yet on Pagewalker.',
            style: AppText.body(15, context: context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first! What did you think?',
            style: AppText.body(14, context: context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
