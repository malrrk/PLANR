class UserProfile {
  final String uid;
  final String displayName;
  final String username;
  final String usernameLower;
  final String email;
  final String? photoUrl;
  final String? bio;
  final String? backgroundImageUrl;
  final int score;
  final int hostedEventCount;
  final int joinedEventCount;
  final List<String> pinnedStoryImageUrls;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.usernameLower,
    required this.email,
    this.photoUrl,
    this.bio,
    this.backgroundImageUrl,
    this.score = 0,
    this.hostedEventCount = 0,
    this.joinedEventCount = 0,
    this.pinnedStoryImageUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'username': username,
      'usernameLower': usernameLower,
      'photoUrl': photoUrl,
      'bio': bio,
      'backgroundImageUrl': backgroundImageUrl,
      'score': score,
      'hostedEventCount': hostedEventCount,
      'joinedEventCount': joinedEventCount,
      'pinnedStoryImageUrls': pinnedStoryImageUrls,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String? ?? 'User',
      username: map['username'] as String? ?? '',
      usernameLower: map['usernameLower'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      backgroundImageUrl: map['backgroundImageUrl'] as String?,
      score: (map['score'] as num?)?.toInt() ?? 0,
      hostedEventCount: (map['hostedEventCount'] as num?)?.toInt() ?? 0,
      joinedEventCount: (map['joinedEventCount'] as num?)?.toInt() ?? 0,
      pinnedStoryImageUrls:
          (map['pinnedStoryImageUrls'] as List<dynamic>?)
                  ?.whereType<String>()
                  .toList() ??
              const [],
    );
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? username,
    String? usernameLower,
    String? email,
    String? photoUrl,
    String? bio,
    String? backgroundImageUrl,
    int? score,
    int? hostedEventCount,
    int? joinedEventCount,
    List<String>? pinnedStoryImageUrls,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      usernameLower: usernameLower ?? this.usernameLower,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      score: score ?? this.score,
      hostedEventCount: hostedEventCount ?? this.hostedEventCount,
      joinedEventCount: joinedEventCount ?? this.joinedEventCount,
      pinnedStoryImageUrls:
          pinnedStoryImageUrls ?? this.pinnedStoryImageUrls,
    );
  }
}