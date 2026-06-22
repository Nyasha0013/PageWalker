import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/book_cover_widget.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/services/widget_service.dart';
import '../../../data/models/book.dart';
import '../../../data/models/user_book.dart';
import '../../../data/repositories/user_book_repository.dart';

class CurrentlyReadingTab extends StatefulWidget {
  const CurrentlyReadingTab({super.key});

  @override
  State<CurrentlyReadingTab> createState() => _CurrentlyReadingTabState();
}

class _CurrentlyReadingTabState extends State<CurrentlyReadingTab> {
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
    final rows =
        await _repo.getShelfEntries(user.id, BookStatus.reading);
    if (mounted) {
      setState(() {
        _entries = rows;
        _loading = false;
      });
      if (rows.isNotEmpty) {
        final book = rows.first.$2;
        await WidgetService.syncCurrentRead(
          book: book,
          totalPages: book.pageCount ?? 0,
        );
      } else {
        await WidgetService.clearCurrentRead();
      }
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
            'Nothing in “Reading” yet. Move a book here from TBR or add one from Discover.',
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
        final book = _entries[index].$2;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                BookCoverWidget(
                  width: 60,
                  height: 90,
                  title: book.title,
                  coverUrl: book.coverUrl,
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
                        style: AppText.body(
                          13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: 0.35,
                          minHeight: 6,
                          backgroundColor: AppColors.darkSurface,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.orangePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GradientButton(
                      label: '▶ Timer',
                      height: 40,
                      width: 112,
                      onPressed: () => context.push('/timer/${book.id}'),
                    ),
                    const SizedBox(height: 8),
                    GradientButton(
                      label: 'Update',
                      height: 40,
                      width: 112,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
