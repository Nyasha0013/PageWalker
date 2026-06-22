import 'package:flutter/material.dart';

enum PagewalkerPlusFeature {
  moodReads,
  readingPersonality,
  readingWrap,
  readingBingo,
  spinWheel,
  unlimitedClubs,
  yearlyWrapped,
}

class PlusFeatureInfo {
  final PagewalkerPlusFeature id;
  final String title;
  final String subtitle;
  final IconData icon;

  const PlusFeatureInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Free vs Plus split — tuned for conversion without blocking core library use.
class PagewalkerPlusCatalog {
  PagewalkerPlusCatalog._();

  static const freeClubLimit = 1;
  static const monthlyPriceLabel = r'$4.99 / month';
  static const yearlyPriceLabel = r'$39.99 / year';

  static const plusFeatures = <PlusFeatureInfo>[
    PlusFeatureInfo(
      id: PagewalkerPlusFeature.moodReads,
      title: 'Mood Reads',
      subtitle: 'AI picks based on how you want to feel',
      icon: Icons.auto_awesome_rounded,
    ),
    PlusFeatureInfo(
      id: PagewalkerPlusFeature.readingPersonality,
      title: 'Reading personality',
      subtitle: 'Your trope DNA and AI personality summary',
      icon: Icons.psychology_alt_rounded,
    ),
    PlusFeatureInfo(
      id: PagewalkerPlusFeature.readingWrap,
      title: 'Reading Wraps',
      subtitle: 'Monthly, quarterly, and yearly share cards',
      icon: Icons.insights_rounded,
    ),
    PlusFeatureInfo(
      id: PagewalkerPlusFeature.readingBingo,
      title: 'Reading Bingo',
      subtitle: '25 mini-challenges on a living bingo board',
      icon: Icons.grid_view_rounded,
    ),
    PlusFeatureInfo(
      id: PagewalkerPlusFeature.spinWheel,
      title: 'Spin the Wheel',
      subtitle: 'Let fate pick your next TBR read',
      icon: Icons.casino_rounded,
    ),
    PlusFeatureInfo(
      id: PagewalkerPlusFeature.unlimitedClubs,
      title: 'Unlimited book clubs',
      subtitle: 'Create and join as many clubs as you want',
      icon: Icons.groups_rounded,
    ),
    PlusFeatureInfo(
      id: PagewalkerPlusFeature.yearlyWrapped,
      title: 'Year in Books',
      subtitle: 'Full yearly wrapped story and share export',
      icon: Icons.celebration_rounded,
    ),
  ];

  static const freeHighlights = <String>[
    'Full library — TBR, Reading, Read, DNF',
    'Search & add books (Google, Open Library, Gutenberg)',
    'Reviews, social feed, and achievements',
    'Join 1 book club',
    'Reading timer and basic stats',
    'Home screen widget — current read on your Android home screen',
  ];
}
