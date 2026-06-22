import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/utils/url_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/book_cover_widget.dart';
import '../../core/widgets/themed_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/catalog_book.dart';
import '../../data/repositories/catalog_book_repository.dart';

class BookSearchScreen extends StatefulWidget {
  final String? initialTopic;

  const BookSearchScreen({super.key, this.initialTopic});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final _repo = CatalogBookRepository();
  final _searchCtrl = TextEditingController();

  List<CatalogBook> _results = [];
  bool _loading = false;
  bool _browsing = false;
  BookSource? _sourceFilter;
  String _lastQuery = '';

  List<CatalogBook> get _filtered {
    var list = _results;
    if (_sourceFilter != null) {
      list = list.where((b) => b.source == _sourceFilter).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final t = widget.initialTopic;
      if (t != null && t.isNotEmpty) {
        _browseGenre(kCatalogGenreMap[t] ?? t);
      } else {
        _loadPopular();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPopular() async {
    setState(() {
      _loading = true;
      _browsing = false;
    });
    final list = await _repo.getPopularMixed(limit: 30);
    if (!mounted) return;
    setState(() {
      _results = list;
      _loading = false;
    });
  }

  Future<void> _browseGenre(String genreKey) async {
    setState(() {
      _loading = true;
      _browsing = true;
    });
    final list = await _repo.browseByGenre(genreKey);
    if (!mounted) return;
    setState(() {
      _results = list;
      _loading = false;
    });
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _browsing = false;
      _lastQuery = q;
    });
    final list = await _repo.searchAll(q);
    if (!mounted) return;
    setState(() {
      _results = list;
      _loading = false;
    });
  }

  void _openBook(CatalogBook b) {
    context.push(
      '/book/${Uri.encodeComponent(b.id)}',
      extra: b,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Search books',
                        style: AppText.display(24, context: context),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _runSearch(),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search any book, author, or series...',
                      border: InputBorder.none,
                      icon: Icon(
                        Icons.search_rounded,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : IconButton(
                              icon: const Icon(Icons.arrow_forward_rounded),
                              onPressed: _runSearch,
                            ),
                    ),
                    style: AppText.body(14),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All sources'),
                      selected: _sourceFilter == null,
                      onSelected: (_) => setState(() => _sourceFilter = null),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Gutenberg'),
                      selected: _sourceFilter == BookSource.gutenberg,
                      onSelected: (_) => setState(
                        () => _sourceFilter = BookSource.gutenberg,
                      ),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Google'),
                      selected: _sourceFilter == BookSource.googleBooks,
                      onSelected: (_) => setState(
                        () => _sourceFilter = BookSource.googleBooks,
                      ),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Open Library'),
                      selected: _sourceFilter == BookSource.openLibrary,
                      onSelected: (_) => setState(
                        () => _sourceFilter = BookSource.openLibrary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_browsing && _lastQuery.isEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Explore by genre',
                    style: AppText.bodySemiBold(13, context: context),
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: kCatalogGenreMap.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(e.key),
                          onPressed: () => _browseGenre(e.value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (_lastQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    'Results for “$_lastQuery”',
                    style: AppText.bodySemiBold(13, context: context),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? _EmptyState(onPopular: _loadPopular)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            children: [
                              _BookGrid(
                                books: _filtered,
                                onOpen: _openBook,
                              ),
                            ],
                          ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                child: Text(
                  Env.hasGoogleBooksCatalog
                      ? 'Metadata from Google Books, Open Library, and Project Gutenberg.'
                      : 'Showing Open Library and Project Gutenberg. Google Books is off in this build.',
                  style: AppText.body(
                    11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                    context: context,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  final List<CatalogBook> books;
  final void Function(CatalogBook) onOpen;

  const _BookGrid({
    required this.books,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.58,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final b = books[index];
        return _CatalogBookCard(
          book: b,
          onTap: () => onOpen(b),
        ).animate().fadeIn(delay: (index * 25).ms, duration: 350.ms);
      },
    );
  }
}

class _CatalogBookCard extends StatelessWidget {
  final CatalogBook book;
  final VoidCallback onTap;

  const _CatalogBookCard({
    required this.book,
    required this.onTap,
  });

  Color _sourceDot() {
    switch (book.source) {
      case BookSource.gutenberg:
        return AppColors.orangePrimary;
      case BookSource.googleBooks:
        return Colors.blueAccent;
      case BookSource.openLibrary:
        return Colors.greenAccent.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: fixCoverUrl(book.coverUrl) ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorWidget: (_, __, ___) => BookCoverWidget(
                                title: book.title,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : BookCoverWidget(
                              title: book.title,
                              width: double.infinity,
                              height: double.infinity,
                            ),
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
                            color: _sourceDot(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          book.source == BookSource.gutenberg
                              ? 'PG'
                              : book.source == BookSource.googleBooks
                                  ? 'GB'
                                  : 'OL',
                          style: AppText.label(9, context: context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(13, context: context),
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                context: context,
              ),
            ),
            if (book.publishedYear != null)
              Text(
                '${book.publishedYear}',
                style: AppText.body(
                  10,
                  color: isDark
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
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onPopular;

  const _EmptyState({required this.onPopular});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Search for any book',
              style: AppText.display(20, context: context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onPopular,
              child: const Text('Show popular classics'),
            ),
          ],
        ),
      ),
    );
  }
}
