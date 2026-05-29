import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/time/calendar_date_utils.dart' as dates;
import '../../auth/presentation/controllers/session_controller.dart';
import '../../calendar/domain/models/calendar_event.dart';
import '../../calendar/presentation/controllers/calendar_controller.dart';
import '../../links/application/api_link_use_case_client.dart';
import '../../links/domain/linked_item_helpers.dart';
import '../data/repositories/date_record_repository.dart';
import '../domain/models/date_record.dart';
import '../presentation/controllers/date_record_controller.dart';

final dateRecordServiceProvider = Provider<DateRecordService>(
  DateRecordService.new,
);

class DateRecordService {
  const DateRecordService(this._ref);

  final Ref _ref;

  Future<String?> ensureDateRecordForEvent(CalendarEvent event) async {
    if (useApi) {
      final session = _ref.read(sessionControllerProvider);
      final user = session.currentUser;
      final couple = session.currentCouple;
      if (user == null || couple == null) {
        return null;
      }
      final record = await _ref
          .read(apiLinkUseCaseClientProvider)
          .ensureDateRecordForEvent(
            coupleId: couple.id,
            userId: user.id,
            eventId: event.id,
          );
      await _refreshLinkedState();
      return record.id;
    }

    final existingDateRecordId = firstDateRecordIdForEvent(event);
    if (existingDateRecordId != null) {
      return existingDateRecordId;
    }

    final linkedRecord = _ref
        .read(dateRecordControllerProvider)
        .records
        .where((record) => record.linkedEventId == event.id)
        .firstOrNull;
    if (linkedRecord != null) {
      final session = _ref.read(sessionControllerProvider);
      final user = session.currentUser;
      final couple = session.currentCouple;
      if (user == null || couple == null) {
        return linkedRecord.id;
      }
      await _ref
          .read(calendarEventRepositoryProvider)
          .updateEvent(
            coupleId: couple.id,
            userId: user.id,
            event: event.copyWith(
              kind: CalendarEventKind.date,
              linkedItems: [
                ...event.linkedItems,
                linkedItemForDateRecord(
                  linkedRecord,
                  emoji: linkedRecord.linkedItems.firstOrNull?.emoji,
                ),
              ],
            ),
          );
      await _refreshLinkedState();
      return linkedRecord.id;
    }

    final session = _ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      return null;
    }

