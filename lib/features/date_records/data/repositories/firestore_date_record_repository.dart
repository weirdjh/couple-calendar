import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../links/domain/models/linked_item.dart';
import '../../../photos/domain/models/photo_attachment.dart';
import '../../domain/models/date_record.dart';
import 'date_record_repository.dart';

class FirestoreDateRecordRepository implements DateRecordRepository {
  FirestoreDateRecordRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<DateRecord>> fetchDateRecords({
    required String coupleId,
    required String userId,
  }) async {
    final snapshot = await _recordsCollection(
      coupleId,
    ).where(DateRecordFields.deletedAt, isNull: true).get();
    return snapshot.docs.map(_DateRecordMapper.fromDocument).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<DateRecord> createRecord({
    required String coupleId,
    required String userId,
    required DateRecordDraft draft,
  }) async {
    final doc = _recordsCollection(coupleId).doc();
    final now = DateTime.now().toUtc();
    final record = DateRecord(
      id: doc.id,
      coupleId: coupleId,
      title: draft.title,
      date: draft.date,
      memo: draft.memo,
      place: draft.placeName.trim().isEmpty
          ? null
          : PlaceSnapshot(
              provider: PlaceProvider.manual,
              name: draft.placeName.trim(),
              address: draft.placeAddress.trim().isEmpty
                  ? null
                  : draft.placeAddress.trim(),
            ),
      photos: photoAttachmentsFromLabels(draft.photoLabels),
      linkedItems: draft.linkedItems,
      linkedEventId: draft.linkedEventId,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(_DateRecordMapper.toMap(record));
    return record;
  }

  @override
  Future<DateRecord> updateRecord({
    required String coupleId,
    required String userId,
    required DateRecord record,
  }) async {
    final updated = record.copyWith(updatedAt: DateTime.now().toUtc());
    await _recordsCollection(
      coupleId,
    ).doc(record.id).set(_DateRecordMapper.toMap(updated));
    return updated;
  }

  @override
  Future<void> deleteRecord({
    required String coupleId,
    required String userId,
    required String recordId,
  }) async {
    await _recordsCollection(coupleId).doc(recordId).update({
      DateRecordFields.deletedAt: Timestamp.fromDate(DateTime.now().toUtc()),
      DateRecordFields.updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
    });
  }

  @override
  Future<DateRecord> linkCalendarEvent({
    required String coupleId,
    required String userId,
    required String recordId,
    required String eventId,
  }) async {
    final doc = _recordsCollection(coupleId).doc(recordId);
    await doc.update({
      DateRecordFields.linkedEventId: eventId,
      DateRecordFields.updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
    });
    return _DateRecordMapper.fromSnapshot(await doc.get());
  }

  @override
  Future<DateRecord?> unlinkCalendarEvent({
    required String coupleId,
    required String userId,
    required String? recordId,
    required String eventId,
  }) async {
    if (recordId == null) {
      return null;
    }
    final doc = _recordsCollection(coupleId).doc(recordId);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      return null;
    }
    final record = _DateRecordMapper.fromSnapshot(snapshot);
    if (record.linkedEventId != eventId) {
      return record;
    }
    await doc.update({
      DateRecordFields.linkedEventId: null,
      DateRecordFields.updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
    });
    return _DateRecordMapper.fromSnapshot(await doc.get());
  }

  @override
  Future<DateRecord> addLinkedItem({
    required String coupleId,
    required String userId,
    required String recordId,
    required LinkedItem linkedItem,
  }) async {
    final doc = _recordsCollection(coupleId).doc(recordId);
    final record = _DateRecordMapper.fromSnapshot(await doc.get());
    final alreadyLinked = record.linkedItems.any(
      (item) =>
          item.type == linkedItem.type && item.targetId == linkedItem.targetId,
    );
    final linkedItems = alreadyLinked
        ? record.linkedItems
        : [...record.linkedItems, linkedItem];
    final updated = record.copyWith(
      linkedItems: linkedItems,
      updatedAt: DateTime.now().toUtc(),
    );
    await doc.set(_DateRecordMapper.toMap(updated));
    return updated;
  }

  @override
  Future<DateRecord> removeLinkedItem({
    required String coupleId,
    required String userId,
    required String recordId,
    required LinkedItem linkedItem,
  }) async {
    final doc = _recordsCollection(coupleId).doc(recordId);
    final record = _DateRecordMapper.fromSnapshot(await doc.get());
    final updated = record.copyWith(
      linkedItems: record.linkedItems
          .where(
            (item) =>
                item.type != linkedItem.type ||
                item.targetId != linkedItem.targetId,
          )
          .toList(),
      updatedAt: DateTime.now().toUtc(),
    );
    await doc.set(_DateRecordMapper.toMap(updated));
    return updated;
  }

  CollectionReference<Map<String, dynamic>> _recordsCollection(
    String coupleId,
  ) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('dateRecords');
  }
}

