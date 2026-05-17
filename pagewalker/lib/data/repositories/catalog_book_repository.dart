import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/env.dart';
import '../../core/utils/catalog_text_utils.dart';
import '../../core/utils/url_utils.dart';
import '../models/catalog_book.dart';

// Catalog search: Google Books, Open Library, Gutendex (Gutenberg links only).
class CatalogBookRepository {
  static const String _gutendexBase = 'https://gutendex.com';
  static const String _openLibraryBase = 'https://openlibrary.org';

  Uri _googleVolumesUri(Map<String, String> params) {
    return Uri(
      scheme: 'https',
      host: 'www.googleapis.com',
      path: '/books/v1/volumes',
      queryParameters: {...params, 'key': Env.googleBooksApiKey},
    );
  }

  Uri _googleVolumeByIdUri(String volumeId) {
    return Uri(
      scheme: 'https',
      host: 'www.googleapis.com',
      path: '/books/v1/volumes/$volumeId',
      queryParameters: {'key': Env.googleBooksApiKey},
    );
  }

  Future<List<CatalogBook>> searchAll(String query) async {
    if (Env.hasGoogleBooksApiKey) {
      final results = await Future.wait([
        _searchGutenberg(query),
        _searchGoogleBooks(query),
        _searchOpenLibrary(query),
      ]);
      return _mergeBooksByTitle([
        ...results[0],
        ...results[1],
        ...results[2],
      ]);
    }
    final results = await Future.wait([
      _searchGutenberg(query),
      _searchOpenLibrary(query),
    ]);
    return _mergeBooksByTitle([
      ...results[0],
      ...results[1],
    ]);
  }

  Future<CatalogBook?> getByCatalogId(String id) async {
    try {
      if (id.startsWith('gutenberg_')) {
        final n = int.tryParse(id.replaceFirst('gutenberg_', ''));
        if (n == null) return null;
        final uri = Uri.parse('$_gutendexBase/books/$n');
        final r = await http.get(uri).timeout(const Duration(seconds: 10));
        if (r.statusCode != 200) return null;
        return _mapGutenbergJson(jsonDecode(r.body) as Map<String, dynamic>);
      }
      if (id.startsWith('google_')) {
        final vid = id.replaceFirst('google_', '');
        final r = await http
            .get(_googleVolumeByIdUri(vid))
            .timeout(const Duration(seconds: 10));
        if (r.statusCode != 200) return null;
        final item = jsonDecode(r.body) as Map<String, dynamic>;
        return _parseGoogleBook(item);
      }
      if (id.startsWith('openlibrary_')) {
        final key = _openLibraryKeyFromId(id);
        if (key == null) return null;
        final uri = Uri.parse('$_openLibraryBase$key.json');
        final r = await http.get(uri).timeout(const Duration(seconds: 10));
        if (r.statusCode != 200) return null;
        final doc = jsonDecode(r.body) as Map<String, dynamic>;
        return _mapOpenLibraryWork(doc, key);
      }
    } catch (_) {}
    return null;
  }

  String? _openLibraryKeyFromId(String id) {
    if (!id.startsWith('openlibrary_')) return null;
    final rest = id.substring('openlibrary_'.length);
    final parts = rest.split('_');
    if (parts.isNotEmpty && parts[0] == 'works' && parts.length >= 2) {
      return '/works/${parts.sublist(1).join('_')}';
    }
    return '/$rest'.replaceAll('_', '/');
  }

  CatalogBook _mapGutenbergJson(Map<String, dynamic> json) {
    final formats = json['formats'] as Map<String, dynamic>? ?? {};
    final authors = json['authors'] as List<dynamic>? ?? [];
    String author = 'Unknown Author';
    if (authors.isNotEmpty) {
      final raw = authors[0]['name'] as String? ?? '';
      final parts = raw.split(', ');
      author = parts.length >= 2
          ? '${parts[1].trim()} ${parts[0].trim()}'
          : raw;
    }
    String? rawCover;
    for (final key in formats.keys) {
      if (key.contains('image')) {
        rawCover = formats[key] as String?;
        break;
      }
    }
    final bookId = json['id'] as int;
    var cover = httpsCoverUrl(rawCover?.replaceAll('http://', 'https://'));
    cover ??= httpsCoverUrl(
      'https://www.gutenberg.org/cache/epub/$bookId/pg$bookId.cover.medium.jpg',
    );
    return CatalogBook(
      id: 'gutenberg_$bookId',
      title: sanitizeCatalogTitle(
        json['title'] as String? ?? 'Unknown Title',
      ),
      author: author,
      coverUrl: cover,
      description: (json['subjects'] as List<dynamic>?)
          ?.take(5)
          .map((e) => e.toString())
          .join(', '),
      genres: List<String>.from(
        (json['subjects'] as List<dynamic>? ?? []).take(5).map((s) => '$s'),
      ),
      source: BookSource.gutenberg,
      gutenbergNumericId: bookId,
    );
  }

