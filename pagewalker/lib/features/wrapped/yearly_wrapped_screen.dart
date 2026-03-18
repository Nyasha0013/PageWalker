import 'dart:math';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/book_cover_widget.dart';
import '../../core/widgets/dynamic_sky_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/book.dart';
import '../../data/repositories/book_repository.dart';

class YearlyWrappedScreen extends StatefulWidget {
  final int year;
  const YearlyWrappedScreen({super.key, required this.year});

  @override
  State<YearlyWrappedScreen> createState() => _YearlyWrappedScreenState();
}

class _YearlyWrappedScreenState extends State<YearlyWrappedScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  final _shareCardKey = GlobalKey();
  final _repo = BookRepository();

  late final AnimationController _bgDrift;
  late final ConfettiController _confetti;

  int _index = 0;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    _bgDrift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _confetti = ConfettiController(duration: const Duration(milliseconds: 800));

    // Mark as seen as soon as the user opens it.
    _markSeen();
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wrapped_${widget.year}_seen', true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgDrift.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _goTo(int next) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      next.clamp(0, 7),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() => _goTo(_index + 1);

  void _skipToEnd() {
    setState(() => _skipped = true);
    _goTo(7);
  }

  Future<void> _shareCard() async {
    final renderObject = _shareCardKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;
    final image = await renderObject.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();

    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        name: 'pagewalker-wrapped-${widget.year}.png',
        mimeType: 'image/png',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Sign in to view Wrapped.',
            style: AppText.body(14, color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: DynamicSkyBackground(
        child: AnimatedBuilder(
          animation: _bgDrift,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: _OrangeParticleField(progress: _bgDrift.value),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF050505),
                          Color.lerp(
                                const Color(0xFF050505),
                                const Color(0xFF2A1206),
                                0.45 + 0.25 * _bgDrift.value,
                              ) ??
                              const Color(0xFF1A0B04),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: FutureBuilder<WrappedData>(
                    future: WrappedData.fetchForYear(user.id, widget.year),
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                            child: Row(
                              children: [
                                _ProgressDots(index: _index, count: 8),
                                const Spacer(),
                                TextButton(
                                  onPressed: _index == 7 ? null : _skipToEnd,
                                  child: Text(
                                    'Skip',
                                    style: AppText.body(
                                      12,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.orangePrimary,
                                    ),
                                  )
                                : PageView(
                                    controller: _pageController,
                                    physics: const BouncingScrollPhysics(),
                                    onPageChanged: (i) {
                                      setState(() => _index = i);
                                    },
                                    children: [
                                      _OpeningSlide(
                                        year: widget.year,
                                        onTap: _next,
                                      ),
                                      _BooksReadSlide(
                                        data: data,
                                        onTap: _next,
                                        repo: _repo,
                                      ),
                                      _PagesSlide(
                                        data: data,
                                        onTap: _next,
                                      ),
                                      _TopTropeSlide(
                                        data: data,
                                        onTap: _next,
                                      ),
                                      _FavouriteBookSlide(
                                        data: data,
                                        onTap: _next,
                                        onStarsDone: () {
                                          if (!_skipped) _confetti.play();
                                        },
                                      ),
                                      _StreakSlide(
                                        data: data,
                                        onTap: _next,
                                      ),
                                      _SocialSlide(
                                        data: data,
                                        onTap: _next,
                                      ),
                                      _ShareCardSlide(
                                        key: _shareCardKey,
                                        year: widget.year,
                                        data: data,
                                        onShare: _shareCard,
                                        onReplay: () {
                                          setState(() => _skipped = false);
                                          _goTo(0);
                                        },
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confetti,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.12,
                    numberOfParticles: 16,
                    colors: const [
                      AppColors.orangePrimary,
                      AppColors.orangeAmber,
                      AppColors.orangeBright,
                      Colors.white,
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class WrappedData {
  final int year;
  final int booksRead;
  final int pagesRead;
  final int longestStreak;
  final Book? favouriteBook;
  final String topTrope;
  final List<String> topTropes;
  final List<Book> allReadBooks;
  final int reviewsWritten;
  final int followersGained;
  final int reviewLikes;
  final Map<int, int> monthlyReads;

  const WrappedData({
    required this.year,
    required this.booksRead,
    required this.pagesRead,
    required this.longestStreak,
    required this.favouriteBook,
    required this.topTrope,
    required this.topTropes,
    required this.allReadBooks,
    required this.reviewsWritten,
    required this.followersGained,
    required this.reviewLikes,
    required this.monthlyReads,
  });

  static Future<WrappedData> fetchForYear(String userId, int year) async {
    final client = SupabaseConfig.client;
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    // Read books finished in the year.
    final userBooksRows = await client
        .from('user_books')
        .select('book_id, star_rating, date_finished, status')
        .eq('user_id', userId)
        .eq('status', 'read')
        .gte('date_finished', start.toIso8601String())
        .lt('date_finished', end.toIso8601String());

    final userBooks = (userBooksRows as List)
        .cast<Map<String, dynamic>>()
        .where((r) => r['book_id'] != null)
        .toList();

    final bookIds = userBooks.map((r) => r['book_id'] as String).toList();

    // Monthly counts.
    final monthly = <int, int>{for (int m = 1; m <= 12; m++) m: 0};
    for (final row in userBooks) {
      final finished = row['date_finished'] as String?;
      if (finished == null) continue;
      final dt = DateTime.tryParse(finished);
      if (dt == null) continue;
      monthly[dt.month] = (monthly[dt.month] ?? 0) + 1;
    }

    // Book metadata from cache table.
    final booksById = <String, Book>{};
    if (bookIds.isNotEmpty) {
      try {
        final bookRows = await client
            .from('books')
            .select()
            .inFilter('id', bookIds);
        for (final r in (bookRows as List).cast<Map<String, dynamic>>()) {
          final b = Book.fromSupabase(r);
          booksById[b.id] = b;
        }
      } catch (_) {
        // Best-effort: leave empty, UI will degrade gracefully.
      }
    }

    final allReadBooks = bookIds
        .map((id) => booksById[id])
        .whereType<Book>()
        .toList();

    // Favourite book: highest star rating among finished books.
    Book? favourite;
    final topRated = userBooks
        .where((r) => r['star_rating'] != null)
        .toList()
      ..sort((a, b) {
        final ar = (a['star_rating'] as num?)?.toDouble() ?? 0;
        final br = (b['star_rating'] as num?)?.toDouble() ?? 0;
        return br.compareTo(ar);
      });
    if (topRated.isNotEmpty) {
      final favId = topRated.first['book_id'] as String;
      favourite = booksById[favId];
    }

    // Pages read: sum pages_read in reading_sessions in the year.
    int pagesRead = 0;
    try {
      final sessions = await client
          .from('reading_sessions')
          .select('ended_at, pages_read')
          .eq('user_id', userId)
          .gte('ended_at', start.toIso8601String())
          .lt('ended_at', end.toIso8601String());
      for (final s in (sessions as List).cast<Map<String, dynamic>>()) {
        pagesRead += (s['pages_read'] as int?) ?? 0;
      }
    } catch (_) {
      // Fallback: approximate by summing page counts of finished books.
      pagesRead = allReadBooks.fold<int>(
        0,
        (sum, b) => sum + (b.pageCount ?? 0),
      );
    }

    // Longest reading streak in the year (based on any session end date).
    int longestStreak = 0;
    try {
      final sessions = await client
          .from('reading_sessions')
          .select('ended_at')
          .eq('user_id', userId)
          .gte('ended_at', start.toIso8601String())
          .lt('ended_at', end.toIso8601String())
          .order('ended_at', ascending: true);

      final days = <DateTime>{};
      for (final s in (sessions as List).cast<Map<String, dynamic>>()) {
        final endedAt = s['ended_at'] as String?;
        final dt = endedAt == null ? null : DateTime.tryParse(endedAt);
        if (dt == null) continue;
        days.add(DateTime(dt.year, dt.month, dt.day));
      }
      final sorted = days.toList()..sort();
      int run = 0;
      DateTime? prev;
      for (final d in sorted) {
        if (prev == null) {
          run = 1;
        } else {
          final delta = d.difference(prev).inDays;
          run = delta == 1 ? run + 1 : 1;
        }
        prev = d;
        longestStreak = max(longestStreak, run);
      }
    } catch (_) {
      longestStreak = 0;
    }

    // Top tropes: from book_tags if present, else fallback to genres on cached books.
    final tropeCounts = <String, int>{};
    if (bookIds.isNotEmpty) {
      try {
        final rows = await client
            .from('book_tags')
            .select()
            .inFilter('book_id', bookIds);

        for (final r in (rows as List).cast<Map<String, dynamic>>()) {
          final tag = (r['tag'] ?? r['trope'] ?? r['name']) as String?;
          if (tag == null) continue;
          final t = tag.trim();
          if (t.isEmpty) continue;
          tropeCounts[t] = (tropeCounts[t] ?? 0) + 1;
        }
      } catch (_) {
        // ignore
      }
    }
    if (tropeCounts.isEmpty) {
      for (final b in allReadBooks) {
        for (final g in b.genres) {
          final t = g.trim();
          if (t.isEmpty) continue;
          tropeCounts[t] = (tropeCounts[t] ?? 0) + 1;
        }
      }
    }
    final sortedTropes = tropeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTropes = sortedTropes.take(3).map((e) => e.key).toList();
    final topTrope = topTropes.isNotEmpty ? topTropes.first : 'Bookish chaos';

    // Social: reviews in the year.
    int reviewsWritten = 0;
    int reviewLikes = 0;
    try {
      final reviewRows = await client
          .from('reviews')
          .select('id, likes_count, created_at')
          .eq('user_id', userId)
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String());
      reviewsWritten = (reviewRows as List).length;
      for (final r in (reviewRows as List).cast<Map<String, dynamic>>()) {
        reviewLikes += (r['likes_count'] as int?) ?? 0;
      }
    } catch (_) {
      reviewsWritten = 0;
      reviewLikes = 0;
    }

    // Followers gained: follows where following_id == me.
    int followersGained = 0;
    try {
      final followerRows = await client
          .from('follows')
          .select('id, created_at')
          .eq('following_id', userId)
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String());
      followersGained = (followerRows as List).length;
    } catch (_) {
      followersGained = 0;
    }

    return WrappedData(
      year: year,
      booksRead: bookIds.length,
      pagesRead: pagesRead,
      longestStreak: longestStreak,
      favouriteBook: favourite,
      topTrope: topTrope,
      topTropes: topTropes,
      allReadBooks: allReadBooks,
      reviewsWritten: reviewsWritten,
      followersGained: followersGained,
      reviewLikes: reviewLikes,
      monthlyReads: monthly,
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int index;
  final int count;
  const _ProgressDots({required this.index, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final selected = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(right: 6),
          width: selected ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? AppColors.orangePrimary
                : Colors.white.withOpacity(0.18),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.orangePrimary.withOpacity(0.4),
                      blurRadius: 12,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _OrangeParticleField extends StatelessWidget {
  final double progress;
  const _OrangeParticleField({required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OrangeParticlePainter(progress: progress),
    );
  }
}

class _OrangeParticlePainter extends CustomPainter {
  final double progress;
  final _rng = Random(7);

  _OrangeParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final count = 42;
    for (int i = 0; i < count; i++) {
      final x0 = _rng.nextDouble();
      final y0 = _rng.nextDouble();
      final drift = (sin((progress * 2 * pi) + i) + 1) / 2;
      final x = (x0 * size.width) + (drift * 18 - 9);
      final y = (y0 * size.height) - (progress * 70) + (i % 3) * 18;
      final opacity = 0.10 + 0.10 * (1 - y0);
      final radius = 1.2 + (i % 4) * 0.9;
      final paint = Paint()
        ..color = AppColors.orangePrimary.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(
        Offset(x % size.width, (y % size.height)),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrangeParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _OpeningSlide extends StatelessWidget {
  final int year;
  final VoidCallback onTap;
  const _OpeningSlide({required this.year, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$year',
                  style: AppText.display(72, context: context).copyWith(
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(
                        color: AppColors.orangeGlow,
                        blurRadius: 30,
                      )
                    ],
                  ),
                ).animate().fadeIn(duration: 900.ms),
                const SizedBox(height: 6),
                Text(
                  'Your year in books',
                  style: AppText.script(28).copyWith(
                    color: Colors.white.withOpacity(0.9),
                    shadows: const [
                      Shadow(
                        color: AppColors.orangePrimary,
                        blurRadius: 20,
                      )
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 800.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 26),
              child: Text(
                'Tap to begin ✦',
                style: AppText.body(
                  13,
                  color: Colors.white.withOpacity(0.55),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 650.ms)
                  .fadeOut(duration: 650.ms),
            ),
          ),
        ],
      ),
    );
  }
}

class _BooksReadSlide extends StatelessWidget {
  final WrappedData? data;
  final VoidCallback onTap;
  final BookRepository repo;
  const _BooksReadSlide({
    required this.data,
    required this.onTap,
    required this.repo,
  });

  @override
  Widget build(BuildContext context) {
    final booksRead = data?.booksRead ?? 0;
    final thumbs = data?.allReadBooks.take(24).toList() ?? const <Book>[];
    final lastYear = (data?.year ?? DateTime.now().year) - 1;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            _CountUpNumber(
              value: booksRead,
              textStyle: AppText.display(96, context: context).copyWith(
                color: AppColors.orangePrimary,
                shadows: const [
                  Shadow(color: AppColors.orangeGlow, blurRadius: 28),
                ],
              ),
              duration: const Duration(milliseconds: 900),
            ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.95, 0.95),
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 6),
            Text(
              'books read this year',
              style: AppText.bodySemiBold(
                15,
                color: Colors.white.withOpacity(0.85),
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 450.ms),
            const SizedBox(height: 6),
            Text(
              booksRead == 0
                  ? 'Next chapter starts now.'
                  : 'That’s ${max(1, (booksRead / 12).round())} books a month ✦',
              style: AppText.body(
                13,
                color: Colors.white.withOpacity(0.55),
              ),
            ).animate().fadeIn(delay: 130.ms, duration: 450.ms),
            const SizedBox(height: 18),
            if (thumbs.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'No finished books recorded for $lastYear–${data?.year ?? widgetYear(context)} yet.',
                  style: AppText.body(13, context: context),
                ),
              )
                  .animate()
                  .fadeIn(delay: 180.ms, duration: 450.ms)
                  .scale(begin: const Offset(0.98, 0.98))
            else
              SizedBox(
                height: 120,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(thumbs.length, (i) {
                    final b = thumbs[i];
                    return _TinyCover(b: b)
                        .animate()
                        .fadeIn(
                          delay: (160 + 35 * i).ms,
                          duration: 280.ms,
                        )
                        .slide(
                          begin: Offset(
                            (i % 3 - 1) * 0.25,
                            (i % 2 == 0 ? 0.4 : -0.4),
                          ),
                          end: Offset.zero,
                          curve: Curves.easeOutCubic,
                        );
                  }),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  int widgetYear(BuildContext context) =>
      DateTime.now().year; // only for fallback copy above
}

class _TinyCover extends StatelessWidget {
  final Book b;
  const _TinyCover({required this.b});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 34,
        height: 52,
        child: b.coverUrl == null
            ? Container(
                color: AppColors.darkCard,
                alignment: Alignment.center,
                child: const Text('✦'),
              )
            : Image.network(b.coverUrl!, fit: BoxFit.cover),
      ),
    );
  }
}

class _PagesSlide extends StatelessWidget {
  final WrappedData? data;
  final VoidCallback onTap;
  const _PagesSlide({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pages = data?.pagesRead ?? 0;
    final formatted = NumberFormat.decimalPattern().format(pages);
    final warAndPeace = pages > 0 ? max(1, (pages / 1225).floor()) : 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PageTurnPainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You turned',
                  style: AppText.bodySemiBold(
                    16,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 10),
                _CountUpText(
                  formattedValue: formatted,
                  rawValue: pages,
                  style: AppText.display(80, context: context).copyWith(
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: AppColors.orangeGlow, blurRadius: 24),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 90.ms, duration: 520.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
                Text(
                  'pages',
                  style: AppText.bodySemiBold(
                    16,
                    color: AppColors.orangePrimary.withOpacity(0.95),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 420.ms)
                    .slideY(begin: 0.15, end: 0),
                const SizedBox(height: 12),
                Text(
                  warAndPeace > 0
                      ? 'That’s like reading War & Peace $warAndPeace times'
                      : 'Enough pages to build a tower taller than you.',
                  style: AppText.body(
                    13,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ).animate().fadeIn(delay: 220.ms, duration: 420.ms),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTurnPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x00FF6B1A),
          Color(0x22FF6B1A),
          Color(0x00000000),
        ],
      ).createShader(Offset.zero & size);

    final path = Path()
      ..moveTo(size.width * 0.55, 0)
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.25,
        size.width * 0.65,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.8,
        size.width * 0.7,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopTropeSlide extends StatelessWidget {
  final WrappedData? data;
  final VoidCallback onTap;
  const _TopTropeSlide({required this.data, required this.onTap});

  String _emojiFor(String trope) {
    final t = trope.toLowerCase();
    if (t.contains('romance')) return '💘';
    if (t.contains('dark')) return '🖤';
    if (t.contains('fantasy') || t.contains('magic')) return '✨';
    if (t.contains('thriller') || t.contains('mystery')) return '🕵️';
    if (t.contains('cozy')) return '☕️';
    return '📚';
  }

  @override
  Widget build(BuildContext context) {
    final top = data?.topTrope ?? 'Bookish chaos';
    final top3 = data?.topTropes ?? const <String>[];
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your reading personality...',
              style: AppText.bodySemiBold(
                15,
                color: Colors.white.withOpacity(0.75),
              ),
            ).animate().fadeIn(duration: 520.ms),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  _emojiFor(top),
                  style: const TextStyle(fontSize: 44),
                ).animate().fadeIn(duration: 520.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    top,
                    style: AppText.script(34).copyWith(
                      color: AppColors.orangePrimary,
                      shadows: const [
                        Shadow(color: AppColors.orangeGlow, blurRadius: 28),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 520.ms)
                      .slideX(begin: -0.05, end: 0),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data == null
                  ? 'Summoning your vibe...'
                  : 'You read ${data!.booksRead} books tagged $top this year',
              style: AppText.body(13, color: Colors.white.withOpacity(0.55)),
            ).animate().fadeIn(delay: 140.ms, duration: 520.ms),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: top3.isEmpty
                  ? [
                      _GlowChip(label: top),
                    ]
                  : top3.map((t) => _GlowChip(label: t)).toList(),
            ).animate().fadeIn(delay: 220.ms, duration: 520.ms),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _GlowChip extends StatelessWidget {
  final String label;
  const _GlowChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.orangePrimary.withOpacity(0.5)),
        color: AppColors.darkCard.withOpacity(0.55),
        boxShadow: [
          BoxShadow(
            color: AppColors.orangePrimary.withOpacity(0.18),
            blurRadius: 18,
          )
        ],
      ),
      child: Text(
        label,
        style: AppText.bodySemiBold(
          12,
          color: Colors.white.withOpacity(0.85),
        ),
      ),
    );
  }
}

class _FavouriteBookSlide extends StatelessWidget {
  final WrappedData? data;
  final VoidCallback onTap;
  final VoidCallback onStarsDone;
  const _FavouriteBookSlide({
    required this.data,
    required this.onTap,
    required this.onStarsDone,
  });

  @override
  Widget build(BuildContext context) {
    final b = data?.favouriteBook;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your book of the year...',
              style: AppText.bodySemiBold(
                15,
                color: Colors.white.withOpacity(0.75),
              ),
            ).animate().fadeIn(duration: 520.ms),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: b == null
                    ? GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No top-rated book yet — rate a finished read to crown one.',
                          style: AppText.body(13, context: context),
                          textAlign: TextAlign.center,
                        ),
                      )
                        .animate()
                        .fadeIn(delay: 80.ms, duration: 520.ms)
                        .scale(begin: const Offset(0.98, 0.98))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Hero(
                            tag: 'wrapped_favourite_${b.id}',
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.62,
                              constraints: const BoxConstraints(maxWidth: 340),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.orangePrimary.withOpacity(0.25),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: b.coverUrl != null
                                    ? Image.network(b.coverUrl!, fit: BoxFit.cover)
                                    : const BookCoverWidget(width: 200, height: 280),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 80.ms, duration: 620.ms)
                              .scale(
                                begin: const Offset(0.85, 0.85),
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: 16),
                          Text(
                            b.title,
                            style: AppText.display(20, context: context).copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ).animate().fadeIn(delay: 120.ms, duration: 500.ms),
                          const SizedBox(height: 4),
                          Text(
                            b.author,
                            style: AppText.body(
                              13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ).animate().fadeIn(delay: 150.ms, duration: 450.ms),
                          const SizedBox(height: 12),
                          _AnimatedStars(
                            onFinished: onStarsDone,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedStars extends StatefulWidget {
  final VoidCallback onFinished;
  const _AnimatedStars({required this.onFinished});

  @override
  State<_AnimatedStars> createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<_AnimatedStars> {
  int _filled = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      setState(() => _filled = i);
      HapticFeedback.lightImpact();
    }
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < _filled;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? AppColors.orangeAmber : Colors.white.withOpacity(0.28),
            size: 26,
            shadows: filled
                ? const [
                    Shadow(color: AppColors.orangeGlow, blurRadius: 16),
                  ]
                : null,
          )
              .animate(target: filled ? 1 : 0)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
                duration: 220.ms,
              ),
        );
      }),
    );
  }
}

class _StreakSlide extends StatelessWidget {
  final WrappedData? data;
  final VoidCallback onTap;
  const _StreakSlide({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final streak = data?.longestStreak ?? 0;
    final months = data?.monthlyReads ?? const <int, int>{};

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your longest streak',
              style: AppText.bodySemiBold(
                15,
                color: Colors.white.withOpacity(0.75),
              ),
            ).animate().fadeIn(duration: 520.ms),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 44))
                    .animate()
                    .fadeIn(duration: 520.ms)
                    .slideY(begin: 0.2, end: 0)
                    .then()
                    .shake(duration: 400.ms),
                const SizedBox(width: 14),
                Expanded(
                  child: _CountUpNumber(
                    value: streak,
                    textStyle: AppText.display(48, context: context).copyWith(
                      color: Colors.white,
                    ),
                    suffix: ' days',
                    duration: const Duration(milliseconds: 900),
                  )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 520.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'of unbroken reading magic',
              style: AppText.body(
                13,
                color: Colors.white.withOpacity(0.55),
              ),
            ).animate().fadeIn(delay: 140.ms, duration: 520.ms),
            const SizedBox(height: 18),
            _MiniHeatmap(monthlyReads: months)
                .animate()
                .fadeIn(delay: 200.ms, duration: 520.ms)
                .scale(begin: const Offset(0.98, 0.98)),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _MiniHeatmap extends StatelessWidget {
  final Map<int, int> monthlyReads;
  const _MiniHeatmap({required this.monthlyReads});

  @override
  Widget build(BuildContext context) {
    final maxValue = monthlyReads.values.fold<int>(0, (m, v) => max(m, v));
    Color cellColor(int value) {
      if (value <= 0) return Colors.white.withOpacity(0.08);
      final t = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
      return Color.lerp(
            AppColors.orangeDeep.withOpacity(0.35),
            AppColors.orangePrimary,
            t,
          ) ??
          AppColors.orangePrimary;
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading activity',
            style: AppText.bodySemiBold(13, context: context),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(12, (i) {
              final m = i + 1;
              final v = monthlyReads[m] ?? 0;
              return Expanded(
                child: Container(
                  height: 26,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: cellColor(v),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    DateFormat.MMM().format(DateTime(2000, m, 1)).substring(0, 1),
                    style: AppText.body(
                      10,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SocialSlide extends StatelessWidget {
  final WrappedData? data;
  final VoidCallback onTap;
  const _SocialSlide({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final reviews = data?.reviewsWritten ?? 0;
    final followers = data?.followersGained ?? 0;
    final likes = data?.reviewLikes ?? 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You weren’t reading alone',
              style: AppText.display(20, context: context).copyWith(
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 520.ms),
            const SizedBox(height: 16),
            _StatLine(
              label: 'Reviews written',
              value: reviews,
              delayMs: 80,
            ),
            const SizedBox(height: 10),
            _StatLine(
              label: 'Followers gained',
              value: followers,
              delayMs: 120,
            ),
            const SizedBox(height: 10),
            _StatLine(
              label: 'Likes on your reviews',
              value: likes,
              delayMs: 160,
            ),
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Text(
                likes > 0
                    ? 'Your reviews got $likes likes from the community ✦'
                    : 'Your next review could be someone’s next favourite read.',
                style: AppText.body(13, context: context),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 520.ms),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final int value;
  final int delayMs;
  const _StatLine({
    required this.label,
    required this.value,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppText.body(
              13,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ),
        _CountUpNumber(
          value: value,
          textStyle: AppText.display(22, context: context).copyWith(
            color: AppColors.orangePrimary,
          ),
          duration: const Duration(milliseconds: 700),
        ),
      ],
    ).animate().fadeIn(delay: delayMs.ms, duration: 420.ms).slideY(
          begin: 0.08,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }
}

class _ShareCardSlide extends StatelessWidget {
  final int year;
  final WrappedData? data;
  final VoidCallback onShare;
  final VoidCallback onReplay;

  const _ShareCardSlide({
    super.key,
    required this.year,
    required this.data,
    required this.onShare,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final d = data;
    final books = d?.booksRead ?? 0;
    final pages = d?.pagesRead ?? 0;
    final streak = d?.longestStreak ?? 0;
    final top = d?.topTrope ?? 'Bookish chaos';
    final covers = d?.allReadBooks.take(9).toList() ?? const <Book>[];
    final username =
        SupabaseConfig.client.auth.currentUser?.email?.split('@').first ??
            'pagewalker';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
      child: Column(
        children: [
          Text(
            'Your $year Pagewalker Wrapped',
            style: AppText.script(26).copyWith(
              color: Colors.white.withOpacity(0.9),
              shadows: const [Shadow(color: AppColors.orangeGlow, blurRadius: 22)],
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 520.ms),
          const SizedBox(height: 14),
          RepaintBoundary(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF050505),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.orangePrimary.withOpacity(0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orangePrimary.withOpacity(0.18),
                      blurRadius: 26,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.55,
                        child: CustomPaint(painter: _CardSparklePainter()),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Pagewalker',
                              style: AppText.script(18).copyWith(
                                color: AppColors.orangePrimary,
                                shadows: const [
                                  Shadow(color: AppColors.orangeGlow, blurRadius: 18),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$year Wrapped',
                              style: AppText.bodySemiBold(
                                12,
                                color: Colors.white.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _CoverGrid9(books: covers),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _CardStat(label: 'books', value: books),
                            const SizedBox(width: 10),
                            _CardStat(label: 'pages', value: pages),
                            const SizedBox(width: 10),
                            _CardStat(label: 'streak', value: streak),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'My reading personality: $top',
                          style: AppText.displayItalic(14).copyWith(
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '@$username',
                            style: AppText.body(
                              12,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 80.ms, duration: 520.ms).scale(
                begin: const Offset(0.98, 0.98),
              ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Share my Wrapped',
            width: double.infinity,
            onPressed: onShare,
          ).animate().fadeIn(delay: 140.ms, duration: 420.ms),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onShare,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orangePrimary,
              side: BorderSide(
                color: AppColors.orangePrimary.withOpacity(0.45),
              ),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Save to Gallery'),
          ).animate().fadeIn(delay: 160.ms, duration: 420.ms),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onReplay,
            child: Text(
              'Replay',
              style: AppText.body(
                12,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ).animate().fadeIn(delay: 190.ms, duration: 420.ms),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label;
  final int value;
  const _CardStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Text(
              NumberFormat.compact().format(value),
              style: AppText.bodySemiBold(
                15,
                color: AppColors.orangePrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppText.body(
                11,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverGrid9 extends StatelessWidget {
  final List<Book> books;
  const _CoverGrid9({required this.books});

  @override
  Widget build(BuildContext context) {
    final shown = books.take(9).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, i) {
        final b = i < shown.length ? shown[i] : null;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: AppColors.darkCard.withOpacity(0.8),
            child: b?.coverUrl == null
                ? Center(
                    child: Text(
                      '✦',
                      style: AppText.display(18, context: context).copyWith(
                        color: AppColors.orangePrimary.withOpacity(0.6),
                      ),
                    ),
                  )
                : Image.network(b!.coverUrl!, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

class _CardSparklePainter extends CustomPainter {
  final _rng = Random(99);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 28; i++) {
      final dx = _rng.nextDouble() * size.width;
      final dy = _rng.nextDouble() * size.height;
      final r = 0.8 + _rng.nextDouble() * 1.8;
      final paint = Paint()
        ..color = AppColors.orangePrimary.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CountUpNumber extends StatefulWidget {
  final int value;
  final TextStyle textStyle;
  final Duration duration;
  final String? suffix;

  const _CountUpNumber({
    required this.value,
    required this.textStyle,
    required this.duration,
    this.suffix,
  });

  @override
  State<_CountUpNumber> createState() => _CountUpNumberState();
}

class _CountUpNumberState extends State<_CountUpNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        final v = (widget.value * _a.value).round();
        final suffix = widget.suffix ?? '';
        return Text(
          '$v$suffix',
          style: widget.textStyle,
        );
      },
    );
  }
}

class _CountUpText extends StatefulWidget {
  final String formattedValue;
  final int rawValue;
  final TextStyle style;
  const _CountUpText({
    required this.formattedValue,
    required this.rawValue,
    required this.style,
  });

  @override
  State<_CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<_CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        final current = (widget.rawValue * _a.value).round();
        final display = NumberFormat.decimalPattern().format(current);
        return Text(display, style: widget.style);
      },
    );
  }
}

