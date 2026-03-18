import '../../core/config/supabase_config.dart';
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

