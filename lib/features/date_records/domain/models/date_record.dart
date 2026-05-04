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
    this.photoLabels = const [],
    this.linkedEventId,
  });

  final String id;
  final String coupleId;
  final String title;
  final DateTime date;
  final String memo;
  final PlaceSnapshot? place;
  final List<String> photoLabels;
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
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedEventId,
  }) {
    return DateRecord(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      place: place ?? this.place,
      photoLabels: photoLabels ?? this.photoLabels,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedEventId: linkedEventId ?? this.linkedEventId,
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