    final record = await _ref
        .read(dateRecordRepositoryProvider)
        .createRecord(
          coupleId: couple.id,
          userId: user.id,
          draft: DateRecordDraft(
            title: event.title,
            date: dates.dateOnly(event.startAt),
            memo: event.memo,
            linkedEventId: event.id,
          ),
        );
    await _ref
        .read(calendarEventRepositoryProvider)
        .updateEvent(
          coupleId: couple.id,
          userId: user.id,
          event: event.copyWith(
            kind: CalendarEventKind.date,
            linkedItems: [
              ...event.linkedItems,
              linkedItemForDateRecord(record),
            ],
          ),
        );
    await _refreshLinkedState();
    return record.id;
  }

  Future<DateRecord?> createDateRecordFromEvent(CalendarEvent event) async {
    final session = _ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      return null;
    }
    if (useApi) {
      final record = await _ref
          .read(apiLinkUseCaseClientProvider)
          .createDateRecordFromEvent(
            coupleId: couple.id,
            userId: user.id,
            eventId: event.id,
          );
      await _refreshLinkedState();
      return record;
    }
    final nestedLinks = nestedDateRecordLinks(event);
    final record = await _ref
        .read(dateRecordRepositoryProvider)
        .createRecord(
          coupleId: couple.id,
          userId: user.id,
          draft: DateRecordDraft(
            title: event.title,
            date: dates.dateOnly(event.startAt),
            memo: event.memo,
            linkedEventId: event.id,
            linkedItems: nestedLinks,
          ),
        );
    await _ref
        .read(calendarEventRepositoryProvider)
        .updateEvent(
          coupleId: couple.id,
          userId: user.id,
          event: event.copyWith(
            kind: CalendarEventKind.date,
            linkedItems: [
              for (final item in event.linkedItems)
                if (!nestedLinks.any(
                  (nested) =>
                      nested.type == item.type &&
                      nested.targetId == item.targetId,
                ))
                  item,
              linkedItemForDateRecord(
                record,
                emoji: nestedLinks.firstOrNull?.emoji,
              ),
            ],
          ),
        );

    await _refreshLinkedState();
    return record;
  }

  Future<DateRecord?> linkRecordToEvent({
    required DateRecord record,
    required CalendarEvent event,
  }) async {
    final session = _ref.read(sessionControllerProvider);
    final couple = session.currentCouple;
    final user = session.currentUser;
    if (couple == null || user == null) {
      return null;
    }
    if (useApi) {
      final linkedRecord = await _ref
          .read(apiLinkUseCaseClientProvider)
          .linkRecordToEvent(
            coupleId: couple.id,
            userId: user.id,
            recordId: record.id,
            eventId: event.id,
          );
      await _refreshLinkedState();
      return linkedRecord;
    }
    if (record.linkedEventId != null && record.linkedEventId != event.id) {
      await unlinkRecordFromEvent(record);
    }

    final linkedRecord = await _ref
        .read(dateRecordRepositoryProvider)
        .linkCalendarEvent(
          coupleId: couple.id,
          userId: user.id,
          recordId: record.id,
          eventId: event.id,
        );

    await _ref
        .read(calendarEventRepositoryProvider)
        .updateEvent(
          coupleId: couple.id,
          userId: user.id,
          event: event.copyWith(
            kind: CalendarEventKind.date,
            linkedItems: [
              ...event.linkedItems.where(
                (item) =>
                    item.type != LinkedItemType.dateRecord ||
                    dateRecordIdForLinkedItem(item) != linkedRecord.id,
              ),
              linkedItemForDateRecord(
                linkedRecord,
                emoji: linkedRecord.linkedItems.firstOrNull?.emoji,
              ),
            ],
          ),
        );
    await _refreshLinkedState();
    return linkedRecord;
  }

  Future<void> unlinkRecordFromEvent(DateRecord record) async {
    final session = _ref.read(sessionControllerProvider);
    final couple = session.currentCouple;
    final user = session.currentUser;
    if (couple == null || user == null) {
      return;
    }
    final eventId = record.linkedEventId;
    if (eventId == null) {
      return;
    }
    if (useApi) {
      await _ref
          .read(apiLinkUseCaseClientProvider)
          .unlinkRecordFromEvent(
            coupleId: couple.id,
            userId: user.id,
            recordId: record.id,
            eventId: eventId,
          );
      await _refreshLinkedState();
      return;
    }

    await _ref
        .read(calendarControllerProvider.notifier)
        .selectDate(record.date);
    final event = _ref
        .read(calendarControllerProvider)
        .events
        .where((item) => item.id == eventId)
        .firstOrNull;
    if (event != null) {
      final linkedItem = event.linkedItems
          .where(
            (item) =>
                item.type == LinkedItemType.dateRecord &&
                dateRecordIdForLinkedItem(item) == record.id,
          )
          .firstOrNull;
      if (linkedItem != null) {
        await _ref
            .read(calendarEventRepositoryProvider)
            .updateEvent(
              coupleId: couple.id,
              userId: user.id,
              event: event.copyWith(
                linkedItems: event.linkedItems
                    .where(
                      (item) =>
                          item.type != linkedItem.type ||
                          item.targetId != linkedItem.targetId,
                    )
                    .toList(),
              ),
            );
      }
    }

    await _ref
        .read(dateRecordRepositoryProvider)
        .unlinkCalendarEvent(
          coupleId: couple.id,
          userId: user.id,
          recordId: record.id,
          eventId: eventId,
        );
    await _refreshLinkedState();
  }

  Future<void> deleteRecord(DateRecord record) async {
    final session = _ref.read(sessionControllerProvider);
    final couple = session.currentCouple;
    final user = session.currentUser;
    if (couple == null || user == null) {
      return;
    }
    if (useApi) {
      await _ref
          .read(apiLinkUseCaseClientProvider)
          .deleteDateRecordEverywhere(
            coupleId: couple.id,
            userId: user.id,
            recordId: record.id,
          );
      await _refreshLinkedState();
      return;
    }
    await unlinkRecordFromEvent(record);
    await _ref
        .read(dateRecordRepositoryProvider)
        .deleteRecord(
          coupleId: couple.id,
          userId: user.id,
          recordId: record.id,
        );
    await _ref.read(dateRecordControllerProvider.notifier).refreshDateRecords();
  }

  Future<void> _refreshLinkedState() async {
    await _ref.read(dateRecordControllerProvider.notifier).refreshDateRecords();
    await _ref.read(calendarControllerProvider.notifier).refreshVisibleMonth();
  }
}

String? firstDateRecordIdForEvent(CalendarEvent event) {
  for (final item in event.linkedItems) {
    if (item.type == LinkedItemType.dateRecord) {
      return dateRecordIdForLinkedItem(item);
    }
  }
  return null;
}

List<LinkedItem> nestedDateRecordLinks(CalendarEvent event) {
  return event.linkedItems
      .where(
        (item) =>
            item.type == LinkedItemType.todo ||
            item.type == LinkedItemType.review,
      )
      .toList();
}

LinkedItem linkedItemForDateRecord(DateRecord record, {String? emoji}) {
  return LinkedItem(
    type: LinkedItemType.dateRecord,
    targetId: record.id,
    targetPath: '/records/dates/${record.id}',
    title: record.title,
    subtitle: record.place?.name,
    date: record.date,
    thumbnailUrl: record.photoLabels.firstOrNull,
    preview: record.memo,
    emoji: emoji,
    createdAt: record.createdAt,
  );
}
