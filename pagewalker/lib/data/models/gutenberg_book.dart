class GutenbergBook {
  final int id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? htmlUrl;
  final String? textUrl;
  final List<String> subjects;
  final int downloadCount;
  final bool copyright;

  const GutenbergBook({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.htmlUrl,
    this.textUrl,
    this.subjects = const [],
    this.downloadCount = 0,
    this.copyright = false,
  });

  String get supabaseBookId => 'gutenberg_$id';

  factory GutenbergBook.fromJson(Map<String, dynamic> json) {
    final formats = json['formats'] as Map<String, dynamic>? ?? {};
    final authors = json['authors'] as List<dynamic>? ?? [];

    String authorName = 'Unknown Author';
    if (authors.isNotEmpty) {
      final raw = authors[0]['name'] as String? ?? '';
      final parts = raw.split(', ');
      authorName = parts.length >= 2
          ? '${parts[1]} ${parts[0]}'.trim()
          : raw;
    }

    String? cover = formats['image/jpeg'] as String?;
    if (cover != null && !cover.contains('medium')) {
      for (final e in formats.entries) {
        final v = e.value;
        if (e.key.contains('image') &&
            v is String &&
            v.contains('medium')) {
          cover = v;
          break;
        }
      }
    }

    String? htmlUrl = formats['text/html'] as String?;
    if (htmlUrl == null) {
      for (final e in formats.entries) {
        if (e.key.startsWith('text/html') && e.value is String) {
          htmlUrl = e.value as String;
          break;
        }
      }
    }

    String? textUrl = formats['text/plain; charset=utf-8'] as String?;
    if (textUrl == null) {
      for (final e in formats.entries) {
        if (e.key.startsWith('text/plain') && e.value is String) {
          textUrl = e.value as String;
          break;
        }
      }
    }

    return GutenbergBook(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Unknown Title',
      author: authorName,
      coverUrl: cover,
      htmlUrl: htmlUrl,
      textUrl: textUrl,
      subjects: List<String>.from(
        (json['subjects'] as List<dynamic>? ?? [])
            .map((s) => s.toString())
            .take(5),
      ),
      downloadCount: json['download_count'] as int? ?? 0,
      copyright: json['copyright'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toBookMap() => {
        'id': supabaseBookId,
        'title': title,
        'author': author,
        'cover_url': coverUrl,
        'description': subjects.take(3).join(', '),
        'genre': subjects.take(3).toList(),
      };
}
