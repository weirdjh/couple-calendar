import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../anniversaries/domain/models/anniversary.dart';
import '../../../anniversaries/presentation/controllers/anniversary_controller.dart';
import '../../../anniversaries/presentation/screens/anniversary_screen.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../date_records/presentation/screens/date_record_screen.dart';
import '../../../date_records/domain/models/date_record.dart';
import '../../../date_records/presentation/controllers/date_record_controller.dart';
import '../../../records/presentation/screens/record_placeholder_screen.dart';
import '../../../reviews/presentation/screens/review_screen.dart';
import '../../../todos/domain/models/todo_item.dart';
import '../../../todos/presentation/controllers/todo_controller.dart';
import '../../../todos/presentation/screens/todo_screen.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/event_input.dart';
import '../controllers/calendar_controller.dart';
import '../event_ownership_presentation.dart';
import '../linked_item_presentation.dart';
import '../widgets/event_editor_sheet.dart';
import '../widgets/month_calendar.dart';
import 'event_detail_screen.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarControllerProvider);
    final currentUserId =
        ref.watch(sessionControllerProvider).currentUser?.id ?? '';
    final anniversaryOccurrences = ref.watch(
      visibleAnniversaryOccurrencesProvider,
    );
    final controller = ref.read(calendarControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '이전 달',
              onPressed: controller.goToPreviousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            TextButton(
              onPressed: () =>
                  _pickFocusedMonth(context, ref, state.focusedMonth),
              child: Text(
                dates.formatMonthLabel(state.focusedMonth),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              tooltip: '다음 달',
              onPressed: controller.goToNextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: controller.goToToday, child: const Text('오늘')),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (state.errorMessage != null)
              _ErrorBanner(message: state.errorMessage!),
            MonthCalendar(
              focusedMonth: state.focusedMonth,
              selectedDate: state.selectedDate,
              events: state.events,
              anniversaries: anniversaryOccurrences,
              showEventTitles: true,
              currentUserId: currentUserId,
              onDateSelected: (date) => _openDateSummary(context, ref, date),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFocusedMonth(
    BuildContext context,
    WidgetRef ref,
    DateTime focusedMonth,
  ) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthPickerDialog(initialMonth: focusedMonth),
    );
    if (picked == null) {
      return;
    }
    await ref.read(calendarControllerProvider.notifier).goToMonth(picked);
  }

  Future<void> _openDateSummary(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) async {
    await ref.read(calendarControllerProvider.notifier).selectDate(date);
    if (!context.mounted) {
      return;
    }

    final state = ref.read(calendarControllerProvider);
    final anniversaries = ref.read(selectedDateAnniversaryOccurrencesProvider);
    final currentUserId =
        ref.read(sessionControllerProvider).currentUser?.id ?? '';
    final dateRecords = ref.read(dateRecordControllerProvider).records;
    final selectedDate = dates.dateOnly(date);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: _SelectedDayPanel(
              selectedDate: selectedDate,
              events: state.selectedDateEvents,
              anniversaries: anniversaries,
              isLoading: state.isLoading,
              currentUserId: currentUserId,
              dateRecords: dateRecords,
              onAddEvent: () {
                Navigator.of(sheetContext).pop();
                _showCreateEventEditor(context, ref, selectedDate);
              },
              onAddDateRecord: () {
                Navigator.of(sheetContext).pop();
                _showCreateDateRecord(context, selectedDate);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateEventEditor(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    return showEventEditorSheet(
      context: context,
      initialDate: selectedDate,
      onSave: (input) => _createEventWithLinkedItems(ref, input),
    );
  }

  Future<void> _showCreateDateRecord(
    BuildContext context,
    DateTime selectedDate,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DateRecordEditScreen(initialDate: selectedDate),
      ),
    );
  }

  Future<void> _createEventWithLinkedItems(
    WidgetRef ref,
    EventInput input,
  ) async {
    final pendingLinks = input.linkedItems;
    final controller = ref.read(calendarControllerProvider.notifier);
    final event = await controller.createEvent(input.copyWith(linkedItems: []));
    if (event == null) {
      return;
    }

    for (final item in pendingLinks) {
      if (item.type != LinkedItemType.todo) {
        await controller.addLinkedItem(eventId: event.id, linkedItem: item);
        continue;
      }
      final completion = await ref
          .read(todoControllerProvider.notifier)
          .addCompletion(
            itemId: item.targetId,
            completedAt: dates.dateOnly(event.startAt),
            calendarEventId: event.id,
          );
      if (completion == null) {
        continue;
      }
      await controller.addLinkedItem(
        eventId: event.id,
        linkedItem: item.copyWithTodoCompletion(completion, event.startAt),
      );
    }
  }
}

extension on LinkedItem {
  LinkedItem copyWithTodoCompletion(
    TodoCompletion completion,
    DateTime eventStartAt,
  ) {
    return LinkedItem(
      type: LinkedItemType.todo,
      targetId: completion.id,
      targetPath: '$targetPath/completions/${completion.id}',
      title: title,
      subtitle: subtitle,
      date: dates.dateOnly(eventStartAt),
      thumbnailUrl: thumbnailUrl,
      preview: '버킷리스트 달성',
      emoji: emoji,
      createdAt: completion.createdAt,
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initialMonth.year;
  late int _month = widget.initialMonth.month;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: '이전 해',
                    onPressed: () => setState(() => _year -= 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      '$_year',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: '다음 해',
                    onPressed: () => setState(() => _year += 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.85,
                children: List.generate(12, (index) {
                  final month = index + 1;
                  final selected = month == _month;
                  return Material(
                    color: selected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _month = month),
                      child: Center(
                        child: Text(
                          '$month월',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: selected
                                    ? scheme.onPrimary
                                    : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      final now = DateTime.now();
                      setState(() {
                        _year = now.year;
                        _month = now.month;
                      });
                    },
                    child: const Text('오늘'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(DateTime(_year, _month)),
                    child: const Text('이동'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDayPanel extends StatelessWidget {
  const _SelectedDayPanel({
    required this.selectedDate,
    required this.events,
    required this.anniversaries,
    required this.isLoading,
    required this.currentUserId,
    required this.dateRecords,
    required this.onAddEvent,
    required this.onAddDateRecord,
  });

  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final List<AnniversaryOccurrence> anniversaries;
  final bool isLoading;
  final String currentUserId;
  final List<DateRecord> dateRecords;
  final VoidCallback onAddEvent;
  final VoidCallback onAddDateRecord;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dates.formatDateLabel(selectedDate),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: '닫기',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (anniversaries.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: anniversaries.map((occurrence) {
                return Chip(
                  avatar: const Icon(Icons.celebration_outlined, size: 18),
                  label: Text('${occurrence.title} ${occurrence.label}'),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          _LinkedSummary(events: events, dateRecords: dateRecords),
          _LinkedPhotoSummary(events: events, dateRecords: dateRecords),
          if (_linkedItemsForEvents(events, dateRecords).isNotEmpty ||
              _linkedPhotosForEvents(events, dateRecords).isNotEmpty)
            const SizedBox(height: 12),
          if (isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else if (events.isEmpty && anniversaries.isEmpty)
            const _EmptyDay()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = events[index];
                return _EventTile(event: event, currentUserId: currentUserId);
              },
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddDateRecord,
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('데이트 기록 추가'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddEvent,
                  icon: const Icon(Icons.add),
                  label: Text(events.isEmpty ? '일정 추가' : '일정 추가'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkedSummary extends StatelessWidget {
  const _LinkedSummary({required this.events, required this.dateRecords});

  final List<CalendarEvent> events;
  final List<DateRecord> dateRecords;

  @override
  Widget build(BuildContext context) {
    final linkedItems = _linkedItemsForEvents(events, dateRecords);
    if (linkedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '연결된 기록',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: linkedItems.map((item) {
            return ActionChip(
              avatar: Icon(linkedItemTypeIcon(item.type), size: 18),
              label: Text(item.title),
              onPressed: () => _openLinkedItem(context, item),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LinkedPhotoSummary extends StatelessWidget {
  const _LinkedPhotoSummary({required this.events, required this.dateRecords});

  final List<CalendarEvent> events;
  final List<DateRecord> dateRecords;

  @override
  Widget build(BuildContext context) {
    final photos = _linkedPhotosForEvents(events, dateRecords);
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '연결된 사진',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: photos.map((item) {
              return InkWell(
                onTap: () => _openLinkedItem(context, item),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_outlined, size: 18),
                      const SizedBox(height: 3),
                      Text(
                        item.thumbnailUrl!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

List<LinkedItem> _linkedItemsForEvents(
  List<CalendarEvent> events,
  List<DateRecord> dateRecords,
) {
  final directItems = events.expand((event) => event.linkedItems);
  final dateRecordIds = directItems
      .where((item) => item.type == LinkedItemType.dateRecord)
      .map(dateRecordIdForLinkedItem)
      .nonNulls
      .toSet();
  final nestedItems = dateRecords
      .where((record) => dateRecordIds.contains(record.id))
      .expand((record) => record.linkedItems);
  final result = <LinkedItem>[];
  final seen = <String>{};
  for (final item in [...directItems, ...nestedItems]) {
    final key = '${item.type.name}:${item.targetId}';
    if (seen.add(key)) {
      result.add(item);
    }
  }
  return result;
}

List<LinkedItem> _linkedPhotosForEvents(
  List<CalendarEvent> events,
  List<DateRecord> dateRecords,
) {
  return _linkedItemsForEvents(events, dateRecords)
      .where(
        (item) => item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty,
      )
      .toList();
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

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.currentUserId});

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
    final timeLabel = dates.formatEventRangeLabel(
      startAt: event.startAt,
      endAt: event.endAt,
      isAllDay: event.isAllDay,
    );

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: event.id),
          ),
        ),
        leading: Container(
          width: 4,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            ownershipLabel,
            timeLabel,
            if (event.memo.isNotEmpty) event.memo,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (event.isPartnerOwnedFor(currentUserId) &&
                event.isWatchedBy(currentUserId))
              const Icon(Icons.notifications_active_outlined, size: 18),
            if (event.reminders.isNotEmpty)
              const Icon(Icons.notifications_outlined, size: 18),
            if (event.linkedItems.isNotEmpty) const Icon(Icons.link, size: 18),
          ],
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 44,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            '아직 등록된 일정이 없어요.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
