import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/dynamic_sky_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/book.dart';
import '../../data/repositories/book_repository.dart';

class ReadingTimerScreen extends StatefulWidget {
  final String bookId;
  const ReadingTimerScreen({super.key, required this.bookId});

  @override
  State<ReadingTimerScreen> createState() => _ReadingTimerScreenState();
}

class _ReadingTimerScreenState extends State<ReadingTimerScreen> {
  final _bookRepo = BookRepository();
  Book? _book;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Timer? _idleTimer;

  bool _running = false;
  bool _controlsVisible = true;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBook() async {
    try {
      final b = await _bookRepo.getBookById(widget.bookId);
      if (!mounted) return;
      setState(() => _book = b);
    } catch (_) {
      // Best-effort: timer works even without book metadata.
    }
  }

  void _startOrPause() {
    _bumpControls();
    if (_running) {
      _ticker?.cancel();
      _stopwatch.stop();
      setState(() => _running = false);
      return;
    }

    _startedAt ??= DateTime.now();
    _stopwatch.start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    setState(() => _running = true);
  }

  void _bumpControls() {
    setState(() => _controlsVisible = true);
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
    });
  }

  Future<void> _finish() async {
    _bumpControls();
    if (_startedAt == null) return;

    _ticker?.cancel();
    _stopwatch.stop();
    final endedAt = DateTime.now();
    final durationSeconds = _stopwatch.elapsed.inSeconds;

    final pagesRead = await _askPagesRead();
    if (pagesRead == null) {
      // If user cancels pages dialog, keep the session running state as paused.
      setState(() => _running = false);
      return;
    }

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        await SupabaseConfig.client.from('reading_sessions').insert({
          'user_id': user.id,
          'book_id': widget.bookId,
          'started_at': _startedAt!.toIso8601String(),
          'ended_at': endedAt.toIso8601String(),
          'duration_seconds': durationSeconds,
          'pages_read': pagesRead,
        });
      }

      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _SessionSummarySheet(
          durationSeconds: durationSeconds,
          pagesRead: pagesRead,
        ),
      );
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save session. Try again.',
            style: AppText.body(14, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFB3261E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _running = false);
    }
  }

  Future<int?> _askPagesRead() async {
    final controller = TextEditingController();
    final result = await showDialog<int?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkCard,
          title: Text(
            'Finish session',
            style: AppText.display(18, context: context),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'How many pages did you read?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final pages = int.tryParse(controller.text.trim()) ?? 0;
                Navigator.of(context).pop(pages);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  String _formatElapsed(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    final elapsed = _stopwatch.elapsed;

    return Scaffold(
      body: GestureDetector(
        onTap: _bumpControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            DynamicSkyBackground(
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    if (book?.coverUrl != null)
                      Positioned.fill(
                        child: Image.network(
                          book!.coverUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (book?.coverUrl != null)
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(color: Colors.black.withOpacity(0.62)),
                        ),
                      )
                    else
                      Positioned.fill(
                        child: Container(color: Colors.black.withOpacity(0.62)),
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _controlsVisible ? 1 : 0,
                          child: IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.orangePrimary.withOpacity(0.55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orangePrimary.withOpacity(0.14),
                            blurRadius: 30,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatElapsed(elapsed),
                            style: AppText.display(
                              48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            book?.title ?? 'Reading session',
                            style: AppText.bodySemiBold(
                              14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 450.ms)
                        .scale(begin: const Offset(0.98, 0.98)),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _controlsVisible ? 1 : 0,
                      child: Column(
                        children: [
                          GradientButton(
                            label: _running ? 'Pause' : 'Start Reading',
                            icon: Icon(
                              _running
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            width: double.infinity,
                            onPressed: _startOrPause,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed:
                                (_startedAt == null) ? null : _finish,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFF4444)),
                              foregroundColor: const Color(0xFFFF4444),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Finish Session'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionSummarySheet extends StatelessWidget {
  final int durationSeconds;
  final int pagesRead;

  const _SessionSummarySheet({
    required this.durationSeconds,
    required this.pagesRead,
  });

  String _format(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Great session!',
                style: AppText.display(18, context: context),
              ),
              const SizedBox(height: 8),
              Text(
                'You read for ${_format(durationSeconds)} • $pagesRead pages',
                style: AppText.body(14, context: context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              GradientButton(
                label: 'Back to Library',
                width: double.infinity,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ).animate().slideY(begin: 0.2, end: 0).fadeIn(),
      ),
    );
  }
}

