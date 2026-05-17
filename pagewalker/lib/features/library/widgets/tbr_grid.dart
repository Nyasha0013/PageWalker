import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/book_cover_widget.dart';
import '../../../data/models/book.dart';
import '../../../data/models/user_book.dart';
import '../../../data/repositories/user_book_repository.dart';

class TbrGrid extends StatefulWidget {
  const TbrGrid({super.key});

  @override
  State<TbrGrid> createState() => _TbrGridState();
}

class _TbrGridState extends State<TbrGrid> {
  final _repo = UserBookRepository();
  List<Book> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final books = await _repo.getBooksForStatus(user.id, BookStatus.tbr);
    if (mounted) {
      setState(() {
        _books = books;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        child: Text(
          'Your TBR is empty. Search in Discover or scan a book to add titles.',
          textAlign: TextAlign.center,
          style: AppText.body(14, context: context),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            itemCount: _books.length,
            gridDelegate: const SliverMasonryGridDelegate(
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              crossAxisCount: 2,
            ),
            itemBuilder: (context, index) {
              final book = _books[index];
              final height = index.isEven ? 170.0 : 200.0;
              return Align(
                alignment: Alignment.topCenter,
                child: BookCoverWidget(
                  width: (constraints.maxWidth - 12) / 2,
                  height: height,
                  title: book.title,
                  coverUrl: book.coverUrl,
                  heroTag: 'book-cover-${book.id}',
                  onTap: () {
                    context.push('/book/${Uri.encodeComponent(book.id)}');
                  },
                )
                    .animate()
                    .fadeIn(
                      delay: (index * 60).ms,
                      duration: 400.ms,
                    )
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
              );
            },
          );
        },
      ),
    );
  }
}

class SliverMasonryGridDelegate extends SliverGridDelegate {
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const SliverMasonryGridDelegate({
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
  });

  @override
  SliverGridLayout getLayout(
    SliverConstraints constraints,
  ) {
    final usableCrossAxisExtent = constraints.crossAxisExtent -
        (crossAxisCount - 1) * crossAxisSpacing;
    final crossAxisStride =
        usableCrossAxisExtent / crossAxisCount + crossAxisSpacing;

    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: 200 + mainAxisSpacing,
      crossAxisStride: crossAxisStride,
      childMainAxisExtent: 200,
      childCrossAxisExtent: usableCrossAxisExtent / crossAxisCount,
      reverseCrossAxis: axisDirectionIsReversed(
        constraints.crossAxisDirection,
      ),
    );
  }

  @override
  bool shouldRelayout(
    covariant SliverMasonryGridDelegate oldDelegate,
  ) {
    return oldDelegate.crossAxisCount != crossAxisCount ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing;
  }
}