class DateRecordFields {
  static const coupleId = 'coupleId';
  static const title = 'title';
  static const date = 'date';
  static const memo = 'memo';
  static const place = 'place';
  static const photos = 'photos';
  static const linkedItems = 'linkedItems';
  static const linkedEventId = 'linkedEventId';
  static const createdBy = 'createdBy';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const deletedAt = 'deletedAt';
}

class _DateRecordMapper {
  static DateRecord fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return _fromData(doc.id, doc.data());
  }

  static DateRecord fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Date record not found: ${doc.id}');
    }
    return _fromData(doc.id, data);
  }

  static DateRecord _fromData(String id, Map<String, dynamic> data) {
    return DateRecord(
      id: id,
      coupleId: data[DateRecordFields.coupleId] as String? ?? '',
      title: data[DateRecordFields.title] as String? ?? '',
      date: _readDate(data[DateRecordFields.date]),
      memo: data[DateRecordFields.memo] as String? ?? '',
      place: _readPlace(data[DateRecordFields.place]),
      photos: _readPhotos(data[DateRecordFields.photos]),
      linkedItems: _readLinkedItems(data[DateRecordFields.linkedItems]),
      linkedEventId: data[DateRecordFields.linkedEventId] as String?,
      createdBy: data[DateRecordFields.createdBy] as String? ?? '',
      createdAt: _readDate(data[DateRecordFields.createdAt]),
      updatedAt: _readDate(data[DateRecordFields.updatedAt]),
    );
  }

  static Map<String, dynamic> toMap(DateRecord record) {
    return {
      DateRecordFields.coupleId: record.coupleId,
      DateRecordFields.title: record.title,
      DateRecordFields.date: Timestamp.fromDate(record.date.toUtc()),
      DateRecordFields.memo: record.memo,
      DateRecordFields.place: _placeToMap(record.place),
      DateRecordFields.photos: record.photos.map(_photoToMap).toList(),
      DateRecordFields.linkedItems: record.linkedItems
          .map(_linkedItemToMap)
          .toList(),
      DateRecordFields.linkedEventId: record.linkedEventId,
      DateRecordFields.createdBy: record.createdBy,
      DateRecordFields.createdAt: Timestamp.fromDate(record.createdAt.toUtc()),
      DateRecordFields.updatedAt: Timestamp.fromDate(record.updatedAt.toUtc()),
      DateRecordFields.deletedAt: null,
    };
  }

  static Map<String, dynamic>? _placeToMap(PlaceSnapshot? place) {
    if (place == null) {
      return null;
    }
    return {
      'provider': place.provider.name,
      'name': place.name,
      'providerPlaceId': place.providerPlaceId,
      'address': place.address,
      'latitude': place.latitude,
      'longitude': place.longitude,
      'url': place.url,
    };
  }

  static PlaceSnapshot? _readPlace(Object? value) {
    if (value is! Map) {
      return null;
    }
    final providerName = value['provider'] as String?;
    return PlaceSnapshot(
      provider: PlaceProvider.values.firstWhere(
        (provider) => provider.name == providerName,
        orElse: () => PlaceProvider.manual,
      ),
      name: value['name'] as String? ?? '',
      providerPlaceId: value['providerPlaceId'] as String?,
      address: value['address'] as String?,
      latitude: (value['latitude'] as num?)?.toDouble(),
      longitude: (value['longitude'] as num?)?.toDouble(),
      url: value['url'] as String?,
    );
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

  static Map<String, dynamic> _linkedItemToMap(LinkedItem item) {
    return {
      'type': item.type.name,
      'targetId': item.targetId,
      'targetPath': item.targetPath,
      'title': item.title,
      'subtitle': item.subtitle,
      'date': item.date == null ? null : Timestamp.fromDate(item.date!.toUtc()),
      'thumbnailUrl': item.thumbnailUrl,
      'preview': item.preview,
      'emoji': item.emoji,
      'createdAt': Timestamp.fromDate(item.createdAt.toUtc()),
    };
  }

  static List<LinkedItem> _readLinkedItems(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map>().map((item) {
      return LinkedItem(
        type: LinkedItemType.values.firstWhere(
          (type) => type.name == item['type'],
          orElse: () => LinkedItemType.place,
        ),
        targetId: item['targetId'] as String? ?? '',
        targetPath: item['targetPath'] as String?,
        title: item['title'] as String? ?? '',
        subtitle: item['subtitle'] as String?,
        date: _readNullableDate(item['date']),
        thumbnailUrl: item['thumbnailUrl'] as String?,
        preview: item['preview'] as String?,
        emoji: item['emoji'] as String?,
        createdAt: _readDate(item['createdAt']),
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
