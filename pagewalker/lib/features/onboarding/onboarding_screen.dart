import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/dynamic_sky_background.dart';
import '../../core/widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/auth/login');
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DynamicSkyBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: AppText.body(
                        14,
                        color: AppColors.darkTextMuted,
                        context: context,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildPage1(context),
                    _buildPage2(context),
                    _buildPage3(context),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: 3,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppColors.orangePrimary,
                        dotColor: AppColors.darkTextMuted,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: _currentPage < 2 ? 'Next ✦' : 'Start my journey',
                      onPressed: _nextPage,
                      width: double.infinity,
                      height: 56,
                    ),
                    if (_currentPage == 2) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _completeOnboarding,
                        child: Text(
                          'Already have an account? Sign in',
                          style: AppText.body(
                            13,
                            color: AppColors.darkTextSecondary,
                            context: context,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage1(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) => Transform.translate(
              offset: Offset(0, _floatController.value * -12),
              child: SizedBox(
                width: 140,
                height: 170,
                child: CustomPaint(
                  painter: _OnboardingBookPainter(legPhase: _floatController.value),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Pagewalker',
            style: AppText.script(48),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),
          Text(
            'Your enchanted reading universe',
            style: AppText.display(22, context: context),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'Track every book you read, discover your next obsession, and share your reading life with friends.',
            style: AppText.body(
              15,
              color: AppColors.darkTextSecondary,
              context: context,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 400.ms).fadeIn(duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildPage2(BuildContext context) {
    final features = const [
      ('📚', 'Your Library', 'TBR, Reading, Read & DNF — all in one beautiful place'),
      ('✨', 'Mood Reads', 'Tell the app how you feel, it finds your perfect next book'),
      ('🎡', 'Spin the Wheel', "Can't decide what to read? Let fate choose from your TBR"),
      ('🏆', 'Tier Your Books', "God Tier, A Class, B Class — rank every book you've ever read"),
      ('📷', 'Scan & Add', 'Point your camera at any book barcode to add it instantly'),
      ('🎖️', 'Achievements', 'Unlock badges for reading milestones and streaks'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Everything a reader needs',
            style: AppText.display(26, context: context),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),
          ...features.asMap().entries.map((entry) {
            final i = entry.key;
            final feature = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.orangePrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.orangePrimary.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        feature.$1,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.$2,
                          style: AppText.bodySemiBold(14, context: context),
                        ),
                        Text(
                          feature.$3,
                          style: AppText.body(
                            12,
                            color: AppColors.darkTextSecondary,
                            context: context,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 100 * i))
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.2, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildPage3(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return SizedBox(
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 30,
                      top: 20 + _floatController.value * 8,
                      child: _buildAvatarBubble('📖', AppColors.orangeDeep),
                    ),
                    Positioned(
                      left: 110,
                      top: _floatController.value * -10,
                      child: _buildAvatarBubble(
                        '✨',
                        AppColors.orangePrimary,
                        size: 70,
                      ),
                    ),
                    Positioned(
                      right: 30,
                      top: 30 + _floatController.value * 6,
                      child: _buildAvatarBubble('💬', AppColors.orangeBright),
                    ),
                    CustomPaint(
                      size: const Size(300, 160),
                      painter: _ConnectionLinesPainter(),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Read together',
            style: AppText.display(30, context: context),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'Follow readers who love what you love. Join Book Club rooms. Discuss your favourite reads with spoiler-safe chats.',
            style: AppText.body(
              15,
              color: AppColors.darkTextSecondary,
              context: context,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              '📌 Track reads',
              '🔥 Build streaks',
              '🫶 Make book friends',
              '🏅 Earn badges',
              '🎬 Yearly Wrapped',
            ]
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.orangePrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.orangePrimary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      label,
                      style: AppText.bodySemiBold(
                        12,
                        color: AppColors.orangePrimary,
                        context: context,
                      ),
                    ),
                  ),
                )
                .toList(),
          ).animate(delay: 400.ms).fadeIn(duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildAvatarBubble(String emoji, Color color, {double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.4),
        ),
      ),
    );
  }
}

class _OnboardingBookPainter extends CustomPainter {
  final double legPhase;

  _OnboardingBookPainter({required this.legPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bookW = size.width * 0.7;
    final bookH = size.height * 0.55;
    final bookTop = size.height * 0.05;
    final bookLeft = cx - bookW / 2;

    final coverPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.orangeBright, AppColors.orangePrimary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(bookLeft, bookTop, bookW, bookH));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bookLeft, bookTop, bookW, bookH),
        const Radius.circular(8),
      ),
      coverPaint,
    );

    final spinePaint = Paint()
      ..color = AppColors.orangeDeep
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(bookLeft + 12, bookTop + 6),
      Offset(bookLeft + 12, bookTop + bookH - 6),
      spinePaint,
    );

    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black;

    canvas.drawCircle(Offset(cx - 10, bookTop + bookH * 0.38), 6, eyePaint);
    canvas.drawCircle(Offset(cx + 10, bookTop + bookH * 0.38), 6, eyePaint);
    canvas.drawCircle(
      Offset(cx - 8.5, bookTop + bookH * 0.38 + 1),
      3,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(cx + 11.5, bookTop + bookH * 0.38 + 1),
      3,
      pupilPaint,
    );

    final smilePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final smilePath = Path()
      ..moveTo(cx - 10, bookTop + bookH * 0.55)
      ..quadraticBezierTo(
        cx,
        bookTop + bookH * 0.64,
        cx + 10,
        bookTop + bookH * 0.55,
      );
    canvas.drawPath(smilePath, smilePaint);

    canvas.drawCircle(
      Offset(cx - 16, bookTop + bookH * 0.52),
      6,
      Paint()..color = AppColors.secondary.withOpacity(0.4),
    );
    canvas.drawCircle(
      Offset(cx + 16, bookTop + bookH * 0.52),
      6,
      Paint()..color = AppColors.secondary.withOpacity(0.4),
    );

    final legPaint = Paint()
      ..color = AppColors.orangeDeep
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final footPaint = Paint()
      ..color = AppColors.orangePrimary
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final sway = sin(legPhase * pi) * 6;

    canvas.drawLine(
      Offset(cx - 18, bookTop + bookH),
      Offset(cx - 18 - sway, bookTop + bookH + size.height * 0.25),
      legPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          cx - 14 - sway,
          bookTop + bookH + size.height * 0.27,
        ),
        width: 22,
        height: 10,
      ),
      footPaint,
    );

    canvas.drawLine(
      Offset(cx + 18, bookTop + bookH),
      Offset(cx + 18 + sway, bookTop + bookH + size.height * 0.25),
      legPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          cx + 22 + sway,
          bookTop + bookH + size.height * 0.27,
        ),
        width: 22,
        height: 10,
      ),
      footPaint,
    );
  }

  @override
  bool shouldRepaint(_OnboardingBookPainter old) => old.legPhase != legPhase;
}

class _ConnectionLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orangePrimary.withOpacity(0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(65, 48), const Offset(130, 60), paint);
    canvas.drawLine(const Offset(180, 60), const Offset(235, 55), paint);
  }

  @override
  bool shouldRepaint(_ConnectionLinesPainter old) => false;
}

