import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/book_cover_widget.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/book.dart';
import '../../../data/models/user_book.dart';
import '../../../data/repositories/user_book_repository.dart';

class DnfTab extends StatefulWidget {
  const DnfTab({super.key});

  @override
  State<DnfTab> createState() => _DnfTabState();
}

class _DnfTabState extends State<DnfTab> {
  final _repo = UserBookRepository();
  final _maybeReturn = <int, bool>{};
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
    final rows = await _repo.getShelfEntries(user.id, BookStatus.dnf);
    if (mounted) {
      setState(() {
        _entries = rows;
        _loading = false;
      });
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
            'No DNF books. Life’s too short — but you haven’t shelved any here yet.',
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
        final checked = _maybeReturn[index] ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BookCoverWidget(
                      width: 52,
                      height: 78,
                      title: book.title,
                      coverUrl: book.coverUrl,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        book.title,
                        style: AppText.bodySemiBold(15, context: context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    checked
                        ? 'Maybe we just met at the wrong time.'
                        : 'A dramatic little rant about why this didn’t work out right now.',
                    key: ValueKey(checked),
                    style: AppText.body(
                      13,
                      context: context,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(
                        () => _maybeReturn[index] = !checked,
                      ),
                      child: Text(
                        checked ? 'Undo' : 'Maybe later…',
                        style: AppText.bodySemiBold(13, context: context),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push(
                        '/book/${Uri.encodeComponent(book.id)}',
                      ),
                      child: Text(
                        'View',
                        style: AppText.bodySemiBold(13, context: context),
                      ),
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
