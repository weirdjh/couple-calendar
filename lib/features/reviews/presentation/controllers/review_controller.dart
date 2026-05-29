import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../date_records/presentation/controllers/date_record_controller.dart';
import '../../../links/application/api_link_use_case_client.dart';
import '../../../photos/domain/models/photo_attachment.dart';
import '../../data/repositories/api_review_repository.dart';
import '../../data/repositories/firestore_review_repository.dart';
import '../../data/repositories/mock_review_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../domain/models/review.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  if (useApi) {
    return ApiReviewRepository(baseUrl: apiBaseUrl);
  }
  if (useFirebase) {
    return FirestoreReviewRepository();
  }
  return MockReviewRepository();
});

final reviewControllerProvider =
    NotifierProvider<ReviewController, ReviewState>(ReviewController.new);

class ReviewState {
  const ReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final List<Review> reviews;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  Review? reviewById(String reviewId) {
    return reviews.where((review) => review.id == reviewId).firstOrNull;
  }

  List<Review> reviewsForDateRecord(String dateRecordId) {
    return reviews
        .where((review) => review.dateRecordId == dateRecordId)
        .toList();
  }

  ReviewState copyWith({
    List<Review>? reviews,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ReviewController extends Notifier<ReviewState> {
  late final ReviewRepository _repository;

  @override
  ReviewState build() {
    _repository = ref.watch(reviewRepositoryProvider);
    final session = ref.watch(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      return const ReviewState();
    }
    Future.microtask(_loadReviews);
    return const ReviewState(isLoading: true);
  }

  Future<Review?> addReview({
    required ReviewType type,
    required String title,
    required double rating,
    String memo = '',
    List<String> photoLabels = const [],
    String? dateRecordId,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: '리뷰 제목을 입력해 주세요.');
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final review = await _repository.createReview(
        coupleId: couple.id,
        userId: user.id,
        draft: ReviewDraft(
          type: type,
          title: trimmedTitle,
          rating: rating.clamp(0, 5).toDouble(),
          memo: memo.trim(),
          photoLabels: photoLabels,
          dateRecordId: dateRecordId,
        ),
      );
      state = state.copyWith(
        reviews: [review, ...state.reviews],
        isSaving: false,
      );
      return review;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '리뷰를 저장하지 못했어요.');
      return null;
    }
  }

  Future<Review?> updateReview({
    required String reviewId,
    required ReviewType type,
    required String title,
    required double rating,
    String memo = '',
    List<String> photoLabels = const [],
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: '리뷰 제목을 입력해 주세요.');
      return null;
    }

    final review = state.reviewById(reviewId);
    if (review == null) {
      state = state.copyWith(errorMessage: '리뷰를 찾을 수 없어요.');
      return null;
    }
    final user = ref.read(sessionControllerProvider).currentUser;
    if (user == null) {
      state = state.copyWith(errorMessage: '로그인이 필요해요.');
      return null;
    }
    final updatedReview = review.copyWith(
      type: type,
      title: trimmedTitle,
      rating: rating.clamp(0, 5).toDouble(),
      memo: memo.trim(),
      photos: photoAttachmentsFromLabels(photoLabels),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _repository.updateReview(
        coupleId: review.coupleId,
        userId: user.id,
        review: updatedReview,
      );
      state = state.copyWith(
        reviews: state.reviews
            .map((item) => item.id == reviewId ? saved : item)
            .toList(),
        isSaving: false,
      );
      return saved;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '리뷰를 수정하지 못했어요.');
      return null;
    }
  }

  Future<Review?> linkDateRecord({
    required String reviewId,
    required String dateRecordId,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    final review = state.reviewById(reviewId);
    if (review == null) {
      state = state.copyWith(errorMessage: '리뷰를 찾을 수 없어요.');
      return null;
    }
    if (useApi) {
      if (user == null || couple == null) {
        state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
        return null;
      }
      state = state.copyWith(isSaving: true, clearError: true);
      try {
        final result = await ref
            .read(apiLinkUseCaseClientProvider)
            .linkReviewToDateRecord(
              coupleId: couple.id,
              userId: user.id,
              reviewId: reviewId,
              recordId: dateRecordId,
            );
        state = state.copyWith(
          reviews: state.reviews
              .map((item) => item.id == reviewId ? result.review : item)
              .toList(),
          isSaving: false,
        );
        await ref
            .read(dateRecordControllerProvider.notifier)
            .refreshDateRecords();
        return result.review;
      } catch (_) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: '데이트 기록 연결을 저장하지 못했어요.',
        );
        return null;
      }
    }
    return _saveReview(
      review.copyWith(dateRecordId: dateRecordId, updatedAt: DateTime.now()),
      errorMessage: '데이트 기록 연결을 저장하지 못했어요.',
    );
  }

  Future<Review?> unlinkDateRecord(String reviewId) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    final review = state.reviewById(reviewId);
    if (review == null) {
      state = state.copyWith(errorMessage: '리뷰를 찾을 수 없어요.');
      return null;
    }
    if (useApi) {
      final recordId = review.dateRecordId;
      if (user == null || couple == null || recordId == null) {
        state = state.copyWith(errorMessage: '데이트 기록 연결을 찾을 수 없어요.');
        return null;
      }
      state = state.copyWith(isSaving: true, clearError: true);
      try {
        final result = await ref
            .read(apiLinkUseCaseClientProvider)
            .unlinkReviewFromDateRecord(
              coupleId: couple.id,
              userId: user.id,
              reviewId: reviewId,
              recordId: recordId,
            );
        state = state.copyWith(
          reviews: state.reviews
              .map((item) => item.id == reviewId ? result.review : item)
              .toList(),
          isSaving: false,
        );
        await ref
            .read(dateRecordControllerProvider.notifier)
            .refreshDateRecords();
        return result.review;
      } catch (_) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: '데이트 기록 연결을 해제하지 못했어요.',
        );
        return null;
      }
    }
    return _saveReview(
      review.copyWith(clearDateRecordId: true, updatedAt: DateTime.now()),
      errorMessage: '데이트 기록 연결을 해제하지 못했어요.',
    );
  }

  Future<void> deleteReview(String reviewId) async {
    final session = ref.read(sessionControllerProvider);
    final couple = session.currentCouple;
    final user = session.currentUser;
    if (couple == null || user == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      if (useApi) {
        await ref
            .read(apiLinkUseCaseClientProvider)
            .deleteReviewEverywhere(
              coupleId: couple.id,
              userId: user.id,
              reviewId: reviewId,
            );
        await ref
            .read(dateRecordControllerProvider.notifier)
            .refreshDateRecords();
      } else {
        await _repository.deleteReview(
          coupleId: couple.id,
          reviewId: reviewId,
          userId: user.id,
        );
      }
      state = state.copyWith(
        reviews: state.reviews
            .where((review) => review.id != reviewId)
            .toList(),
        isSaving: false,
      );
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '리뷰를 삭제하지 못했어요.');
    }
  }

  Future<Review?> _saveReview(
    Review review, {
    required String errorMessage,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _repository.updateReview(
        coupleId: review.coupleId,
        userId:
            ref.read(sessionControllerProvider).currentUser?.id ??
            review.createdBy,
        review: review,
      );
      state = state.copyWith(
        reviews: state.reviews
            .map((item) => item.id == review.id ? saved : item)
            .toList(),
        isSaving: false,
      );
      return saved;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: errorMessage);
      return null;
    }
  }

  Future<void> refreshReviews() {
    return _loadReviews();
  }

  Future<void> _loadReviews() async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = const ReviewState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reviews = await _repository.fetchReviews(
        coupleId: couple.id,
        userId: user.id,
      );
      state = state.copyWith(reviews: reviews, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: '리뷰를 불러오지 못했어요.');
    }
  }
}
