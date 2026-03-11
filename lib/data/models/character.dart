class CharacterNote {
  final String id;
  final String userId;
  final String bookId;
  final String name;
  final int rankPosition;
  final String? notes;

  const CharacterNote({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.name,
    required this.rankPosition,
    this.notes,
  });

  factory CharacterNote.fromSupabase(Map<String, dynamic> json) {
    return CharacterNote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      name: json['character_name'] as String,
      rankPosition: json['rank_position'] as int,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'user_id': userId,
        'book_id': bookId,
        'character_name': name,
        'rank_position': rankPosition,
        'notes': notes,
      };
}

