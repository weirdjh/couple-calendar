import '../../../photos/domain/models/photo_attachment.dart';
import '../../domain/models/review.dart';
import 'review_repository.dart';

class MockReviewRepository implements ReviewRepository {
  final Map<String, List<Review>> _reviewsByCouple = {};
  var _nextId = 2;

  @override
  Future<List<Review>> fetchReviews({
    required String coupleId,
    required String userId,
  }) async {
    return List.unmodifiable(_ensureSeeded(coupleId: coupleId, userId: userId));
  }

  @override
  Future<Review> createReview({
    required String coupleId,
    required String userId,
    required ReviewDraft draft,
  }) async {
    final reviews = _ensureSeeded(coupleId: coupleId, userId: userId);
    final now = DateTime.now();
    final review = Review(
      id: 'review-${_nextId++}',
      coupleId: coupleId,
      type: draft.type,
      title: draft.title,
      rating: draft.rating,
      memo: draft.memo,
      photos: photoAttachmentsFromLabels(draft.photoLabels),
      dateRecordId: draft.dateRecordId,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );
    _reviewsByCouple[coupleId] = [review, ...reviews];
    return review;
  }

  @override
  Future<Review> updateReview({
    required String coupleId,
    required String userId,
    required Review review,
  }) async {
    _reviewsByCouple[coupleId] =
        _reviewsByCouple[coupleId]
            ?.map((item) => item.id == review.id ? review : item)
            .toList() ??
        [review];
    return review;
  }

  @override
  Future<void> deleteReview({
    required String coupleId,
    required String reviewId,
    required String userId,
  }) async {
    _reviewsByCouple[coupleId] =
        _reviewsByCouple[coupleId]
            ?.where((review) => review.id != reviewId)
            .toList() ??
        const [];
  }

  List<Review> _ensureSeeded({
    required String coupleId,
    required String userId,
  }) {
    return _reviewsByCouple.putIfAbsent(
      coupleId,
      () => _seed(coupleId: coupleId, userId: userId),
    );
  }

  List<Review> _seed({required String coupleId, required String userId}) {
    final now = DateTime.now();
    return [
      Review(
        id: 'review-1',
        coupleId: coupleId,
        type: ReviewType.movie,
        title: '영화 리뷰',
        rating: 4.5,
        memo: '같이 보고 나서 얘기할 게 많았던 영화.',
        photos: const [PhotoAttachment(id: 'photo-1', label: '영화 티켓')],
        dateRecordId: 'date-record-2',
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
