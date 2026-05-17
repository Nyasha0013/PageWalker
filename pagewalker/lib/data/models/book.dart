import '../../core/utils/url_utils.dart';
import 'catalog_book.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final int? pageCount;
  final List<String> genres;
  final int? publishedYear;
  final String? isbn;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.description,
    this.pageCount,
    this.genres = const [],
    this.publishedYear,
    this.isbn,
  });

  factory Book.fromGoogleBooks(Map<String, dynamic> json) {
    final volumeInfo =
        json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks =
        volumeInfo['imageLinks'] as Map<String, dynamic>? ?? {};
    String? cover = imageLinks['thumbnail'] as String?;
    cover = fixCoverUrl(cover);
    return Book(
      id: json['id'] as String,
      title: volumeInfo['title'] as String? ?? 'Unknown Title',
      author: () {
        final a = volumeInfo['authors'];
        if (a is! List) return 'Unknown Author';
        final s = a
            .map((e) => e.toString())
            .where((x) => x.isNotEmpty)
            .join(', ');
        return s.isEmpty ? 'Unknown Author' : s;
      }(),
      coverUrl: cover,
      description: volumeInfo['description'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      genres: List<String>.from(volumeInfo['categories'] ?? []),
      publishedYear: int.tryParse(
        (volumeInfo['publishedDate'] as String? ?? '')
            .split('-')
            .first,
      ),
      isbn: ((volumeInfo['industryIdentifiers']
                      as List<dynamic>?) ??
                  [])
              .firstWhere(
                (e) => e['type'] == 'ISBN_13',
                orElse: () => {'identifier': null},
              )['identifier']
          as String?,
    );
  }

  factory Book.fromCatalogBook(CatalogBook c) {
    return Book(
      id: c.id,
      title: c.title,
      author: c.author,
      coverUrl: c.coverUrl,
      description: c.description,
      pageCount: c.pageCount,
      genres: c.genres,
      publishedYear: c.publishedYear,
      isbn: null,
    );
  }

  factory Book.fromSupabase(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String? ?? '',
      coverUrl: httpsCoverUrl(json['cover_url'] as String?),
      description: json['description'] as String?,
      pageCount: json['page_count'] as int?,
      genres: List<String>.from(json['genre'] ?? []),
      publishedYear: json['published_year'] as int?,
      isbn: json['isbn'] as String?,
    );
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'title': title,
        'author': author,
        'cover_url': coverUrl,
        'description': description,
        'page_count': pageCount,
        'genre': genres,
        'published_year': publishedYear,
        'isbn': isbn,
      };
}

