import 'package:http/http.dart' as http;

import '../../../../core/api/api_client.dart';
import '../../../photos/domain/models/photo_attachment.dart';
import '../../domain/models/review.dart';
import 'review_repository.dart';

class ApiReviewRepository implements ReviewRepository {
  ApiReviewRepository({required String baseUrl, http.Client? client})
    : _api = ApiClient(baseUrl: baseUrl, client: client);

  final ApiClient _api;

  @override
  Future<List<Review>> fetchReviews({
    required String coupleId,
    required String userId,
  }) async {
    final decoded = await _api.getJson(
      '/v1/couples/$coupleId/reviews',
      credential: ApiCredential.devUser(userId),
    );
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_ReviewApiMapper.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Review> createReview({
    required String coupleId,
    required String userId,
    required ReviewDraft draft,
  }) async {
    final json =
        await _api.postJson(
              '/v1/couples/$coupleId/reviews',
              credential: ApiCredential.devUser(userId),
              body: {'draft': _ReviewApiMapper.draftToJson(draft)},
            )
            as Map<String, dynamic>;
    return _ReviewApiMapper.fromJson(json);
  }

  @override
  Future<Review> updateReview({
    required String coupleId,
    required String userId,
    required Review review,
  }) async {
    final json =
        await _api.putJson(
              '/v1/couples/$coupleId/reviews/${review.id}',
              credential: ApiCredential.devUser(userId),
              body: {'review': _ReviewApiMapper.reviewToJson(review)},
            )
            as Map<String, dynamic>;
    return _ReviewApiMapper.fromJson(json);
  }

  @override
  Future<void> deleteReview({
    required String coupleId,
    required String reviewId,
    required String userId,
  }) async {
    await _api.deleteJson(
      '/v1/couples/$coupleId/reviews/$reviewId',
      credential: ApiCredential.devUser(userId),
    );
  }
}

class _ReviewApiMapper {
  static Review fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String? ?? '',
      coupleId: json['coupleId'] as String? ?? '',
      type: _readType(json['type']),
      title: json['title'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      memo: json['memo'] as String? ?? '',
      photos: _readPhotos(json['photos']),
      dateRecordId: json['dateRecordId'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  static Map<String, dynamic> draftToJson(ReviewDraft draft) {
    return {
      'type': draft.type.name,
      'title': draft.title,
      'rating': draft.rating,
      'memo': draft.memo,
      'photos': photoAttachmentsFromLabels(
        draft.photoLabels,
      ).map(photoToJson).toList(),
      'dateRecordId': draft.dateRecordId,
    };
  }

  static Map<String, dynamic> reviewToJson(Review review) {
    return {
      'id': review.id,
      'coupleId': review.coupleId,
      'type': review.type.name,
      'title': review.title,
      'rating': review.rating,
      'memo': review.memo,
      'photos': review.photos.map(photoToJson).toList(),
      'dateRecordId': review.dateRecordId,
      'createdBy': review.createdBy,
      'createdAt': review.createdAt.toUtc().toIso8601String(),
      'updatedAt': review.updatedAt.toUtc().toIso8601String(),
    };
  }

  static Map<String, dynamic> photoToJson(PhotoAttachment photo) {
    return {
      'id': photo.id,
      'label': photo.label,
      'storagePath': photo.storagePath,
      'downloadUrl': photo.downloadUrl,
      'createdAt': photo.createdAt?.toUtc().toIso8601String(),
    };
  }

  static List<PhotoAttachment> _readPhotos(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map<String, dynamic>>().map((json) {
      return PhotoAttachment(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        storagePath: json['storagePath'] as String?,
        downloadUrl: json['downloadUrl'] as String?,
        createdAt: _readNullableDate(json['createdAt']),
      );
    }).toList();
  }

  static ReviewType _readType(Object? value) {
    return ReviewType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ReviewType.other,
    );
  }

  static DateTime _readDate(Object? value) {
    return _readNullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _readNullableDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }
}
