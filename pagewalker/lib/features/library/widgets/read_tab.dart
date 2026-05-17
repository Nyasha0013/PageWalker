import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/book_cover_widget.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/book.dart';
import '../../../data/models/user_book.dart';
import '../../../data/repositories/user_book_repository.dart';

class ReadTab extends StatefulWidget {
  const ReadTab({super.key});

  @override
  State<ReadTab> createState() => _ReadTabState();
}

class _ReadTabState extends State<ReadTab> {
  final _repo = UserBookRepository();
  List<(UserBook, Book)> _entries = [];
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
    final rows = await _repo.getShelfEntries(user.id, BookStatus.read);
    if (mounted) {
      setState(() {
        _entries = rows;
        _loading = false;
      });
    }
  }

  String _tierLabel(BookTier? t) {
    switch (t) {
      case BookTier.godTier:
        return 'God Tier';
      case BookTier.aClass:
        return 'A Class';
      case BookTier.bClass:
        return 'B Class';
      case BookTier.cClass:
      case null:
        return 'C Class';
    }
  }

  Color _tierColor(BookTier? t) {
    switch (t) {
      case BookTier.godTier:
        return AppColors.tierGod;
      case BookTier.aClass:
        return AppColors.tierA;
      case BookTier.bClass:
        return AppColors.tierB;
      case BookTier.cClass:
      case null:
        return AppColors.tierC;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No finished books yet. When you finish a read, mark it here.',
            textAlign: TextAlign.center,
            style: AppText.body(14, context: context),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final ub = _entries[index].$1;
        final book = _entries[index].$2;
        final tierLabel = _tierLabel(ub.tier);
        final tierColor = _tierColor(ub.tier);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: InkWell(
              onTap: () => context.push('/book/${Uri.encodeComponent(book.id)}'),
              child: Row(
                children: [
                  Stack(
                    children: [
                      BookCoverWidget(
                        width: 60,
                        height: 90,
                        title: book.title,
                        coverUrl: book.coverUrl,
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: tierColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: AppText.bodySemiBold(15, context: context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: AppText.body(13, context: context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Placed in $tierLabel',
                          style: AppText.body(
                            13,
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
        );
      },
    );
  }
}
