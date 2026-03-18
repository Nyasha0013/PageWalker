import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/dynamic_sky_background.dart';
import 'widgets/currently_reading_tab.dart';
import 'widgets/dnf_tab.dart';
import 'widgets/read_tab.dart';
import 'widgets/spin_wheel_modal.dart';
import 'widgets/tbr_grid.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final ConfettiController _confettiController;

  final _tabs = const ['TBR', 'Reading', 'Read', 'DNF'];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: _SpinFab(
        onPressed: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => SpinWheelModal(
              confettiController: _confettiController,
            ),
          );
        },
      ),
      body: DynamicSkyBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Library',
                      style: AppText.display(24, context: context),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.push('/scanner'),
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                          ),
                          color: AppColors.orangePrimary,
                          tooltip: 'Scan a book',
                        ),
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: AppColors.orangeAmber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Updated tab selector (prevents orange pill covering text)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard.withOpacity(0.8)
                      : AppColors.lightCard.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.orangePrimary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: _tabs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final label = entry.value;
                    final selected = _currentIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.orangePrimary.withOpacity(0.85)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildTabBody(_currentIndex),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBody(int index) {
    switch (index) {
      case 0:
        return const TbrGrid().animate().fadeIn().scale(
              begin: const Offset(0.98, 0.98),
              curve: Curves.easeOut,
            );
      case 1:
        return const CurrentlyReadingTab().animate().fadeIn();
      case 2:
        return const ReadTab().animate().fadeIn();
      case 3:
      default:
        return const DnfTab().animate().fadeIn();
    }
  }
}

class _SpinFab extends StatefulWidget {
  final VoidCallback onPressed;

  const _SpinFab({required this.onPressed});

  @override
  State<_SpinFab> createState() => _SpinFabState();
}

class _SpinFabState extends State<_SpinFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.95).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
          ),
        ),
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: AppColors.gradientOrange,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.orangeBright,
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '✦',
              style: AppText.display(24, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
