import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/env.dart';
import '../../core/utils/catalog_text_utils.dart';
import '../../core/utils/url_utils.dart';
import '../models/catalog_book.dart';

class PagewalkerBooksApi {
  static const _timeout = Duration(seconds: 15);
  static const _userAgent = 'Pagewalker/6.0 Flutter';
  static const _cacheTtl = Duration(minutes: 5);

  final Map<String, (List<CatalogBook> books, DateTime expires)> _searchCache = {};
  final Map<String, (CatalogBook? book, DateTime expires)> _detailCache = {};

  bool _cacheFresh(DateTime expires) => DateTime.now().isBefore(expires);

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${Env.apiBaseUrl}$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      };

  Future<List<CatalogBook>> search({
    required String query,
    int maxResults = 20,
  }) async {
    final cacheKey = 'search::$query::$maxResults';
    final hit = _searchCache[cacheKey];
    if (hit != null && _cacheFresh(hit.$2)) return hit.$1;

    final response = await http
        .get(
          _uri('/api/books', {
            'type': 'search',
            'q': query,
            'maxResults': '$maxResults',
          }),
          headers: _headers,
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('PagewalkerBooksApi search ${response.statusCode}');
      }
      return [];
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = data['books'] as List<dynamic>? ?? [];
    final books = rows
        .map((row) => _mapApiBook(row as Map<String, dynamic>))
        .whereType<CatalogBook>()
        .toList();
    _searchCache[cacheKey] = (books, DateTime.now().add(_cacheTtl));
    return books;
  }

  Future<List<CatalogBook>> trending({int maxResults = 10}) async {
    final cacheKey = 'trending::$maxResults';
    final hit = _searchCache[cacheKey];
    if (hit != null && _cacheFresh(hit.$2)) return hit.$1;

    final response = await http
        .get(
          _uri('/api/books', {
            'type': 'trending',
            'maxResults': '$maxResults',
          }),
          headers: _headers,
        )
        .timeout(_timeout);
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = data['books'] as List<dynamic>? ?? [];
    final books = rows
        .map((row) => _mapApiBook(row as Map<String, dynamic>))
        .whereType<CatalogBook>()
        .toList();
    _searchCache[cacheKey] = (books, DateTime.now().add(_cacheTtl));
    return books;
  }

  Future<CatalogBook?> detail(String id) async {
    final hit = _detailCache[id];
    if (hit != null && _cacheFresh(hit.$2)) return hit.$1;

    final response = await http
        .get(
          _uri('/api/books', {'type': 'detail', 'id': id}),
          headers: _headers,
        )
        .timeout(_timeout);
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final book = _mapApiBook(data);
    _detailCache[id] = (book, DateTime.now().add(_cacheTtl));
    return book;
  }

  CatalogBook? _mapApiBook(Map<String, dynamic> json) {
    final sourceStr = json['source'] as String? ?? '';
    final BookSource source;
    switch (sourceStr) {
      case 'google':
        source = BookSource.googleBooks;
      case 'openlibrary':
        source = BookSource.openLibrary;
      case 'gutenberg':
        source = BookSource.gutenberg;
      default:
        return null;
    }

    final id = json['id'] as String? ?? '';
    if (id.isEmpty) return null;

    int? gutenbergId;
    if (id.startsWith('gutenberg_')) {
      gutenbergId = int.tryParse(id.replaceFirst('gutenberg_', ''));
    }

    final yearRaw = json['publishedYear'];
    final publishedYear = yearRaw is int
        ? yearRaw
        : int.tryParse('${yearRaw ?? ''}');

    final descriptionRaw = json['description'] as String?;
    final description = (descriptionRaw == null || descriptionRaw.trim().isEmpty)
        ? null
        : descriptionRaw;

    return CatalogBook(
      id: id,
      title: sanitizeCatalogTitle(
        json['title'] as String? ?? 'Unknown Title',
      ),
      author: json['author'] as String? ?? 'Unknown Author',
      coverUrl: httpsCoverUrl(json['coverUrl'] as String?),
      description: description,
      genres: List<String>.from(json['genres'] as List<dynamic>? ?? []),
      publishedYear: publishedYear,
      source: source,
      gutenbergNumericId: gutenbergId,
      googleAverageRating: (json['googleRating'] as num?)?.toDouble(),
    );
  }
}
