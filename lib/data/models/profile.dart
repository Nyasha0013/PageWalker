class Profile {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final int? age;
  final String? location;
  final String? instagramHandle;
  final String? facebookName;
  final String? favouriteGenre;
  final int readingGoal;
  final bool isPublic;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.age,
    this.location,
    this.instagramHandle,
    this.facebookName,
    this.favouriteGenre,
    this.readingGoal = 12,
    this.isPublic = true,
    required this.createdAt,
  });

  factory Profile.fromSupabase(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      age: json['age'] as int?,
      location: json['location'] as String?,
      instagramHandle: json['instagram_handle'] as String?,
      facebookName: json['facebook_name'] as String?,
      favouriteGenre: json['favourite_genre'] as String?,
      readingGoal: json['reading_goal'] as int? ?? 12,
      isPublic: json['is_public'] as bool? ?? true,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toSupabase() => {
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'bio': bio,
        'age': age,
        'location': location,
        'instagram_handle': instagramHandle,
        'facebook_name': facebookName,
        'favourite_genre': favouriteGenre,
        'reading_goal': readingGoal,
        'is_public': isPublic,
      };
}

