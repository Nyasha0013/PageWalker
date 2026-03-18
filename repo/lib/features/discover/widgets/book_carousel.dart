import 'package:flutter/material.dart';

import '../../../core/widgets/book_cover_widget.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_text.dart';

class BookCarousel extends StatelessWidget {
  final String title;

  const BookCarousel({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.bodySemiBold(14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return const BookCoverWidget(
                  width: 70,
                  height: 100,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

