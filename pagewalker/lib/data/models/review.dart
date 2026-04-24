class Review {
  final String id;
  final String userId;
  final String bookId;
  final String content;
  final bool containsSpoilers;
  final int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? starRating;

  /// Denormalized on `reviews` when present (see `reviews_catalog_columns.sql`).
  final String? bookTitle;
  final String? bookAuthor;
  final String? bookCoverUrl;

  const Review({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.content,
    required this.containsSpoilers,
    required this.likesCount,
    required this.createdAt,
    required this.updatedAt,
    this.starRating,
    this.bookTitle,
    this.bookAuthor,
    this.bookCoverUrl,
  });

  factory Review.fromSupabase(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      content: json['content'] as String,
      containsSpoilers: json['contains_spoilers'] as bool? ?? false,
      likesCount: json['likes_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      starRating: (json['star_rating'] as num?)?.toDouble(),
      bookTitle: json['book_title'] as String?,
      bookAuthor: json['book_author'] as String?,
      bookCoverUrl: json['book_cover_url'] as String?,
    );
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'user_id': userId,
        'book_id': bookId,
        'content': content,
        'contains_spoilers': containsSpoilers,
        'likes_count': likesCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (starRating != null) 'star_rating': starRating,
        if (bookTitle != null) 'book_title': bookTitle,
        if (bookAuthor != null) 'book_author': bookAuthor,
        if (bookCoverUrl != null) 'book_cover_url': bookCoverUrl,
      };
}
