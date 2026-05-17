import '../../core/config/supabase_config.dart';
import '../models/book.dart';
import '../models/user_book.dart';

class UserBookRepository {
  final _client = SupabaseConfig.client;

  Future<List<UserBook>> getUserBooks(String userId) async {
    final rows = await _client
        .from('user_books')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return (rows as List<dynamic>)
        .map((e) => UserBook.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Book>> getBooksForStatus(String userId, BookStatus status) async {
    final rows = await _client
        .from('user_books')
        .select('*, books(*)')
        .eq('user_id', userId)
        .eq('status', status.name)
        .order('created_at', ascending: false);
    return _parseJoinedBooks(rows);
  }

  Future<List<Book>> getRecentBooks(String userId, {int limit = 8}) async {
    final rows = await _client
        .from('user_books')
        .select('*, books(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return _parseJoinedBooks(rows);
  }

  Future<List<(UserBook, Book)>> getShelfEntries(
    String userId,
    BookStatus status,
  ) async {
    final rows = await _client
        .from('user_books')
        .select('*, books(*)')
        .eq('user_id', userId)
        .eq('status', status.name)
        .order('created_at', ascending: false) as List<dynamic>;
    final out = <(UserBook, Book)>[];
    for (final row in rows) {
      final m = row as Map<String, dynamic>;
      final b = m['books'];
      if (b is! Map<String, dynamic>) continue;
      final ubMap = Map<String, dynamic>.from(m)..remove('books');
      try {
        out.add((
          UserBook.fromSupabase(ubMap),
          Book.fromSupabase(b),
        ));
      } catch (_) {}
    }
    return out;
  }

  List<Book> _parseJoinedBooks(dynamic rows) {
    final out = <Book>[];
    if (rows is! List) return out;
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final b = row['books'];
      if (b is Map<String, dynamic>) {
        try {
          out.add(Book.fromSupabase(b));
        } catch (_) {}
      }
    }
    return out;
  }

  Future<({int readCount, double avgRating})> getReadStats(
    String userId,
  ) async {
    final rows = await getShelfEntries(userId, BookStatus.read);
    if (rows.isEmpty) {
      return (readCount: 0, avgRating: 0.0);
    }
    double sum = 0;
    var n = 0;
    for (final (ub, _) in rows) {
      final r = ub.starRating;
      if (r != null) {
        sum += r;
        n++;
      }
    }
    final avg = n > 0 ? sum / n : 4.0;
    return (readCount: rows.length, avgRating: avg);
  }

  Future<void> upsertUserBook(UserBook userBook) async {
    await _client.from('user_books').upsert({
      'id': userBook.id,
      'user_id': userBook.userId,
      'book_id': userBook.bookId,
      'status': userBook.status.name,
      'star_rating': userBook.starRating,
      'tier': userBook.tierToDb,
      'date_started':
          userBook.dateStarted?.toIso8601String(),
      'date_finished':
          userBook.dateFinished?.toIso8601String(),
      'is_favorite': userBook.isFavorite,
    });
  }
}
