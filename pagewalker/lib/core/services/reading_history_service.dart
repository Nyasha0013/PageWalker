import '../config/supabase_config.dart';

class ReadingHistoryService {
  ReadingHistoryService._();

  static Future<void> upsertProgress({
    required String bookId,
    required String bookTitle,
    required String bookAuthor,
    required String source,
    required double scrollPosition,
    bool isFinished = false,
  }) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    try {
      await SupabaseConfig.client.from('reading_history').upsert({
        'user_id': user.id,
        'book_id': bookId,
        'book_title': bookTitle,
        'book_author': bookAuthor,
        'source': source,
        'scroll_position': scrollPosition,
        'is_finished': isFinished,
        'last_read_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // migration not applied yet
    }
  }
}
