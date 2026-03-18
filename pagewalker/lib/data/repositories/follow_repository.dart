import '../../core/config/supabase_config.dart';

class FollowRepository {
  final _client = SupabaseConfig.client;

  Future<bool> isFollowing(String targetUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final row = await _client
        .from('follows')
        .select('id')
        .eq('follower_id', user.id)
        .eq('following_id', targetUserId)
        .maybeSingle();
    return row != null;
  }

  Future<void> follow(String targetUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('follows').upsert({
      'follower_id': user.id,
      'following_id': targetUserId,
    });
  }

  Future<void> unfollow(String targetUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
        .from('follows')
        .delete()
        .eq('follower_id', user.id)
        .eq('following_id', targetUserId);
  }

  Future<List<String>> getFollowingIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', user.id);
    return (rows as List)
        .map((e) => e['following_id'] as String)
        .toList();
  }
}

