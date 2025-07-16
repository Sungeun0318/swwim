class Comment {
  final String author;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.author,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      author: json['author'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'author': author,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
}

class CommunityPost {
  final String id;
  final String author;
  final String avatarUrl;
  final String title;
  final String content;
  final List<Comment> comments;
  final int likes;
  final int shares;
  final DateTime? createdAt; // 추가

  CommunityPost({
    required this.id,
    required this.author,
    required this.avatarUrl,
    required this.title,
    required this.content,
    List<Comment>? comments,
    this.likes = 0,
    this.shares = 0,
    this.createdAt, // 추가
  }) : comments = comments ?? [];

  factory CommunityPost.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        createdAt = DateTime.tryParse(json['createdAt']);
      } else if (json['createdAt'] is DateTime) {
        createdAt = json['createdAt'];
      } else if (json['createdAt'].toString().contains('Timestamp')) {
        // Firestore Timestamp 지원
        createdAt = (json['createdAt'] as dynamic).toDate();
      }
    }
    return CommunityPost(
      id: id ?? '',
      author: json['author'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      comments: (json['comments'] as List<dynamic>?)
          ?.map((comment) {
            if (comment is String) {
              return Comment(author: '익명', content: comment);
            } else {
              return Comment.fromJson(comment);
            }
          })
          .toList() ?? [],
      likes: json['likes'] ?? 0,
      shares: json['shares'] ?? 0,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'author': author,
    'avatarUrl': avatarUrl,
    'title': title,
    'content': content,
    'comments': comments.map((comment) => comment.toJson()).toList(),
    'likes': likes,
    'shares': shares,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };
}