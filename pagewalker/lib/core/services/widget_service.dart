import 'package:home_widget/home_widget.dart';

import '../../data/models/book.dart';

class WidgetService {
  static const _appGroupId = 'com.example.pagewalker';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateCurrentRead({
    required Book book,
    required int currentPage,
    required int totalPages,
  }) async {
    final progress = totalPages > 0
        ? ((currentPage / totalPages) * 100).round().clamp(0, 100)
        : 0;
    final pagesText = totalPages > 0
        ? 'Page $currentPage of $totalPages · ${100 - progress}% left'
        : 'Currently reading';

    await HomeWidget.saveWidgetData('widget_book_title', book.title);
    await HomeWidget.saveWidgetData('widget_author', book.author);
    await HomeWidget.saveWidgetData('widget_progress', progress);
    await HomeWidget.saveWidgetData('widget_pages', pagesText);
    await HomeWidget.updateWidget(
      androidName: 'PagewalkerWidget',
    );
  }

  static Future<void> clearCurrentRead() async {
    await HomeWidget.saveWidgetData('widget_book_title', 'No current read');
    await HomeWidget.saveWidgetData('widget_author', 'Add a book to start');
    await HomeWidget.saveWidgetData('widget_progress', 0);
    await HomeWidget.saveWidgetData('widget_pages', 'Tap to open Pagewalker');
    await HomeWidget.updateWidget(androidName: 'PagewalkerWidget');
  }
}

