import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SparkleBackground extends StatefulWidget {
  final Widget child;
  final int sparkleCount;

  const SparkleBackground({
    super.key,
    required this.child,
    this.sparkleCount = 20,
  });

  @override
  State<SparkleBackground> createState() => _SparkleBackgroundState();
}

class _SparkleParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final Duration delay;
  final Duration duration;

  _SparkleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.delay,
    required this.duration,
  });
}

class _SparkleBackgroundState extends State<SparkleBackground>
    with TickerProviderStateMixin {
  final List<_SparkleParticle> _particles = [];
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];
  final _random = Random();
  final _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.gold,
    AppColors.moonlight,
    AppColors.mystic,
  ];

  @override
  void initState() {
    super.initState();
    _initParticles();
  }

  void _initParticles() {
    for (int i = 0; i < widget.sparkleCount; i++) {
      _particles.add(
        _SparkleParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 5 + 2,
          color: _colors[_random.nextInt(_colors.length)],
          delay: Duration(milliseconds: _random.nextInt(3000)),
          duration: Duration(milliseconds: 1500 + _random.nextInt(2000)),
        ),
      );
      final controller = AnimationController(
        duration: _particles[i].duration,
        vsync: this,
      );
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
      _controllers.add(controller);
      _animations.add(animation);
      Future.delayed(_particles[i].delay, () {
        if (mounted) {
          controller.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Sparkle particles
        ...List.generate(_particles.length, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, _) {
              return Positioned(
                left:
                    _particles[i].x * MediaQuery.of(context).size.width,
                top:
                    _particles[i].y * MediaQuery.of(context).size.height,
                child: Opacity(
                  opacity: _animations[i].value * 0.7,
                  child: Text(
                    '✦',
                    style: TextStyle(
                      fontSize: _particles[i].size,
                      color: _particles[i].color,
                    ),
                  ),
                ),
              );
            },
          );
        }),
        // Main content
        widget.child,
      ],
    );
  }
}

