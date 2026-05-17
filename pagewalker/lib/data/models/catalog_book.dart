enum BookSource { gutenberg, googleBooks, openLibrary }

class CatalogBook {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final int? pageCount;
  final List<String> genres;
  final int? publishedYear;
  final BookSource source;
  final int? gutenbergNumericId;
  final double? googleAverageRating;
  final int? googleRatingsCount;
  final String? externalPreviewUrl;

  const CatalogBook({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.description,
    this.pageCount,
    this.genres = const [],
    this.publishedYear,
    required this.source,
    this.gutenbergNumericId,
    this.googleAverageRating,
    this.googleRatingsCount,
    this.externalPreviewUrl,
  });

  String get sourceLabel {
    switch (source) {
      case BookSource.gutenberg:
        return 'Project Gutenberg';
      case BookSource.googleBooks:
        return 'Google Books';
      case BookSource.openLibrary:
        return 'Open Library';
    }
  }

  bool get hasGutenbergLink => gutenbergNumericId != null;

  Map<String, dynamic> toSupabaseBook() => {
        'id': id,
        'title': title,
        'author': author,
        'cover_url': coverUrl,
        'description': description,
        'page_count': pageCount,
        'genre': genres,
        'published_year': publishedYear,
      };
}

const Map<String, String> kCatalogGenreMap = {
  'Romance': 'romance',
  'Mystery': 'mystery',
  'Adventure': 'adventure',
  'Horror': 'horror',
  'History': 'history',
  'Science': 'science',
  'Drama': 'drama',
  'Philosophy': 'philosophy',
  'Travel': 'travel',
  'Humour': 'humor',
  'Gothic': 'gothic',
  'Detective': 'detective',
  'Science Fiction': 'science fiction',
  'Fantasy': 'fantasy',
  'Biography': 'biography',
  'Comedy': 'comedy',
  'Nature': 'nature',
  'Sci-Fi': 'science fiction',
  'Love Stories': 'love',
};
