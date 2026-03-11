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
    if (cover != null) {
      cover = cover.replaceAll('http://', 'https://');
    }
    return Book(
      id: json['id'] as String,
      title: volumeInfo['title'] as String? ?? 'Unknown Title',
      author: (volumeInfo['authors'] as List<dynamic>?)
              ?.join(', ') ??
          'Unknown Author',
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

  factory Book.fromSupabase(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
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

