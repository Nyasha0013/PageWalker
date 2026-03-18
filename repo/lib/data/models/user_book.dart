enum BookStatus { tbr, reading, read, dnf }

enum BookTier { godTier, aClass, bClass, cClass }

class UserBook {
  final String id;
  final String userId;
  final String bookId;
  final BookStatus status;
  final double? starRating;
  final BookTier? tier;
  final DateTime? dateStarted;
  final DateTime? dateFinished;
  final bool isFavorite;
  final DateTime createdAt;

  const UserBook({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    this.starRating,
    this.tier,
    this.dateStarted,
    this.dateFinished,
    this.isFavorite = false,
    required this.createdAt,
  });

  factory UserBook.fromSupabase(Map<String, dynamic> json) {
    return UserBook(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      status: BookStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookStatus.tbr,
      ),
      starRating: (json['star_rating'] as num?)?.toDouble(),
      tier: json['tier'] != null
          ? BookTier.values.firstWhere(
              (e) => e.name == _tierFromDb(json['tier'] as String),
              orElse: () => BookTier.cClass,
            )
          : null,
      dateStarted: json['date_started'] != null
          ? DateTime.parse(json['date_started'] as String)
          : null,
      dateFinished: json['date_finished'] != null
          ? DateTime.parse(json['date_finished'] as String)
          : null,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static String _tierFromDb(String db) {
    switch (db) {
      case 'god_tier':
        return 'godTier';
      case 'a_class':
        return 'aClass';
      case 'b_class':
        return 'bClass';
      case 'c_class':
        return 'cClass';
      default:
        return 'cClass';
    }
  }

  String get tierToDb {
    switch (tier) {
      case BookTier.godTier:
        return 'god_tier';
      case BookTier.aClass:
        return 'a_class';
      case BookTier.bClass:
        return 'b_class';
      case BookTier.cClass:
        return 'c_class';
      default:
        return 'c_class';
    }
  }
}

