import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/config/supabase_config.dart';
import '../../core/services/achievement_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/book.dart';
import '../../data/repositories/book_repository.dart';

class BookScannerScreen extends StatefulWidget {
  const BookScannerScreen({super.key});

  @override
  State<BookScannerScreen> createState() => _BookScannerScreenState();
}

class _BookScannerScreenState extends State<BookScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final BookRepository _bookRepo = BookRepository();

  bool _scanning = true;
  bool _loading = false;
  Book? _foundBook;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (!_scanning) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    final isbn = raw.trim();

    setState(() {
      _scanning = false;
      _loading = true;
      _errorMessage = null;
    });

    await _scannerController.stop();

    try {
      final results = await _bookRepo.searchBooks('isbn:$isbn');
      setState(() {
        _loading = false;
        if (results.isNotEmpty) {
          _foundBook = results.first;
        } else {
          _errorMessage = "Couldn't find this book. Try searching manually.";
        }
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errorMessage = "Couldn't search right now. Try again.";
      });
    }
  }

  Future<void> _addToTBR() async {
    final book = _foundBook;
    if (book == null) return;

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        setState(() => _errorMessage = 'Please log in to add books.');
        return;
      }

      await SupabaseConfig.client.from('books').upsert(book.toSupabase());
      await SupabaseConfig.client.from('user_books').upsert({
        'user_id': user.id,
        'book_id': book.id,
        'status': 'tbr',
      });
      await AchievementService().checkAchievements(
        userId: user.id,
        justScanned: true,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added to your TBR!',
            style: AppText.bodySemiBold(14, color: Colors.white),
          ),
          backgroundColor: AppColors.orangePrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      context.pop();
    } catch (_) {
      setState(() => _errorMessage = 'Failed to add book. Try again.');
    }
  }

  void _rescan() {
    setState(() {
      _scanning = true;
      _loading = false;
      _foundBook = null;
      _errorMessage = null;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_scanning || _loading)
            MobileScanner(
              controller: _scannerController,
              onDetect: _onBarcodeDetected,
            ),
          if (_scanning) _buildScanOverlay(),
          if (_loading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.orangePrimary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Finding your book...',
                      style: AppText.bodySemiBold(16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          if (_foundBook != null) _buildFoundBookSheet(),
          if (_errorMessage != null) _buildErrorSheet(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.orangePrimary.withOpacity(0.4),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: 260,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: SizedBox(
            width: 260,
            height: 160,
            child: CustomPaint(painter: _ScanFramePainter()),
          ),
        ),
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                'Point at the barcode on the back of any book',
                style: AppText.body(14, color: Colors.white),
                textAlign: TextAlign.center,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 800.ms)
                  .then()
                  .fadeOut(duration: 800.ms),
              const SizedBox(height: 8),
              Text(
                'Works with ISBN barcodes',
                style: AppText.body(12, color: AppColors.orangePrimary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoundBookSheet() {
    final book = _foundBook!;
    return Container(
      color: Colors.black87,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GlassCard(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Book found!',
                style: AppText.bodySemiBold(
                  14,
                  color: AppColors.orangePrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: book.coverUrl != null
                        ? Image.network(
                            book.coverUrl!,
                            width: 70,
                            height: 105,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 70,
                            height: 105,
                            color: AppColors.darkCard,
                            child: const Icon(
                              Icons.book,
                              color: AppColors.orangePrimary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: AppText.display(18, context: context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: AppText.body(
                            14,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                        if (book.pageCount != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${book.pageCount} pages',
                            style: AppText.body(
                              12,
                              color: AppColors.darkTextMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Add to TBR',
                onPressed: _addToTBR,
                width: double.infinity,
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _rescan,
                child: Text(
                  'Scan another book',
                  style: AppText.bodySemiBold(
                    14,
                    color: AppColors.orangePrimary,
                  ),
                ),
              ),
            ],
          ),
        ).animate().slideY(
              begin: 1,
              end: 0,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }

  Widget _buildErrorSheet() {
    return Container(
      color: Colors.black87,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GlassCard(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage ?? 'Something went wrong.',
                style: AppText.body(15, context: context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Try Again',
                onPressed: _rescan,
                width: double.infinity,
              ),
            ],
          ),
        ).animate().slideY(begin: 1, end: 0),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orangePrimary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const r = 12.0;

    canvas.drawLine(const Offset(r, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, r), const Offset(0, cornerLength), paint);

    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width - r, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, r),
      Offset(size.width, cornerLength),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height - r),
      paint,
    );
    canvas.drawLine(
      Offset(r, size.height),
      Offset(cornerLength, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height - r),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width - r, size.height),
      paint,
    );

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.orangePrimary,
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(0, size.height / 2, size.width, 2),
      )
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(8, size.height / 2),
      Offset(size.width - 8, size.height / 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) => false;
}

