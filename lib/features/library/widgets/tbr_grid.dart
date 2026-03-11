import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/book_cover_widget.dart';

class TbrGrid extends StatelessWidget {
  const TbrGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            itemCount: 10,
            gridDelegate:
                const SliverMasonryGridDelegate(
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              crossAxisCount: 2,
            ),
            itemBuilder: (context, index) {
              final height =
                  index.isEven ? 170.0 : 200.0;
              final id = 'demo-$index';
              return Align(
                alignment: Alignment.topCenter,
                child: BookCoverWidget(
                  width: (constraints.maxWidth - 12) / 2,
                  height: height,
                  heroTag: 'book-cover-$id',
                  onTap: () {
                    context.push('/book/$id');
                  },
                )
                    .animate()
                    .fadeIn(
                      delay: (index * 60).ms,
                      duration: 400.ms,
                    )
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    );
            },
          );
        },
      ),
    );
  }
}

// Using a simple Masonry delegate to avoid extra dependency wiring
class SliverMasonryGridDelegate
    extends SliverGridDelegate {
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const SliverMasonryGridDelegate({
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
  });

  @override
  SliverGridLayout getLayout(
    SliverConstraints constraints,
  ) {
    final usableCrossAxisExtent = constraints.crossAxisExtent -
        (crossAxisCount - 1) * crossAxisSpacing;
    final crossAxisStride =
        usableCrossAxisExtent / crossAxisCount +
            crossAxisSpacing;

    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: 200 + mainAxisSpacing,
      crossAxisStride: crossAxisStride,
      childMainAxisExtent: 200,
      childCrossAxisExtent:
          usableCrossAxisExtent / crossAxisCount,
      reverseCrossAxis:
          axisDirectionIsReversed(
        constraints.crossAxisDirection,
      ),
    );
  }

  @override
  bool shouldRelayout(
    covariant SliverMasonryGridDelegate oldDelegate,
  ) {
    return oldDelegate.crossAxisCount != crossAxisCount ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing;
  }
}

