import '../../domain/models/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> fetchReviews({
    required String coupleId,
    required String userId,
  });

  Future<Review> createReview({
    required String coupleId,
    required String userId,
    required ReviewDraft draft,
  });

  Future<Review> updateReview({
    required String coupleId,
    required String userId,
    required Review review,
  });

  Future<void> deleteReview({
    required String coupleId,
    required String reviewId,
    required String userId,
  });
}

class ReviewDraft {
  const ReviewDraft({
    required this.type,
    required this.title,
    required this.rating,
    this.memo = '',
    this.photoLabels = const [],
    this.dateRecordId,
  });

  final ReviewType type;
  final String title;
  final double rating;
  final String memo;
  final List<String> photoLabels;
  final String? dateRecordId;
}
