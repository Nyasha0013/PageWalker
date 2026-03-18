import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
class DynamicSkyBackground extends StatelessWidget {
  final Widget child;

  const DynamicSkyBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // Static sky gradient based on theme
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [
                      Color(0xFF0A0A0A),
                      Color(0xFF120800),
                      Color(0xFF1A0A00),
                    ]
                  : const [
                      Color(0xFFFFF8F0),
                      Color(0xFFFFE8C0),
                      Color(0xFFFFCC80),
                    ],
            ),
          ),
        ),
        // Static sun (dark mode) or bright sun (light mode)
        Positioned(
          top: 30,
          left: 0,
          right: 0,
          child: Center(
            child: _buildSun(isDark),
          ),
        ),
        // Stars — only in dark mode
        if (isDark) _buildStars(context),
        // Horizon glow
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.orangePrimary.withOpacity(isDark ? 0.15 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }

  Widget _buildSun(bool isDark) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isDark
              ? [
                  const Color(0xFFFFCC44),
                  const Color(0xFFFF8800),
                  const Color(0xFFFF4400).withOpacity(0.3),
                  Colors.transparent,
                ]
              : [
                  const Color(0xFFFFEE88),
                  const Color(0xFFFFCC33),
                  const Color(0xFFFF8800).withOpacity(0.4),
                  Colors.transparent,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orangeAmber.withOpacity(isDark ? 0.8 : 0.5),
            blurRadius: isDark ? 40 : 30,
            spreadRadius: isDark ? 10 : 5,
          ),
        ],
      ),
    );
  }

  Widget _buildStars(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _StaticStarsPainter(),
      ),
    );
  }
}

class _StaticStarsPainter extends CustomPainter {
  final List<Offset> _starPositions = const [
    Offset(0.1, 0.05),
    Offset(0.25, 0.08),
    Offset(0.4, 0.03),
    Offset(0.6, 0.07),
    Offset(0.75, 0.04),
    Offset(0.9, 0.09),
    Offset(0.15, 0.15),
    Offset(0.35, 0.12),
    Offset(0.55, 0.18),
    Offset(0.7, 0.11),
    Offset(0.85, 0.16),
    Offset(0.05, 0.22),
    Offset(0.45, 0.2),
    Offset(0.65, 0.25),
    Offset(0.8, 0.2),
    Offset(0.2, 0.28),
    Offset(0.5, 0.3),
    Offset(0.95, 0.26),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFEECC).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    for (final pos in _starPositions) {
      canvas.drawCircle(
        Offset(pos.dx * size.width, pos.dy * size.height),
        1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StaticStarsPainter old) => false;
}

