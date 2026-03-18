import '../../core/config/supabase_config.dart';
import '../models/review.dart';

class ReviewRepository {
  final _client = SupabaseConfig.client;

  Future<List<Review>> getReviewsForBook(String bookId) async {
    final rows = await _client
        .from('reviews')
        .select()
        .eq('book_id', bookId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => Review.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addReview(Review review) async {
    await _client.from('reviews').insert(review.toSupabase());
  }

  Future<void> toggleLike(String reviewId, bool like) async {
    await _client.rpc(
      like ? 'increment_review_likes' : 'decrement_review_likes',
      params: {'review_id': reviewId},
    );
  }
}

