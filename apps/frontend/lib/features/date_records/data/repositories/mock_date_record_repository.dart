import '../../../links/domain/models/linked_item.dart';
import '../../../photos/domain/models/photo_attachment.dart';
import '../../domain/models/date_record.dart';
import 'date_record_repository.dart';

class MockDateRecordRepository implements DateRecordRepository {
  final Map<String, List<DateRecord>> _recordsByCouple = {};
  var _nextId = 3;

  @override
  Future<List<DateRecord>> fetchDateRecords({
    required String coupleId,
    required String userId,
  }) async {
    return List.unmodifiable(_ensureSeeded(coupleId: coupleId, userId: userId));
  }

  @override
  Future<DateRecord> createRecord({
    required String coupleId,
    required String userId,
    required DateRecordDraft draft,
  }) async {
    final records = _ensureSeeded(coupleId: coupleId, userId: userId);
    final now = DateTime.now();
    final record = DateRecord(
      id: 'date-record-${_nextId++}',
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
      linkedItems: List.unmodifiable(draft.linkedItems),
      linkedEventId: draft.linkedEventId,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );
    _recordsByCouple[coupleId] = [record, ...records];
    return record;
  }

  @override
  Future<DateRecord> updateRecord({
    required String coupleId,
    required String userId,
    required DateRecord record,
  }) async {
    _recordsByCouple[coupleId] =
        _recordsByCouple[coupleId]
            ?.map((item) => item.id == record.id ? record : item)
            .toList() ??
        [record];
    return record;
  }

  @override
  Future<void> deleteRecord({
    required String coupleId,
    required String userId,
    required String recordId,
  }) async {
    _recordsByCouple[coupleId] =
        _recordsByCouple[coupleId]
            ?.where((record) => record.id != recordId)
            .toList() ??
        const [];
  }

  @override
  Future<DateRecord> linkCalendarEvent({
    required String coupleId,
    required String userId,
    required String recordId,
    required String eventId,
  }) async {
    return _updateOne(
      coupleId: coupleId,
      recordId: recordId,
      update: (record) =>
          record.copyWith(linkedEventId: eventId, updatedAt: DateTime.now()),
    );
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
    final record = _recordsByCouple[coupleId]
        ?.where((item) => item.id == recordId)
        .firstOrNull;
    if (record == null || record.linkedEventId != eventId) {
      return record;
    }
    return _updateOne(
      coupleId: coupleId,
      recordId: recordId,
      update: (record) =>
          record.copyWith(clearLinkedEventId: true, updatedAt: DateTime.now()),
    );
  }

  @override
  Future<DateRecord> addLinkedItem({
    required String coupleId,
    required String userId,
    required String recordId,
    required LinkedItem linkedItem,
  }) async {
    return _updateOne(
      coupleId: coupleId,
      recordId: recordId,
      update: (record) {
        final alreadyLinked = record.linkedItems.any(
          (item) =>
              item.type == linkedItem.type &&
              item.targetId == linkedItem.targetId,
        );
        if (alreadyLinked) {
          return record;
        }
        return record.copyWith(
          linkedItems: [...record.linkedItems, linkedItem],
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  @override
  Future<DateRecord> removeLinkedItem({
    required String coupleId,
    required String userId,
    required String recordId,
    required LinkedItem linkedItem,
  }) async {
    return _updateOne(
      coupleId: coupleId,
      recordId: recordId,
      update: (record) => record.copyWith(
        linkedItems: record.linkedItems
            .where(
              (item) =>
                  item.type != linkedItem.type ||
                  item.targetId != linkedItem.targetId,
            )
            .toList(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  List<DateRecord> _ensureSeeded({
    required String coupleId,
    required String userId,
  }) {
    return _recordsByCouple.putIfAbsent(
      coupleId,
      () => _seed(coupleId: coupleId, userId: userId),
    );
  }

  DateRecord _updateOne({
    required String coupleId,
    required String recordId,
    required DateRecord Function(DateRecord record) update,
  }) {
    final records = _recordsByCouple[coupleId] ?? const <DateRecord>[];
    DateRecord? updated;
    _recordsByCouple[coupleId] = records.map((record) {
      if (record.id != recordId) {
        return record;
      }
      updated = update(record);
      return updated!;
    }).toList();
    if (updated == null) {
      throw StateError('Date record not found: $recordId');
    }
    return updated!;
  }

  List<DateRecord> _seed({required String coupleId, required String userId}) {
    final now = DateTime.now();
    final mountainDate = DateTime(now.year, now.month, now.day + 3);
    final movieDate = DateTime(now.year, now.month, now.day - 2);
    return [
      DateRecord(
        id: 'date-record-1',
        coupleId: coupleId,
        title: '하남검단산 데이트',
        date: mountainDate,
        memo: '버킷리스트 등산을 데이트 기록으로 남기기',
        place: const PlaceSnapshot(
          provider: PlaceProvider.manual,
          name: '하남검단산',
          address: '경기 하남시',
        ),
        photos: const [PhotoAttachment(id: 'photo-1', label: '정상 사진')],
        linkedItems: [
          LinkedItem(
            type: LinkedItemType.todo,
            targetId: 'todo-completion-1',
            targetPath: '/todos/todo-item-1/completions/todo-completion-1',
            title: '하남검단산 가기',
            subtitle: '등산 하기',
            date: mountainDate,
            preview: '버킷리스트 달성',
            emoji: '⛰️',
            createdAt: now,
          ),
        ],
        linkedEventId: 'event-2',
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      ),
      DateRecord(
        id: 'date-record-2',
        coupleId: coupleId,
        title: '영화 리뷰',
        date: movieDate,
        memo: '영화 보고 짧게 감상 남기기',
        place: const PlaceSnapshot(
          provider: PlaceProvider.manual,
          name: '집 근처 영화관',
        ),
        linkedItems: [
          LinkedItem(
            type: LinkedItemType.review,
            targetId: 'review-1',
            targetPath: '/reviews/review-1',
            title: '영화 리뷰 placeholder',
            subtitle: '별점 기록 예정',
            date: movieDate,
            preview: '리뷰 모듈 연결 예정',
            emoji: '🎬',
            createdAt: now,
          ),
        ],
        linkedEventId: 'event-4',
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
