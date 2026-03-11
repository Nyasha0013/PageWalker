class Quote {
  final String id;
  final String userId;
  final String bookId;
  final String quote;
  final int? pageNumber;
  final DateTime createdAt;

  const Quote({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.quote,
    this.pageNumber,
    required this.createdAt,
  });

  factory Quote.fromSupabase(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      quote: json['quote'] as String,
      pageNumber: json['page_number'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'user_id': userId,
        'book_id': bookId,
        'quote': quote,
        'page_number': pageNumber,
        'created_at': createdAt.toIso8601String(),
      };
}

