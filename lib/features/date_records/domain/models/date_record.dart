import '../../../links/domain/models/linked_item.dart';
import '../../../photos/domain/models/photo_attachment.dart';

class DateRecord {
  const DateRecord({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.date,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memo = '',
    this.place,
    List<String> photoLabels = const [],
    List<PhotoAttachment>? photos,
    this.linkedItems = const [],
    this.linkedEventId,
  }) : photos = photos ?? const [],
       _legacyPhotoLabels = photoLabels;

  final String id;
  final String coupleId;
  final String title;
  final DateTime date;
  final String memo;
  final PlaceSnapshot? place;
  final List<PhotoAttachment> photos;
  final List<String> _legacyPhotoLabels;
  List<String> get photoLabels => photos.isEmpty
      ? List.unmodifiable(_legacyPhotoLabels)
      : photoLabelsFromAttachments(photos);
  final List<LinkedItem> linkedItems;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? linkedEventId;

  DateRecord copyWith({
    String? id,
    String? coupleId,
    String? title,
    DateTime? date,
    String? memo,
    PlaceSnapshot? place,
    List<String>? photoLabels,
    List<PhotoAttachment>? photos,
    List<LinkedItem>? linkedItems,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedEventId,
    bool clearLinkedEventId = false,
  }) {
    return DateRecord(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      place: place ?? this.place,
      photoLabels: photoLabels ?? this.photoLabels,
      photos: photos ?? this.photos,
      linkedItems: linkedItems ?? this.linkedItems,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedEventId: clearLinkedEventId
          ? null
          : linkedEventId ?? this.linkedEventId,
    );
  }
}

class PlaceSnapshot {
  const PlaceSnapshot({
    required this.provider,
    required this.name,
    this.providerPlaceId,
    this.address,
    this.latitude,
    this.longitude,
    this.url,
  });

  final PlaceProvider provider;
  final String name;
  final String? providerPlaceId;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? url;
}

enum PlaceProvider { manual, googleMaps, naverMaps }
