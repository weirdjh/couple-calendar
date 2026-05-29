import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../date_records/domain/models/date_record.dart';
import '../../photos/domain/models/photo_attachment.dart';
import '../../reviews/domain/models/review.dart';
import '../../todos/domain/models/todo_item.dart';
import '../domain/models/linked_item.dart';

final apiLinkUseCaseClientProvider = Provider<ApiLinkUseCaseClient>(
  (ref) => ApiLinkUseCaseClient(baseUrl: apiBaseUrl),
);

class ApiLinkUseCaseClient {
  ApiLinkUseCaseClient({required String baseUrl, http.Client? client})
    : _api = ApiClient(baseUrl: baseUrl, client: client);

  final ApiClient _api;

  Future<DateRecord> ensureDateRecordForEvent({
    required String coupleId,
    required String userId,
    required String eventId,
  }) async {
    final json =
        await _api.postJson(
              '/v1/couples/$coupleId/links/date-records/ensure-for-event',
              credential: ApiCredential.devUser(userId),
              body: {'eventId': eventId},
            )
            as Map<String, dynamic>;
    return _readDateRecordResult(json);
  }

  Future<DateRecord> createDateRecordFromEvent({
    required String coupleId,
    required String userId,
    required String eventId,
  }) async {
    final json =
        await _api.postJson(
              '/v1/couples/$coupleId/links/date-records/from-event',
              credential: ApiCredential.devUser(userId),
              body: {'eventId': eventId},
            )
            as Map<String, dynamic>;
    return _readDateRecordResult(json);
  }

  Future<DateRecord> linkRecordToEvent({
    required String coupleId,
    required String userId,
    required String recordId,
    required String eventId,
  }) async {
    final json =
        await _api.postJson(
              '/v1/couples/$coupleId/links/date-records/$recordId/calendar-event',
              credential: ApiCredential.devUser(userId),
              body: {'eventId': eventId},
            )
            as Map<String, dynamic>;
    return _readDateRecordResult(json);
  }

  Future<DateRecord> unlinkRecordFromEvent({
    required String coupleId,
    required String userId,
    required String recordId,
    required String eventId,
  }) async {
    final json =
        await _api.deleteJson(
              '/v1/couples/$coupleId/links/date-records/$recordId/calendar-event/$eventId',
              credential: ApiCredential.devUser(userId),
            )
            as Map<String, dynamic>;
    return _readDateRecordResult(json);
  }

  Future<void> deleteDateRecordEverywhere({
    required String coupleId,
    required String userId,
    required String recordId,
  }) async {
    await _api.deleteJson(
      '/v1/couples/$coupleId/links/date-records/$recordId',
      credential: ApiCredential.devUser(userId),
    );
  }

  Future<ApiTodoCompletionResult> completeTodoItemForEvent({
    required String coupleId,
    required String userId,
    required String itemId,
    required String eventId,
  }) async {
    final json =
        await _api.postJson(
              '/v1/couples/$coupleId/links/todo-completions',
              credential: ApiCredential.devUser(userId),
              body: {'itemId': itemId, 'eventId': eventId},
            )
            as Map<String, dynamic>;
    return ApiTodoCompletionResult(
      completion: _completionFromJson(
        json['completion'] as Map<String, dynamic>,
      ),
      linkedItem: _linkedItemFromJson(
        json['linkedItem'] as Map<String, dynamic>,
      ),
      dateRecordId: json['dateRecordId'] as String? ?? '',
    );
  }

  Future<void> removeCalendarEventLinkedItem({
    required String coupleId,
    required String userId,
    required String eventId,
    required LinkedItem linkedItem,
  }) async {
    await _api.postJson(
      '/v1/couples/$coupleId/links/calendar-events/$eventId/linked-items/remove',
      credential: ApiCredential.devUser(userId),
      body: {'linkedItem': _linkedItemToJson(linkedItem)},
    );
  }

  Future<void> removeTodoCompletionEverywhere({
    required String coupleId,
    required String userId,
    required String completionId,
  }) async {
    await _api.deleteJson(
      '/v1/couples/$coupleId/links/todo-completions/$completionId',
      credential: ApiCredential.devUser(userId),
    );
  }

