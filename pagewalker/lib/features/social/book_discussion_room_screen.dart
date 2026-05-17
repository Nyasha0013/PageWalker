import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/themed_background.dart';
import '../../data/models/profile.dart';
import '../../data/models/review.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/review_repository.dart';

class BookDiscussionRoomScreen extends StatefulWidget {
  final String bookId;

  const BookDiscussionRoomScreen({super.key, required this.bookId});

  @override
  State<BookDiscussionRoomScreen> createState() => _BookDiscussionRoomScreenState();
}

class _BookDiscussionRoomScreenState extends State<BookDiscussionRoomScreen> {
  final _reviewsRepo = ReviewRepository();
  final _profilesRepo = ProfileRepository();
  final _commentCtrl = TextEditingController();

  List<Review> _reviews = [];
  Map<String, Profile> _profiles = {};
  bool _loading = true;
  bool _posting = false;
  bool _spoiler = false;
  bool _confirmedEntry = false;

  String get _roomBookId => Uri.decodeComponent(widget.bookId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final allowed = await _showSpoilerConsent();
      if (!mounted) return;
      if (!allowed) {
        context.pop();
        return;
      }
      setState(() => _confirmedEntry = true);
      await _loadReviews();
    });
  }

  Future<bool> _showSpoilerConsent() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Spoiler confirmation'),
          content: const Text(
            'By entering this discussion room, you confirm you have finished this book and accept spoilers from other readers.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enter room'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    final reviews = await _reviewsRepo.getReviewsForBook(_roomBookId);
    final ids = reviews.map((r) => r.userId).toSet().toList();
    final profiles = await _profilesRepo.getProfilesByIds(ids);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _profiles = profiles;
      _loading = false;
    });
  }

  Future<void> _post() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in required to post in rooms.')),
      );
      context.push('/auth/login');
      return;
    }
    setState(() => _posting = true);
    try {
      await _reviewsRepo.addReview(
        Review(
          id: const Uuid().v4(),
          userId: user.id,
          bookId: _roomBookId,
          content: text,
          containsSpoilers: _spoiler,
          likesCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _commentCtrl.clear();
      setState(() => _spoiler = false);
      await _loadReviews();
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Discussion Room',
                        style: AppText.display(22, context: context),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_confirmedEntry)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Room channel',
                                    style: AppText.bodySemiBold(14, context: context),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _commentCtrl,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                      hintText: 'Share your thoughts with readers...',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text('Spoiler', style: AppText.body(12, context: context)),
                                      const Spacer(),
                                      Switch(
                                        value: _spoiler,
                                        onChanged: (v) => setState(() => _spoiler = v),
                                        activeTrackColor:
                                            AppColors.orangePrimary.withValues(alpha: 0.45),
                                        thumbColor: WidgetStateProperty.all(AppColors.orangePrimary),
                                      ),
                                    ],
                                  ),
                                  GradientButton(
                                    label: 'Post to room',
                                    width: double.infinity,
                                    isLoading: _posting,
                                    onPressed: _posting ? null : _post,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_reviews.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'No messages yet. Start the discussion.',
                                  style: AppText.body(13, context: context),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              ..._reviews.map((r) {
                                final p = _profiles[r.userId];
                                return GlassCard(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '@${p?.username ?? 'reader'}',
                                            style: AppText.bodySemiBold(13, context: context),
                                          ),
                                          const Spacer(),
                                          Text(
                                            DateFormat.yMMMd().add_jm().format(r.createdAt),
                                            style: AppText.body(11, context: context),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        r.content,
                                        style: AppText.body(14, context: context),
                                      ),
                                      if (r.containsSpoilers) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Spoiler',
                                          style: AppText.label(
                                            11,
                                            color: AppColors.orangePrimary,
                                            context: context,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
