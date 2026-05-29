import 'package:http/http.dart' as http;

import '../../../../core/api/api_client.dart';
import '../../../links/domain/models/linked_item.dart';
import '../../../photos/domain/models/photo_attachment.dart';
import '../../domain/models/date_record.dart';
import 'date_record_repository.dart';

class ApiDateRecordRepository implements DateRecordRepository {
  ApiDateRecordRepository({required String baseUrl, http.Client? client})
    : _api = ApiClient(baseUrl: baseUrl, client: client);

  final ApiClient _api;

  @override
  Future<List<DateRecord>> fetchDateRecords({
    required String coupleId,
    required String userId,
  }) async {
    final decoded = await _api.getJson(
      '/v1/couples/$coupleId/date-records',
      credential: ApiCredential.devUser(userId),
    );
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_DateRecordApiMapper.fromJson)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<DateRecord> createRecord({
    required String coupleId,
    required String userId,
    required DateRecordDraft draft,
  }) async {
    final decoded = await _api.postJson(
      '/v1/couples/$coupleId/date-records',
      credential: ApiCredential.devUser(userId),
      body: _DateRecordApiMapper.draftToJson(draft),
    );
    return _DateRecordApiMapper.fromJson(decoded as Map<String, dynamic>);
  }

  @override
  Future<DateRecord> updateRecord({
    required String coupleId,
    required String userId,
    required DateRecord record,
  }) async {
    final decoded = await _api.putJson(
      '/v1/couples/$coupleId/date-records/${record.id}',
      credential: ApiCredential.devUser(userId),
      body: _DateRecordApiMapper.recordToJson(record),
    );
    return _DateRecordApiMapper.fromJson(decoded as Map<String, dynamic>);
  }

  @override
  Future<void> deleteRecord({
    required String coupleId,
    required String userId,
    required String recordId,
  }) async {
    await _api.deleteJson(
      '/v1/couples/$coupleId/date-records/$recordId',
      credential: ApiCredential.devUser(userId),
    );
  }

  @override
  Future<DateRecord> linkCalendarEvent({
    required String coupleId,
    required String userId,
    required String recordId,
    required String eventId,
  }) async {
    final decoded = await _api.putJson(
      '/v1/couples/$coupleId/date-records/$recordId/calendar-event',
      credential: ApiCredential.devUser(userId),
      body: {'eventId': eventId},
    );
    return _DateRecordApiMapper.fromJson(decoded as Map<String, dynamic>);
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
    final decoded = await _api.deleteJson(
      '/v1/couples/$coupleId/date-records/$recordId/calendar-event/$eventId',
      credential: ApiCredential.devUser(userId),
    );
    return _DateRecordApiMapper.fromJson(decoded as Map<String, dynamic>);
  }

  @override
  Future<DateRecord> addLinkedItem({
    required String coupleId,
    required String userId,
    required String recordId,
    required LinkedItem linkedItem,
  }) async {
    final decoded = await _api.postJson(
      '/v1/couples/$coupleId/date-records/$recordId/linked-items',
      credential: ApiCredential.devUser(userId),
      body: {
        'linkedItem': _DateRecordApiMapper.linkedItemToJson(linkedItem),
      },
    );
    return _DateRecordApiMapper.fromJson(decoded as Map<String, dynamic>);
  }

  @override
  Future<DateRecord> removeLinkedItem({
    required String coupleId,
    required String userId,
    required String recordId,
    required LinkedItem linkedItem,
  }) async {
    final decoded = await _api.postJson(
      '/v1/couples/$coupleId/date-records/$recordId/linked-items/remove',
      credential: ApiCredential.devUser(userId),
      body: {
        'linkedItem': _DateRecordApiMapper.linkedItemToJson(linkedItem),
      },
    );
    return _DateRecordApiMapper.fromJson(decoded as Map<String, dynamic>);
  }
}

class _DateRecordApiMapper {
  static DateRecord fromJson(Map<String, dynamic> json) {
    return DateRecord(
      id: json['id'] as String? ?? '',
      coupleId: json['coupleId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: _readDate(json['date']),
      memo: json['memo'] as String? ?? '',
      place: _readPlace(json['place']),
      photos: _readPhotos(json['photos']),
      linkedItems: _readLinkedItems(json['linkedItems']),
      linkedEventId: json['linkedEventId'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  static Map<String, dynamic> draftToJson(DateRecordDraft draft) {
    return {
      'title': draft.title,
      'date': draft.date.toUtc().toIso8601String(),
      'memo': draft.memo,
      'place': _placeFromDraft(draft),
      'photos': photoAttachmentsFromLabels(
        draft.photoLabels,
      ).map(photoToJson).toList(),
      'linkedItems': draft.linkedItems.map(linkedItemToJson).toList(),
      'linkedEventId': draft.linkedEventId,
    };
  }

  static Map<String, dynamic> recordToJson(DateRecord record) {
    return {
      'title': record.title,
      'date': record.date.toUtc().toIso8601String(),
      'memo': record.memo,
      'place': placeToJson(record.place),
      'photos': record.photos.map(photoToJson).toList(),
      'linkedItems': record.linkedItems.map(linkedItemToJson).toList(),
      'linkedEventId': record.linkedEventId,
    };
  }

  static Map<String, dynamic>? _placeFromDraft(DateRecordDraft draft) {
    if (draft.placeName.trim().isEmpty) {
      return null;
    }
    return {
      'provider': PlaceProvider.manual.name,
      'name': draft.placeName.trim(),
      'address': draft.placeAddress.trim().isEmpty
          ? null
          : draft.placeAddress.trim(),
    };
  }

  static Map<String, dynamic>? placeToJson(PlaceSnapshot? place) {
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
    if (value is! Map<String, dynamic>) {
      return null;
    }
    return PlaceSnapshot(
      provider: PlaceProvider.values.firstWhere(
        (provider) => provider.name == value['provider'],
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

  static Map<String, dynamic> linkedItemToJson(LinkedItem item) {
    return {
      'type': item.type.name,
      'targetId': item.targetId,
      'targetPath': item.targetPath,
      'title': item.title,
      'subtitle': item.subtitle,
      'date': item.date?.toUtc().toIso8601String(),
      'thumbnailUrl': item.thumbnailUrl,
      'preview': item.preview,
      'emoji': item.emoji,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
    };
  }

  static List<LinkedItem> _readLinkedItems(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map<String, dynamic>>().map((json) {
      return LinkedItem(
        type: LinkedItemType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => LinkedItemType.place,
        ),
        targetId: json['targetId'] as String? ?? '',
        targetPath: json['targetPath'] as String?,
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        date: _readNullableDate(json['date']),
        thumbnailUrl: json['thumbnailUrl'] as String?,
        preview: json['preview'] as String?,
        emoji: json['emoji'] as String?,
        createdAt: _readDate(json['createdAt']),
      );
    }).toList();
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
