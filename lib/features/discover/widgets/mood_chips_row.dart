import 'package:flutter/material.dart';

import '../../../core/widgets/trope_chip.dart';

class MoodChipsRow extends StatelessWidget {
  final List<String> moods;
  final ValueChanged<String> onSelected;

  const MoodChipsRow({
    super.key,
    required this.moods,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = moods[index];
          return TropeChip(
            label: label,
            onTap: () => onSelected(label),
          );
        },
      ),
    );
  }
}

