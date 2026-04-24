import 'package:flutter/foundation.dart';

import '../../core/config/supabase_config.dart';
import '../models/review.dart';

class ReviewRepository {
  final _client = SupabaseConfig.client;

  /// Books with the most reviews in the last 7 days (for Discover “Hot right now”).
  /// Uses optional `book_title`, `book_author`, `book_cover_url` on `reviews` when present.
  Future<List<Map<String, dynamic>>> getHotBooksThisWeek() async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final rows = await _client
          .from('reviews')
          .select(
            'book_id, book_title, book_author, book_cover_url, created_at',
          )
          .gte('created_at', weekAgo.toIso8601String())
          .limit(200);

      final list = rows as List<dynamic>;
      final counts = <String, Map<String, dynamic>>{};
      for (final raw in list) {
        final r = raw as Map<String, dynamic>;
        final id = r['book_id'] as String?;
        if (id == null || id.isEmpty) continue;
        counts.putIfAbsent(
          id,
          () => {
            'book_id': id,
            'book_title': r['book_title'],
            'book_author': r['book_author'],
            'book_cover_url': r['book_cover_url'],
            'count': 0,
          },
        );
        counts[id]!['count'] = (counts[id]!['count'] as int) + 1;
      }
      final sorted = counts.values.toList()
        ..sort(
          (a, b) => (b['count'] as int).compareTo(a['count'] as int),
        );
      return sorted.take(10).toList();
    } catch (e, st) {
      debugPrint('getHotBooksThisWeek: $e\n$st');
      return [];
    }
  }

  Future<List<Review>> getReviewsForBook(
    String bookId, {
    bool sortByLikes = false,
  }) async {
    final rows =
        await _client.from('reviews').select().eq('book_id', bookId).order(
              sortByLikes ? 'likes_count' : 'created_at',
              ascending: false,
            );
    return (rows as List<dynamic>)
        .map((e) => Review.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> countReviewsForBook(String bookId) async {
    final rows =
        await _client.from('reviews').select('id').eq('book_id', bookId);
    return (rows as List).length;
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

  /// Newest reviews first (for Social feed). Best-effort; returns empty on error.
  Future<List<Review>> getRecentReviews({int limit = 120}) async {
    try {
      final rows = await _client
          .from('reviews')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List<dynamic>)
          .map((e) => Review.fromSupabase(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('getRecentReviews: $e\n$st');
      return [];
    }
  }
}
