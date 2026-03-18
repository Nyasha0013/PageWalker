import '../config/supabase_config.dart';
import 'notification_service.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._();
  factory AchievementService() => _instance;
  AchievementService._();

  Future<void> checkAchievements({
    required String userId,
    int? booksRead,
    int? currentStreak,
    int? godTierCount,
    int? reviewsCount,
    int? followersCount,
    int? tbrCount,
    bool? justScanned,
    bool? nightOwlSession,
    bool? speedRead,
    bool? wroteFirstReview,
    bool? followedSomeone,
  }) async {
    final unlocked = <String>[];

    if (booksRead != null) {
      if (booksRead >= 1) unlocked.add('first_book');
      if (booksRead >= 5) unlocked.add('books_5');
      if (booksRead >= 10) unlocked.add('books_10');
      if (booksRead >= 25) unlocked.add('books_25');
      if (booksRead >= 50) unlocked.add('books_50');
      if (booksRead >= 100) unlocked.add('books_100');
    }

    if (currentStreak != null) {
      if (currentStreak >= 7) unlocked.add('streak_7');
      if (currentStreak >= 30) unlocked.add('streak_30');
      if (currentStreak >= 100) unlocked.add('streak_100');
    }

    if (godTierCount != null) {
      if (godTierCount >= 1) unlocked.add('god_tier_1');
      if (godTierCount >= 5) unlocked.add('god_tier_5');
    }

    if (reviewsCount != null && reviewsCount >= 1) unlocked.add('first_review');
    if (reviewsCount != null && reviewsCount >= 10) unlocked.add('reviews_10');
    if (followersCount != null && followersCount >= 10) {
      unlocked.add('followers_10');
    }
    if (tbrCount != null && tbrCount >= 20) unlocked.add('tbr_20');

    if (justScanned == true) unlocked.add('scanner_1');
    if (nightOwlSession == true) unlocked.add('night_owl');
    if (speedRead == true) unlocked.add('speed_reader');
    if (wroteFirstReview == true) unlocked.add('first_review');
    if (followedSomeone == true) unlocked.add('first_follow');

    final existing = await SupabaseConfig.client
        .from('user_achievements')
        .select('achievement_id')
        .eq('user_id', userId);
    final existingIds = (existing as List)
        .map((e) => e['achievement_id'] as String)
        .toSet();

    for (final id in unlocked) {
      if (existingIds.contains(id)) continue;

      await SupabaseConfig.client.from('user_achievements').insert({
        'user_id': userId,
        'achievement_id': id,
      });

      final achievement = await SupabaseConfig.client
          .from('achievements')
          .select()
          .eq('id', id)
          .single();

      await NotificationService().sendMilestone(
        '${achievement['icon']} Achievement Unlocked!',
        '${achievement['name']}: ${achievement['description']}',
      );
    }
  }
}