  Future<List<CatalogBook>> _searchGutenberg(String query) async {
    try {
      final uri = Uri.parse(
        '$_gutendexBase/books'
        '?search=${Uri.encodeComponent(query)}'
        '&languages=en&copyright=false',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      return results
          .map((e) => _mapGutenbergJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CatalogBook>> _searchGoogleBooks(String query) async {
    if (!Env.hasGoogleBooksApiKey) {
      if (kDebugMode) debugPrint('Google Books: no API key');
      return [];
    }
    try {
      final allUri = _googleVolumesUri({
        'q': query,
        'maxResults': '20',
        'langRestrict': 'en',
      });
      final freeUri = _googleVolumesUri({
        'q': query,
        'filter': 'free-ebooks',
        'maxResults': '10',
        'langRestrict': 'en',
      });
      final responses = await Future.wait([
        http.get(allUri).timeout(const Duration(seconds: 10)),
        http.get(freeUri).timeout(const Duration(seconds: 10)),
      ]);
      final books = <String, CatalogBook>{};
      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final book = _parseGoogleBook(item as Map<String, dynamic>);
          if (book != null) books[book.id] = book;
        }
      } else if (kDebugMode) {
        debugPrint('Google Books ${responses[0].statusCode}: ${responses[0].body}');
      }
      if (responses[1].statusCode == 200) {
        final data = jsonDecode(responses[1].body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final book = _parseGoogleBook(item as Map<String, dynamic>);
          if (book != null) books[book.id] = book;
        }
      }
      return books.values.toList();
    } catch (e, st) {
      debugPrint('Google Books exception: $e\n$st');
      return [];
    }
  }

  Future<List<CatalogBook>> getGoogleTrendingFiction({int maxResults = 10}) async {
    if (!Env.hasGoogleBooksApiKey) return [];
    try {
      final uri = _googleVolumesUri({
        'q': 'subject:fiction',
        'orderBy': 'relevance',
        'maxResults': '$maxResults',
        'langRestrict': 'en',
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      final out = <CatalogBook>[];
      for (final item in items) {
        final book = _parseGoogleBook(item as Map<String, dynamic>);
        if (book != null) out.add(book);
      }
      return out;
    } catch (e) {
      debugPrint('getGoogleTrendingFiction: $e');
      return [];
    }
  }

  Future<List<CatalogBook>> searchGoogleBooksForQuery(
    String query, {
    int maxResults = 5,
  }) async {
    if (!Env.hasGoogleBooksApiKey) return [];
    try {
      final uri = _googleVolumesUri({
        'q': query,
        'maxResults': '$maxResults',
        'langRestrict': 'en',
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      final out = <CatalogBook>[];
      for (final item in items) {
        final book = _parseGoogleBook(item as Map<String, dynamic>);
        if (book != null) out.add(book);
      }
      return out;
    } catch (e) {
      debugPrint('searchGoogleBooksForQuery: $e');
      return [];
    }
  }

  CatalogBook? _parseGoogleBook(Map<String, dynamic> json) {
    try {
      final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
      final accessInfo = json['accessInfo'] as Map<String, dynamic>? ?? {};
      final imageLinks =
          volumeInfo['imageLinks'] as Map<String, dynamic>? ?? {};
      String? cover = imageLinks['thumbnail'] as String? ??
          imageLinks['smallThumbnail'] as String?;
      cover = httpsCoverUrl(cover?.replaceAll('http://', 'https://'));
      if (cover != null) {
        cover = cover.replaceAll('zoom=1', 'zoom=3');
      }
      final webReader = accessInfo['webReaderLink'] as String?;
      final rawAuthors = volumeInfo['authors'];
      final authorList = rawAuthors is List
          ? rawAuthors.map((a) => a.toString()).where((s) => s.isNotEmpty).toList()
          : <String>[];
      final authorStr =
          authorList.isNotEmpty ? authorList.join(', ') : 'Unknown Author';
      return CatalogBook(
        id: 'google_${json['id']}',
        title: sanitizeCatalogTitle(
          volumeInfo['title'] as String? ?? 'Unknown Title',
        ),
        author: authorStr,
        coverUrl: cover,
        description: volumeInfo['description'] as String?,
        pageCount: volumeInfo['pageCount'] as int?,
        genres: List<String>.from(
          volumeInfo['categories'] as List<dynamic>? ?? [],
        ),
        publishedYear: int.tryParse(
          (volumeInfo['publishedDate'] as String? ?? '').split('-').first,
        ),
        source: BookSource.googleBooks,
        googleAverageRating:
            (volumeInfo['averageRating'] as num?)?.toDouble(),
        googleRatingsCount: volumeInfo['ratingsCount'] as int?,
        externalPreviewUrl: httpsCoverUrl(webReader),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<CatalogBook>> _searchOpenLibrary(String query) async {
    try {
      final uri = Uri.parse(
        '$_openLibraryBase/search.json'
        '?q=${Uri.encodeComponent(query)}'
        '&limit=15'
        '&language=eng'
        '&fields=key,title,author_name,cover_i,subject,'
        'first_publish_year,number_of_pages_median',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>? ?? [];
      return docs.map((doc) {
        return _mapOpenLibrarySearchDoc(doc as Map<String, dynamic>);
      }).toList();
    } catch (e, st) {
      debugPrint('Open Library exception: $e\n$st');
      return [];
    }
  }

  CatalogBook _mapOpenLibrarySearchDoc(Map<String, dynamic> doc) {
    final coverId = doc['cover_i'];
    String? coverUrl;
    if (coverId != null) {
      coverUrl = httpsCoverUrl(
        'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
      );
    }
    final authors = doc['author_name'] as List<dynamic>? ?? [];
    final rawKey = doc['key'] as String? ?? '';
    final idBody =
        rawKey.replaceAll('/', '_').replaceFirst(RegExp(r'^_+'), '');
    return CatalogBook(
      id: 'openlibrary_$idBody',
      title: sanitizeCatalogTitle(doc['title'] as String? ?? 'Unknown Title'),
      author: authors.isNotEmpty ? authors.join(', ') : 'Unknown Author',
      coverUrl: coverUrl,
      description: null,
      genres: List<String>.from(
        (doc['subject'] as List<dynamic>? ?? []).take(5).map((e) => '$e'),
      ),
      publishedYear: doc['first_publish_year'] as int?,
      pageCount: doc['number_of_pages_median'] as int?,
      source: BookSource.openLibrary,
    );
  }

  CatalogBook _mapOpenLibraryWork(Map<String, dynamic> doc, String key) {
    final authors = (doc['authors'] as List<dynamic>? ?? [])
        .map((a) {
          if (a is Map) return a['name'] ?? '';
          return '$a';
        })
        .where((s) => '$s'.isNotEmpty)
        .join(', ');
    final coverId = doc['covers'] != null && (doc['covers'] as List).isNotEmpty
        ? (doc['covers'] as List).first
        : null;
    String? coverUrl;
    if (coverId != null) {
      coverUrl = httpsCoverUrl(
        'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
      );
    }
    final desc = doc['description'];
    String? description;
    if (desc is String) {
      description = desc;
    } else if (desc is Map && desc['value'] != null) {
      description = desc['value'] as String?;
    }
    final idBody = key.replaceAll('/', '_').replaceFirst(RegExp(r'^_+'), '');
    return CatalogBook(
      id: 'openlibrary_$idBody',
      title: sanitizeCatalogTitle(doc['title'] as String? ?? 'Unknown Title'),
      author: authors.isNotEmpty ? authors : 'Unknown Author',
      coverUrl: coverUrl,
      description: description,
      genres: const [],
      source: BookSource.openLibrary,
    );
  }

  Future<List<CatalogBook>> getOpenLibrarySubjectSlice(
    String subjectKey, {
    int limit = 12,
  }) async {
    try {
      final uri = Uri.parse(
        'https://openlibrary.org/subjects/'
        '${Uri.encodeComponent(subjectKey)}.json?limit=$limit',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final works = data['works'] as List<dynamic>? ?? [];
      return works.map((e) {
        return _mapOpenLibrarySubjectWork(e as Map<String, dynamic>);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  CatalogBook _mapOpenLibrarySubjectWork(Map<String, dynamic> w) {
    final coverId = w['cover_id'];
    String? coverUrl;
    if (coverId != null) {
      coverUrl = httpsCoverUrl(
        'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
      );
    }
    final rawKey = w['key'] as String? ?? '';
    final idBody =
        rawKey.replaceAll('/', '_').replaceFirst(RegExp(r'^_+'), '');
    final authors = w['authors'] as List<dynamic>? ?? [];
    String author = 'Unknown Author';
    if (authors.isNotEmpty) {
      final first = authors.first;
      if (first is Map<String, dynamic>) {
        author = first['name'] as String? ?? 'Unknown Author';
      }
    }
    return CatalogBook(
      id: 'openlibrary_$idBody',
      title: sanitizeCatalogTitle(w['title'] as String? ?? 'Unknown Title'),
      author: author,
      coverUrl: coverUrl,
      description: null,
      genres: const [],
      source: BookSource.openLibrary,
    );
  }

  Future<List<CatalogBook>> getPopularMixed({int limit = 24}) async {
    final results = await Future.wait([
      getPopularGutenberg(),
      getOpenLibrarySubjectSlice('romance', limit: 16),
    ]);
    final merged = _mergeBooksByTitle([
      ...results[0],
      ...results[1],
    ]);
    if (merged.length <= limit) return merged;
    return merged.take(limit).toList();
  }

  Future<List<CatalogBook>> getPopularGutenberg() async {
    try {
      final uri = Uri.parse(
        '$_gutendexBase/books?languages=en&copyright=false&sort=popular',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      return results
          .take(10)
          .map((e) => _mapGutenbergJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CatalogBook>> getNewestGutenberg({int limit = 8}) async {
    try {
      final uri = Uri.parse(
        '$_gutendexBase/books?languages=en&copyright=false&sort=descending',
      );
      final r = await http.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      return results
          .take(limit)
          .map((e) => _mapGutenbergJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CatalogBook>> browseByGenre(String genre) async {
    if (Env.hasGoogleBooksApiKey) {
      final results = await Future.wait([
        _searchGutenberg(genre),
        _searchGoogleBooks('subject:$genre'),
        _searchOpenLibrary('subject:$genre'),
      ]);
      return _mergeBooksByTitle([
        ...results[0],
        ...results[1],
        ...results[2],
      ]);
    }
    final results = await Future.wait([
      _searchGutenberg(genre),
      _searchOpenLibrary('subject:$genre'),
    ]);
    return _mergeBooksByTitle([
      ...results[0],
      ...results[1],
    ]);
  }

  String _normaliseTitle(String title) =>
      title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  String? _firstDescription(CatalogBook a, CatalogBook b) {
    final da = a.description?.trim();
    if (da != null && da.isNotEmpty) return da;
    final db = b.description?.trim();
    if (db != null && db.isNotEmpty) return db;
    return null;
  }

  List<CatalogBook> _mergeBooksByTitle(List<CatalogBook> books) {
    final groups = <String, List<CatalogBook>>{};
    for (final b in books) {
      final k = _normaliseTitle(b.title);
      if (k.isEmpty) continue;
      groups.putIfAbsent(k, () => []).add(b);
    }
    return groups.values.map(_mergeBookGroup).toList();
  }

  CatalogBook _mergeBookGroup(List<CatalogBook> group) {
    if (group.length == 1) return group.first;

    CatalogBook? guten;
    CatalogBook? google;
    CatalogBook? openLib;
    for (final b in group) {
      switch (b.source) {
        case BookSource.gutenberg:
          guten = b;
          break;
        case BookSource.googleBooks:
          google = b;
          break;
        case BookSource.openLibrary:
          openLib = b;
          break;
      }
    }

    if (guten != null && guten.gutenbergNumericId != null && google != null) {
      final g = guten;
      final meta = google;
      return CatalogBook(
        id: meta.id,
        title: meta.title,
        author: meta.author,
        coverUrl: meta.coverUrl ?? g.coverUrl,
        description: _firstDescription(meta, g) ?? g.description,
        pageCount: meta.pageCount ?? g.pageCount,
        genres: meta.genres.isNotEmpty ? meta.genres : g.genres,
        publishedYear: meta.publishedYear ?? g.publishedYear,
        source: BookSource.googleBooks,
        gutenbergNumericId: g.gutenbergNumericId,
        googleAverageRating: meta.googleAverageRating,
        googleRatingsCount: meta.googleRatingsCount,
        externalPreviewUrl: meta.externalPreviewUrl,
      );
    }

    if (guten != null && guten.gutenbergNumericId != null && openLib != null) {
      final g = guten;
      final ol = openLib;
      return CatalogBook(
        id: g.id,
        title: g.title,
        author: g.author,
        coverUrl: ol.coverUrl ?? g.coverUrl,
        description: _firstDescription(ol, g) ?? g.description,
        pageCount: ol.pageCount ?? g.pageCount,
        genres: ol.genres.isNotEmpty ? ol.genres : g.genres,
        publishedYear: ol.publishedYear ?? g.publishedYear,
        source: BookSource.gutenberg,
        gutenbergNumericId: g.gutenbergNumericId,
      );
    }

    if (google != null && openLib != null) {
      return CatalogBook(
        id: google.id,
        title: google.title,
        author: google.author,
        coverUrl: google.coverUrl ?? openLib.coverUrl,
        description: _firstDescription(google, openLib) ?? openLib.description,
        pageCount: google.pageCount ?? openLib.pageCount,
        genres: google.genres.isNotEmpty ? google.genres : openLib.genres,
        publishedYear: google.publishedYear ?? openLib.publishedYear,
        source: BookSource.googleBooks,
        googleAverageRating: google.googleAverageRating,
        googleRatingsCount: google.googleRatingsCount,
        externalPreviewUrl: google.externalPreviewUrl,
      );
    }
    if (google != null) return google;
    if (openLib != null) return openLib;
    if (guten != null) return guten;
    return group.first;
  }
}