  Future<ApiReviewLinkResult> linkReviewToDateRecord({
    required String coupleId,
    required String userId,
    required String reviewId,
    required String recordId,
  }) async {
    final json =
        await _api.postJson(
              '/v1/couples/$coupleId/links/reviews/$reviewId/date-record',
              credential: ApiCredential.devUser(userId),
              body: {'recordId': recordId},
            )
            as Map<String, dynamic>;
    return _readReviewLinkResult(json);
  }

  Future<ApiReviewLinkResult> unlinkReviewFromDateRecord({
    required String coupleId,
    required String userId,
    required String reviewId,
    required String recordId,
  }) async {
    final json =
        await _api.deleteJson(
              '/v1/couples/$coupleId/links/reviews/$reviewId/date-record/$recordId',
              credential: ApiCredential.devUser(userId),
            )
            as Map<String, dynamic>;
    return _readReviewLinkResult(json);
  }

  Future<void> deleteReviewEverywhere({
    required String coupleId,
    required String userId,
    required String reviewId,
  }) async {
    await _api.deleteJson(
      '/v1/couples/$coupleId/links/reviews/$reviewId',
      credential: ApiCredential.devUser(userId),
    );
  }
}

class ApiTodoCompletionResult {
  const ApiTodoCompletionResult({
    required this.completion,
    required this.linkedItem,
    required this.dateRecordId,
  });

  final TodoCompletion completion;
  final LinkedItem linkedItem;
  final String dateRecordId;
}

class ApiReviewLinkResult {
  const ApiReviewLinkResult({
    required this.review,
    required this.record,
    required this.linkedItem,
  });

  final Review review;
  final DateRecord record;
  final LinkedItem linkedItem;
}

DateRecord _readDateRecordResult(Map<String, dynamic> json) {
  return _dateRecordFromJson(json['record'] as Map<String, dynamic>);
}

ApiReviewLinkResult _readReviewLinkResult(Map<String, dynamic> json) {
  return ApiReviewLinkResult(
    review: _reviewFromJson(json['review'] as Map<String, dynamic>),
    record: _dateRecordFromJson(json['record'] as Map<String, dynamic>),
    linkedItem: _linkedItemFromJson(json['linkedItem'] as Map<String, dynamic>),
  );
}

DateRecord _dateRecordFromJson(Map<String, dynamic> json) {
  return DateRecord(
    id: json['id'] as String? ?? '',
    coupleId: json['coupleId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    date: _readDate(json['date']),
    memo: json['memo'] as String? ?? '',
    place: _placeFromJson(json['place']),
    photos: _readPhotos(json['photos']),
    linkedItems: _readLinkedItems(json['linkedItems']),
    linkedEventId: json['linkedEventId'] as String?,
    createdBy: json['createdBy'] as String? ?? '',
    createdAt: _readDate(json['createdAt']),
    updatedAt: _readDate(json['updatedAt']),
  );
}

PlaceSnapshot? _placeFromJson(Object? value) {
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

List<PhotoAttachment> _readPhotos(Object? value) {
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

List<LinkedItem> _readLinkedItems(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(_linkedItemFromJson)
      .toList();
}

LinkedItem _linkedItemFromJson(Map<String, dynamic> json) {
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
}

Map<String, dynamic> _linkedItemToJson(LinkedItem item) {
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

TodoCompletion _completionFromJson(Map<String, dynamic> json) {
  return TodoCompletion(
    id: json['id'] as String? ?? '',
    coupleId: json['coupleId'] as String? ?? '',
    itemId: json['itemId'] as String? ?? '',
    completedAt: _readDate(json['completedAt']),
    completedBy: json['completedBy'] as String? ?? '',
    calendarEventId: json['calendarEventId'] as String? ?? '',
    memo: json['memo'] as String? ?? '',
    createdAt: _readDate(json['createdAt']),
  );
}

Review _reviewFromJson(Map<String, dynamic> json) {
  return Review(
    id: json['id'] as String? ?? '',
    coupleId: json['coupleId'] as String? ?? '',
    type: ReviewType.values.firstWhere(
      (type) => type.name == json['type'],
      orElse: () => ReviewType.other,
    ),
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

DateTime _readDate(Object? value) {
  return _readNullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _readNullableDate(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value)?.toLocal();
}
