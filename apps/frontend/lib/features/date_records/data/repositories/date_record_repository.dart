import '../../../links/domain/models/linked_item.dart';
import '../../domain/models/date_record.dart';

abstract class DateRecordRepository {
  Future<List<DateRecord>> fetchDateRecords({
    required String coupleId,
    required String userId,
  });

  Future<DateRecord> createRecord({
    required String coupleId,
    required String userId,
    required DateRecordDraft draft,
  });

  Future<DateRecord> updateRecord({
    required String coupleId,
    required String userId,
    required DateRecord record,
  });

  Future<void> deleteRecord({
    required String coupleId,
    required String userId,
    required String recordId,
  });

  Future<DateRecord> linkCalendarEvent({
    required String coupleId,
    required String userId,
    required String recordId,
    required String eventId,
  });

  Future<DateRecord?> unlinkCalendarEvent({
    required String coupleId,
    required String userId,
    required String? recordId,
    required String eventId,
  });

  Future<DateRecord> addLinkedItem({
    required String coupleId,
    required String userId,
    required String recordId,
    required LinkedItem linkedItem,
  });

  Future<DateRecord> removeLinkedItem({
    required String coupleId,
    required String userId,
    required String recordId,
    required LinkedItem linkedItem,
  });
}

class DateRecordDraft {
  const DateRecordDraft({
    required this.title,
    required this.date,
    this.memo = '',
    this.placeName = '',
    this.placeAddress = '',
    this.photoLabels = const [],
    this.linkedItems = const [],
    this.linkedEventId,
  });

  final String title;
  final DateTime date;
  final String memo;
  final String placeName;
  final String placeAddress;
  final List<String> photoLabels;
  final List<LinkedItem> linkedItems;
  final String? linkedEventId;
}
