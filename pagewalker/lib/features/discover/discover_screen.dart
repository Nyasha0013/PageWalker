import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/url_utils.dart';
import '../../core/widgets/book_cover_widget.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/themed_background.dart';
import '../../core/widgets/trope_chip.dart';
import '../../data/models/book.dart';
import '../../data/models/catalog_book.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/repositories/catalog_book_repository.dart';
import '../../data/repositories/review_repository.dart';

/// Discover “Hot right now” row — in-app buzz or API fallback.
class HotNowRow {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String badge;

  const HotNowRow({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.badge,
  });
}

const _googleCuratedCollections = <(String, String)>[
  ('Enemies to Lovers', 'enemies to lovers romance'),
  ('Dark Academia', 'dark academia mystery thriller'),
  ('Magic & Fantasy', 'fantasy magic young adult'),
  ('Dark Romance', 'dark romance adult fiction'),
  ('Cozy Mystery', 'cozy mystery detective'),
];

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _moodController = TextEditingController();
  final _repository = BookRepository();
  final _catalogRepo = CatalogBookRepository();
  final PageController _curatedPageController =
      PageController(viewportFraction: 0.72);
  List<CatalogBook> _freeToRead = [];
  List<CatalogBook> _justAdded = [];
  bool _unifiedLoading = true;
  final _moods = const [
    'Make me cry',
    'Dark & twisted',
    'Cozy',
    'Chaos',
    'Slow burn',
    'Magic',
    'Light & funny',
  ];
  bool _loading = false;
  List<String> _topBooks = const [];
  List<String> _topTropes = const [];
  List<Book> _moodBooks = [];
  List<HotNowRow> _hotRows = [];
  List<(String label, List<CatalogBook> books)> _curated = [];
  final _reviewRepo = ReviewRepository();

  @override
  void initState() {
    super.initState();
    _loadUnifiedDiscover();
  }

  @override
  void dispose() {
    _moodController.dispose();
    _curatedPageController.dispose();
    super.dispose();
  }

  Future<void> _loadUnifiedDiscover() async {
    final popular = await _catalogRepo.getPopularGutenberg();
    final newest = await _catalogRepo.getNewestGutenberg(limit: 8);
    final mixed = await _catalogRepo.getPopularMixed(limit: 12);

    final hotFromReviews = await _reviewRepo.getHotBooksThisWeek();
    final hotRows = <HotNowRow>[];
    for (final m in hotFromReviews) {
      final id = m['book_id'] as String;
      final titleRaw = m['book_title'] as String?;
      final author = (m['book_author'] as String?)?.trim() ?? '';
      final cover = m['book_cover_url'] as String?;
      final count = m['count'] as int;
      hotRows.add(
        HotNowRow(
          id: id,
          title: (titleRaw != null && titleRaw.trim().isNotEmpty)
              ? titleRaw.trim()
              : 'Book',
          author: author,
          coverUrl: cover,
          badge: '$count ${count == 1 ? 'reader' : 'readers'} discussing',
        ),
      );
    }
    if (hotRows.isEmpty) {
      if (Env.hasGoogleBooksApiKey) {
        final trending =
            await _catalogRepo.getGoogleTrendingFiction(maxResults: 8);
        for (final b in trending) {
          hotRows.add(
            HotNowRow(
              id: b.id,
              title: b.title,
              author: b.author,
              coverUrl: b.coverUrl,
              badge: 'Trending',
            ),
          );
        }
      }
      if (hotRows.isEmpty) {
        for (final b in mixed.take(6)) {
          hotRows.add(
            HotNowRow(
              id: b.id,
              title: b.title,
              author: b.author,
              coverUrl: b.coverUrl,
              badge: 'Popular now',
            ),
          );
        }
      }
    }

    late final List<(String, List<CatalogBook>)> curatedSlices;
    if (Env.hasGoogleBooksApiKey) {
      curatedSlices = [];
      for (final c in _googleCuratedCollections) {
        final books = await _catalogRepo.searchGoogleBooksForQuery(
          c.$2,
          maxResults: 5,
        );
        curatedSlices.add((c.$1, books));
      }
    } else {
      final genres = [
        ('Romance picks', 'romance'),
        ('Mystery night', 'mystery'),
        ('History & ideas', 'history'),
        ('Science & wonder', 'science_fiction'),
        ('Philosophy shelf', 'philosophy'),
      ];
      curatedSlices = await Future.wait(
        genres.map((g) async {
          final books =
              await _catalogRepo.getOpenLibrarySubjectSlice(g.$2, limit: 4);
          return (g.$1, books);
        }),
      );
    }

    if (!mounted) return;
    setState(() {
      _freeToRead = popular.take(12).toList();
      _justAdded = newest;
      _hotRows = hotRows;
      _curated = curatedSlices;
      _unifiedLoading = false;
    });
  }

  Future<void> _findNextRead() async {
    if (_moodController.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _moodBooks = [];
    });
    try {
      final books = await _repository.getMoodRecommendations(
        moodInput: _moodController.text.trim(),
        topBooks: _topBooks,
        topTropes: _topTropes,
      );
      setState(() {
        _moodBooks = books;
      });
    } catch (_) {
      setState(() {
        _moodBooks = [];
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24,
            ),
            children: [
              Text(
                'What’s your vibe?',
                style: AppText.display(26, context: context),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _moodController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Tell Pagewalker how you want to feel...',
                      ),
                      style: AppText.body(14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _moods.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final label = _moods[index];
                          return TropeChip(
                            label: label,
                            selected: false,
                            onTap: () {
                              _moodController.text = label;
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Find my next read ✦',
                      width: double.infinity,
                      onPressed: _loading ? null : _findNextRead,
                      isLoading: _loading,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 120.ms, duration: 500.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              Text(
                'Popular on Project Gutenberg',
                style: AppText.display(20, context: context),
              ).animate().fadeIn(delay: 140.ms, duration: 400.ms),
              const SizedBox(height: 12),
              if (_unifiedLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _freeToRead.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final b = _freeToRead[i];
                      return GestureDetector(
                        onTap: () => context.push(
                          '/book/${Uri.encodeComponent(b.id)}',
                          extra: b,
                        ),
                        child: SizedBox(
                          width: 124,
                          child: GlassCard(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        b.coverUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl:
                                                    fixCoverUrl(b.coverUrl) ??
                                                        '',
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              )
                                            : Container(
                                                color: AppColors
                                                    .logoMarkSurfaceTint(
                                                        context),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.menu_book_rounded,
                                                  color:
                                                      AppColors.logoMarkColor(
                                                          context),
                                                ),
                                              ),
                                        Positioned(
                                          right: 6,
                                          bottom: 6,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: b.source ==
                                                          BookSource.gutenberg
                                                      ? AppColors.orangePrimary
                                                      : b.source ==
                                                              BookSource
                                                                  .googleBooks
                                                          ? Colors.blueAccent
                                                          : Colors.greenAccent
                                                              .shade400,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                b.source == BookSource.gutenberg
                                                    ? 'PG'
                                                    : b.source ==
                                                            BookSource
                                                                .googleBooks
                                                        ? 'GB'
                                                        : 'OL',
                                                style: AppText.label(
                                                  9,
                                                  context: context,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  b.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.bodySemiBold(
                                    12,
                                    context: context,
                                  ),
                                ),
                                Text(
                                  b.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(
                                    10,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    context: context,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Just Added to Free Library',
                style: AppText.display(20, context: context),
              ),
              const SizedBox(height: 12),
              if (_unifiedLoading)
                const SizedBox.shrink()
              else
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _justAdded.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final b = _justAdded[i];
                      return GestureDetector(
                        onTap: () => context.push(
                          '/book/${Uri.encodeComponent(b.id)}',
                          extra: b,
                        ),
                        child: SizedBox(
                          width: 120,
                          child: GlassCard(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: b.coverUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: b.coverUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          )
                                        : Container(
                                            color:
                                                AppColors.logoMarkSurfaceTint(
                                                    context),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.menu_book_rounded,
                                              color: AppColors.logoMarkColor(
                                                  context),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  b.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.bodySemiBold(
                                    12,
                                    context: context,
                                  ),
                                ),
                                Text(
                                  b.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(
                                    10,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    context: context,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/free-books'),
                  child: Text(
                    'View full library →',
                    style: AppText.bodySemiBold(14, context: context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore by vibe:',
                style: AppText.bodySemiBold(13, context: context),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in kCatalogGenreMap.entries.take(8))
                    ActionChip(
                      label: Text(e.key),
                      onPressed: () => context.push(
                        '/search?topic=${Uri.encodeComponent(e.value)}',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 140,
                        child: Lottie.asset(
                          'assets/animations/sparkle.json',
                          repeat: true,
                        ),
                      ),
                      Text(
                        'Consulting the story stars...',
                        style: AppText.body(
                          14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_loading && _moodBooks.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommendations',
                      style: AppText.display(20, context: context),
                    ).animate().fadeIn(
                          delay: 160.ms,
                          duration: 400.ms,
                        ),
                    const SizedBox(height: 12),
                    ..._moodBooks.asMap().entries.map(
                          (entry) => GlassCard(
                            margin: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                BookCoverWidget(
                                  width: 60,
                                  height: 90,
                                  title: entry.value.title,
                                  coverUrl: entry.value.coverUrl,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.value.title,
                                        style: AppText.bodySemiBold(
                                          15,
                                          context: context,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.value.author,
                                        style: AppText.body(
                                          12,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                          context: context,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'A pick that matches your current vibe.',
                                        style: AppText.displayItalic(
                                          13,
                                          context: context,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(
                                delay: (200 + entry.key * 60).ms,
                                duration: 400.ms,
                              )
                              .slideY(
                                begin: 0.1,
                                end: 0,
                              ),
                        ),
                  ],
                ),
              const SizedBox(height: 24),
              Text(
                'Curated for you',
                style: AppText.display(20, context: context),
              ),
              const SizedBox(height: 12),
              if (_curated.isEmpty)
                Text(
                  'Loading collections…',
                  style: AppText.body(13, context: context),
                )
              else
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _curatedPageController,
                    itemCount: _curated.length,
                    itemBuilder: (context, index) {
                      final label = _curated[index].$1;
                      final books = _curated[index].$2;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style:
                                    AppText.bodySemiBold(14, context: context),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    for (final b in books.take(3))
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
                                          child: GestureDetector(
                                            onTap: () => context.push(
                                              '/book/${Uri.encodeComponent(b.id)}',
                                              extra: b,
                                            ),
                                            child: BookCoverWidget(
                                              width: 56,
                                              height: 84,
                                              title: b.title,
                                              coverUrl: b.coverUrl,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Hot right now',
                style: AppText.display(20, context: context),
              ),
              const SizedBox(height: 8),
              Text(
                Env.hasGoogleBooksApiKey
                    ? 'Most discussed in Pagewalker this week, or trending from Google Books.'
                    : 'Most discussed in Pagewalker this week, or popular picks from our catalog.',
                style: AppText.body(
                  12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  context: context,
                ),
              ),
              const SizedBox(height: 12),
              if (_hotRows.isEmpty)
                Text(
                  'Check back soon for trending titles.',
                  style: AppText.body(13, context: context),
                )
              else
                ..._hotRows.map((row) {
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    child: InkWell(
                      onTap: () => context.push(
                        '/book/${Uri.encodeComponent(row.id)}',
                      ),
                      child: Row(
                        children: [
                          BookCoverWidget(
                            width: 52,
                            height: 78,
                            title: row.title,
                            coverUrl: row.coverUrl,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.title,
                                  style: AppText.bodySemiBold(15,
                                      context: context),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  row.author,
                                  style: AppText.body(
                                    12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    context: context,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  row.badge,
                                  style: AppText.label(
                                    11,
                                    color: AppColors.orangeAmber,
                                    context: context,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
