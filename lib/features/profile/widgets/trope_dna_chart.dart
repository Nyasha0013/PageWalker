import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/glass_card.dart';

class TropeDnaChart extends StatelessWidget {
  const TropeDnaChart({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      PieChartSectionData(
        color: AppColors.primary,
        value: 35,
        title: '',
      ),
      PieChartSectionData(
        color: AppColors.secondary,
        value: 25,
        title: '',
      ),
      PieChartSectionData(
        color: AppColors.mystic,
        value: 20,
        title: '',
      ),
      PieChartSectionData(
        color: AppColors.gold,
        value: 20,
        title: '',
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your reading personality',
            style: AppText.display(18),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

