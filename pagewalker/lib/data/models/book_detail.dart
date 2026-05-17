import 'catalog_book.dart';

enum BookReadType { readableInApp, trackOnly }

// Older search/detail shape; built from CatalogBook.
class BookDetail {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? summary;
  final int? pageCount;
  final List<String> genres;
  final String? publishedYear;
  final String? publisher;
  final double? googleRating;
  final int? googleRatingsCount;
  final BookReadType readType;
  final String? gutenbergReadUrl;
  final String source;

  const BookDetail({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.summary,
    this.pageCount,
    this.genres = const [],
    this.publishedYear,
    this.publisher,
    this.googleRating,
    this.googleRatingsCount,
    required this.readType,
    this.gutenbergReadUrl,
    required this.source,
  });

  bool get isReadableInApp => readType == BookReadType.readableInApp;

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'title': title,
        'author': author,
        'cover_url': coverUrl,
        'description': summary,
        'page_count': pageCount,
        'genre': genres,
        'published_year': int.tryParse(publishedYear ?? ''),
      };

  factory BookDetail.fromCatalogBook(CatalogBook b) {
    final gutenUrl = b.gutenbergNumericId != null
        ? 'https://www.gutenberg.org/ebooks/${b.gutenbergNumericId}'
        : null;
    return BookDetail(
      id: b.id,
      title: b.title,
      author: b.author,
      coverUrl: b.coverUrl,
      summary: b.description,
      pageCount: b.pageCount,
      genres: b.genres,
      publishedYear: b.publishedYear?.toString(),
      publisher: null,
      googleRating: b.googleAverageRating,
      googleRatingsCount: b.googleRatingsCount,
      readType: BookReadType.trackOnly,
      gutenbergReadUrl: gutenUrl,
      source: switch (b.source) {
        BookSource.gutenberg => 'gutenberg',
        BookSource.googleBooks => 'google',
        BookSource.openLibrary => 'openlibrary',
      },
    );
  }
}
