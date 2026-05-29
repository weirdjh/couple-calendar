import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../photos/domain/models/photo_attachment.dart';
import '../../domain/models/review.dart';
import 'review_repository.dart';

class FirestoreReviewRepository implements ReviewRepository {
  FirestoreReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Review>> fetchReviews({
    required String coupleId,
    required String userId,
  }) async {
    final snapshot = await _reviewsCollection(
      coupleId,
    ).where(ReviewFields.deletedAt, isNull: true).get();
    return snapshot.docs.map(_ReviewMapper.fromDocument).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Review> createReview({
    required String coupleId,
    required String userId,
    required ReviewDraft draft,
  }) async {
    final doc = _reviewsCollection(coupleId).doc();
    final now = DateTime.now().toUtc();
    final review = Review(
      id: doc.id,
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
    await doc.set(_ReviewMapper.toMap(review));
    return review;
  }

  @override
  Future<Review> updateReview({
    required String coupleId,
    required String userId,
    required Review review,
  }) async {
    final updated = review.copyWith(updatedAt: DateTime.now().toUtc());
    await _reviewsCollection(
      coupleId,
    ).doc(review.id).set(_ReviewMapper.toMap(updated));
    return updated;
  }

  @override
  Future<void> deleteReview({
    required String coupleId,
    required String reviewId,
    required String userId,
  }) async {
    await _reviewsCollection(coupleId).doc(reviewId).update({
      ReviewFields.deletedAt: Timestamp.fromDate(DateTime.now().toUtc()),
      ReviewFields.updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
    });
  }

  CollectionReference<Map<String, dynamic>> _reviewsCollection(
    String coupleId,
  ) {
    return _firestore.collection('couples').doc(coupleId).collection('reviews');
  }
}

class ReviewFields {
  static const coupleId = 'coupleId';
  static const type = 'type';
  static const title = 'title';
  static const rating = 'rating';
  static const memo = 'memo';
  static const photos = 'photos';
  static const dateRecordId = 'dateRecordId';
  static const createdBy = 'createdBy';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const deletedAt = 'deletedAt';
}

class _ReviewMapper {
  static Review fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Review(
      id: doc.id,
      coupleId: data[ReviewFields.coupleId] as String? ?? '',
      type: ReviewType.values.firstWhere(
        (type) => type.name == data[ReviewFields.type],
        orElse: () => ReviewType.other,
      ),
      title: data[ReviewFields.title] as String? ?? '',
      rating: (data[ReviewFields.rating] as num?)?.toDouble() ?? 0,
      memo: data[ReviewFields.memo] as String? ?? '',
      photos: _readPhotos(data[ReviewFields.photos]),
      dateRecordId: data[ReviewFields.dateRecordId] as String?,
      createdBy: data[ReviewFields.createdBy] as String? ?? '',
      createdAt: _readDate(data[ReviewFields.createdAt]),
      updatedAt: _readDate(data[ReviewFields.updatedAt]),
    );
  }

  static Map<String, dynamic> toMap(Review review) {
    return {
      ReviewFields.coupleId: review.coupleId,
      ReviewFields.type: review.type.name,
      ReviewFields.title: review.title,
      ReviewFields.rating: review.rating,
      ReviewFields.memo: review.memo,
      ReviewFields.photos: review.photos.map(_photoToMap).toList(),
      ReviewFields.dateRecordId: review.dateRecordId,
      ReviewFields.createdBy: review.createdBy,
      ReviewFields.createdAt: Timestamp.fromDate(review.createdAt.toUtc()),
      ReviewFields.updatedAt: Timestamp.fromDate(review.updatedAt.toUtc()),
      ReviewFields.deletedAt: null,
    };
  }

  static Map<String, dynamic> _photoToMap(PhotoAttachment photo) {
    return {
      'id': photo.id,
      'label': photo.label,
      'storagePath': photo.storagePath,
      'downloadUrl': photo.downloadUrl,
      'createdAt': photo.createdAt == null
          ? null
          : Timestamp.fromDate(photo.createdAt!.toUtc()),
    };
  }

  static List<PhotoAttachment> _readPhotos(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map>().map((item) {
      return PhotoAttachment(
        id: item['id'] as String? ?? '',
        label: item['label'] as String? ?? '',
        storagePath: item['storagePath'] as String?,
        downloadUrl: item['downloadUrl'] as String?,
        createdAt: _readNullableDate(item['createdAt']),
      );
    }).toList();
  }

  static DateTime _readDate(Object? value) {
    return _readNullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _readNullableDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
