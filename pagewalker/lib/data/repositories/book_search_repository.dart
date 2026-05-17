import 'package:flutter/foundation.dart';

import '../../core/config/env.dart';
import '../models/book_detail.dart';
import 'catalog_book_repository.dart';

class BookSearchRepository {
  final _inner = CatalogBookRepository();

  Future<List<BookDetail>> searchBooks(String query) async {
    if (!Env.hasGoogleBooksApiKey && kDebugMode) {
      debugPrint('Google Books skipped (no API key)');
    }
    final list = await _inner.searchAll(query);
    return list.map(BookDetail.fromCatalogBook).toList();
  }

  Future<List<BookDetail>> getPopularBooks() async {
    final list = await _inner.getPopularGutenberg();
    return list.map(BookDetail.fromCatalogBook).toList();
  }

  Future<List<BookDetail>> browseByGenre(String genre) async {
    final list = await _inner.browseByGenre(genre);
    return list.map(BookDetail.fromCatalogBook).toList();
  }
}
