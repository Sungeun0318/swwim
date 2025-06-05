class CommunityPost {
  final String author;
  final String avatarUrl;
  final String title;
  final String content;
  final List<String> comments;

  CommunityPost({
    required this.author,
    required this.avatarUrl,
    required this.title,
    required this.content,
    List<String>? comments,
  }) : comments = comments ?? [];

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      author: json['author'],
      avatarUrl: json['avatarUrl'],
      title: json['title'],
      content: json['content'],
      comments: List<String>.from(json['comments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'author': author,
    'avatarUrl': avatarUrl,
    'title': title,
    'content': content,
    'comments': comments,
  };
}