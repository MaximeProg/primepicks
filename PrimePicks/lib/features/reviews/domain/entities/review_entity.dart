class ReviewEntity {
  final String id;
  final int rating;
  final String? comment;
  final String? authorName;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.rating,
    this.comment,
    this.authorName,
    required this.createdAt,
  });
}
