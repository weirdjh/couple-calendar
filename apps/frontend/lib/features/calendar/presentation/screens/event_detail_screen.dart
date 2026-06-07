import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../anniversaries/presentation/screens/anniversary_screen.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../date_records/application/date_record_service.dart';
import '../../../date_records/presentation/controllers/date_record_controller.dart';
import '../../../date_records/presentation/screens/date_record_screen.dart';
import '../../../links/application/linked_content_service.dart';
import '../../../records/presentation/screens/record_placeholder_screen.dart';
import '../../../reviews/presentation/screens/review_screen.dart';
import '../../../todos/application/bucket_completion_service.dart';
import '../../../todos/domain/models/todo_item.dart';
import '../../../todos/presentation/controllers/todo_controller.dart';
import '../../../todos/presentation/screens/todo_screen.dart';
import '../../domain/models/calendar_event.dart';
import '../controllers/calendar_controller.dart';
import '../event_ownership_presentation.dart';
import '../linked_item_presentation.dart';
import '../widgets/event_editor_sheet.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarControllerProvider);
    final event = state.events.where((item) => item.id == eventId).firstOrNull;

    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('일정을 찾을 수 없어요.')),
      );
    }
    final currentUser = ref.watch(sessionControllerProvider).currentUser;
    final dateRecords = ref.watch(dateRecordControllerProvider).records;
    final linkedDateRecord = dateRecords
        .where((record) => record.linkedEventId == event.id)
        .firstOrNull;
    final displayLinkedItems = [
      ...event.linkedItems,
      if (linkedDateRecord != null &&
          !event.linkedItems.any(
            (item) =>
                item.type == LinkedItemType.dateRecord &&
                dateRecordIdForLinkedItem(item) == linkedDateRecord.id,
          ))
        linkedItemForDateRecord(linkedDateRecord),
    ];
    final currentUserId = currentUser?.id ?? '';
    final canEdit = currentUserId.isNotEmpty && event.canEditFor(currentUserId);
    final hasDateRecordLink = displayLinkedItems.any(
      (item) => item.type == LinkedItemType.dateRecord,
    );
    final canWatch =
        currentUserId.isNotEmpty && event.isPartnerOwnedFor(currentUserId);
    final isWatched =
        currentUserId.isNotEmpty && event.isWatchedBy(currentUserId);

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (canWatch)
            IconButton(
              tooltip: isWatched ? '지켜보기 해제' : '지켜보기',
              onPressed: () => ref
                  .read(calendarControllerProvider.notifier)
                  .toggleWatchEvent(event.id),
              icon: Icon(
                isWatched
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined,
              ),
            ),
          if (canEdit) ...[
            IconButton(
              tooltip: '편집',
              onPressed: () => _editEvent(context, ref, event),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: '삭제',
              onPressed: () => _deleteEvent(context, ref, event),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Header(event: event, currentUserId: currentUserId),
            const SizedBox(height: 8),
            if (canWatch) ...[
              _Section(
                title: '지켜보기',
                icon: isWatched
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isWatched ? '알림을 받고 있어요.' : '상대 일정 알림 받기'),
                  subtitle: const Text('상대 일정은 지켜보기한 경우에만 알림을 받아요.'),
                  value: isWatched,
                  onChanged: (_) => ref
                      .read(calendarControllerProvider.notifier)
                      .toggleWatchEvent(event.id),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (event.memo.isNotEmpty) ...[
              _Section(
                title: '메모',
                icon: Icons.notes_outlined,
                child: Text(
                  event.memo,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (event.reminders.isNotEmpty) ...[
              _Section(
                title: '알림',
                icon: Icons.notifications_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: event.reminders.map((reminder) {
                    return Text(
                      '${_reminderLabel(reminder.offsetMinutes)} · ${dates.formatDateLabel(reminder.remindAt)} ${dates.formatTimeLabel(reminder.remindAt)}',
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),
            ],
            _Section(
              title: '연결',
              icon: Icons.link,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayLinkedItems.isNotEmpty)
                    ...displayLinkedItems.map((item) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _openLinkedItem(context, item),
                        leading: Icon(linkedItemTypeIcon(item.type)),
                        title: Text(item.title),
                        subtitle: item.subtitle == null
                            ? null
                            : Text(item.subtitle!),
                        trailing: canEdit
                            ? IconButton(
                                tooltip: '연결 해제',
                                onPressed: () =>
                                    _unlinkItem(context, ref, event, item),
                                icon: const Icon(Icons.link_off),
                              )
                            : null,
                      );
                    }),
                  if (displayLinkedItems.isNotEmpty) const SizedBox(height: 4),
                  if (canEdit)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!hasDateRecordLink)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _createDateRecordFromEvent(context, ref, event),
                            icon: const Icon(Icons.favorite_border),
                            label: const Text('데이트'),
                          ),
                        if (hasDateRecordLink)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _linkTodoItemToDateRecord(context, ref, event),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('버킷'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정을 삭제할까요?'),
        content: Text('${event.title} 일정을 삭제해요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(calendarControllerProvider.notifier).deleteEvent(event.id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _openLinkedItem(BuildContext context, LinkedItem item) {
    final screen = switch (item.type) {
      LinkedItemType.todo => TodoScreen(
        highlightedItemId: todoItemIdForLinkedItem(item),
        highlightedCompletionId: todoCompletionIdForLinkedItem(item),
      ),
      LinkedItemType.dateRecord => DateRecordDetailScreen(
        dateRecordIdForLinkedItem(item),
      ),
      LinkedItemType.conflict => const RecordPlaceholderScreen(
        title: '싸움 기록',
        body: '싸움 기록 상세 화면은 아직 준비 중이에요.',
      ),
      LinkedItemType.review => ReviewDetailScreen(item.targetId),
      LinkedItemType.anniversary => const AnniversaryScreen(),
      LinkedItemType.place => DateRecordDetailScreen(
        dateRecordIdForLinkedItem(item),
      ),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _editEvent(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) async {
    await showEventEditorSheet(
      context: context,
      sheetTitle: '일정 편집',
      initialDate: event.startAt,
      initialEndAt: event.endAt,
      initialTitle: event.title,
      initialMemo: event.memo,
      initialIsAllDay: event.isAllDay,
      initialColorValue: event.colorValue,
      initialOwnership: event.ownership,
      initialReminderOffsetMinutes: event.reminders.isEmpty
          ? null
          : event.reminders.first.offsetMinutes,
      initialLinkedItems: event.linkedItems,
      onSave: (input) => ref
          .read(calendarControllerProvider.notifier)
          .updateEventFromInput(eventId: event.id, input: input),
    );
  }

  Future<void> _linkTodoItemToDateRecord(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) async {
    final dateRecordId = firstDateRecordIdForEvent(event);
    if (dateRecordId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('데이트 없음')));
      return;
    }

    final selection = await showModalBottomSheet<_TodoSelection>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _TodoPickerSheet(todoState: ref.read(todoControllerProvider)),
    );
    if (selection == null || !context.mounted) {
      return;
    }

    final result = await ref
        .read(bucketCompletionServiceProvider)
        .completeItemForEvent(
          item: selection.item,
          event: event,
          category: selection.category,
        );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결됨')));
    }
  }

  Future<void> _createDateRecordFromEvent(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) async {
    final record = await ref
        .read(dateRecordServiceProvider)
        .createDateRecordFromEvent(event);
    if (record == null) {
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결됨')));
    }
  }

  Future<void> _unlinkItem(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
    LinkedItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('해제?'),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('해제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref
        .read(linkedContentServiceProvider)
        .unlinkCalendarEventItem(eventId: event.id, linkedItem: item);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('해제됨')));
    }
  }
}

class _TodoSelection {
  const _TodoSelection({required this.category, required this.item});

  final TodoCategory category;
  final TodoItem item;
}

class _TodoPickerSheet extends StatelessWidget {
  const _TodoPickerSheet({required this.todoState});

  final TodoState todoState;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '버킷리스트 항목 선택',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: todoState.categories.expand((category) {
                  final items = todoState.itemsForCategory(category.id);
                  return [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                      child: Text(
                        '${category.emoji} ${category.title}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    ...items.map((item) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(item.title),
                        subtitle: item.note.isEmpty ? null : Text(item.note),
                        onTap: () => Navigator.of(
                          context,
                        ).pop(_TodoSelection(category: category, item: item)),
                      );
                    }),
                  ];
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.event, required this.currentUserId});

  final CalendarEvent event;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final color = currentUserId.isEmpty
        ? Color(event.colorValue)
        : eventOwnershipColor(event, currentUserId);
    final ownershipLabel = currentUserId.isEmpty
        ? '일정'
        : event.ownershipLabelFor(currentUserId);
    final kindLabel = event.kind == CalendarEventKind.date ? '데이트' : '일정';
    final dateLabel = dates.formatEventRangeLabel(
      startAt: event.startAt,
      endAt: event.endAt,
      isAllDay: event.isAllDay,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                eventOwnershipIcon(event, currentUserId),
                size: 18,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                ownershipLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                event.kind == CalendarEventKind.date
                    ? Icons.favorite_border
                    : Icons.event_outlined,
                size: 17,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                kindLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            event.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            dateLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
          const SizedBox(height: 14),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
        ],
      ),
    );
  }
}

String _reminderLabel(int offsetMinutes) {
  return switch (offsetMinutes) {
    10 => '10분 전',
    60 => '1시간 전',
    1440 => '하루 전',
    _ => '$offsetMinutes분 전',
  };
}
