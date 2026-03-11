import 'package:flutter/material.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/widgets/book_cover_widget.dart';
import '../../../core/widgets/glass_card.dart';

class ReadingWrapWidget extends StatelessWidget {
  final String periodLabel;

  const ReadingWrapWidget({
    super.key,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            periodLabel,
            style: AppText.bodySemiBold(14),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              BookCoverWidget(width: 50, height: 75),
              SizedBox(width: 6),
              BookCoverWidget(width: 50, height: 75),
              SizedBox(width: 6),
              BookCoverWidget(width: 50, height: 75),
            ],
          ),
        ],
      ),
    );
  }
}

