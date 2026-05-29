import '../../../photos/domain/models/photo_attachment.dart';

enum ReviewType { movie, drama, wine, restaurant, place, other }

class Review {
  const Review({
    required this.id,
    required this.coupleId,
    required this.type,
    required this.title,
    required this.rating,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memo = '',
    List<String> photoLabels = const [],
    List<PhotoAttachment>? photos,
    this.dateRecordId,
  }) : photos = photos ?? const [],
       _legacyPhotoLabels = photoLabels;

  final String id;
  final String coupleId;
  final ReviewType type;
  final String title;
  final double rating;
  final String memo;
  final List<PhotoAttachment> photos;
  final List<String> _legacyPhotoLabels;
  List<String> get photoLabels => photos.isEmpty
      ? List.unmodifiable(_legacyPhotoLabels)
      : photoLabelsFromAttachments(photos);
  final String? dateRecordId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review copyWith({
    String? id,
    String? coupleId,
    ReviewType? type,
    String? title,
    double? rating,
    String? memo,
    List<String>? photoLabels,
    List<PhotoAttachment>? photos,
    String? dateRecordId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDateRecordId = false,
  }) {
    return Review(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      type: type ?? this.type,
      title: title ?? this.title,
      rating: rating ?? this.rating,
      memo: memo ?? this.memo,
      photoLabels: photoLabels ?? this.photoLabels,
      photos: photos ?? this.photos,
      dateRecordId: clearDateRecordId
          ? null
          : dateRecordId ?? this.dateRecordId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
