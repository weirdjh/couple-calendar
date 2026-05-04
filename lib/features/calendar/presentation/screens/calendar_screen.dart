import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../anniversaries/domain/models/anniversary.dart';
import '../../../anniversaries/presentation/controllers/anniversary_controller.dart';
import '../../../anniversaries/presentation/screens/anniversary_screen.dart';
import '../../../date_records/presentation/screens/date_record_screen.dart';
import '../../../records/presentation/screens/record_placeholder_screen.dart';
import '../../../todos/domain/models/todo_item.dart';
import '../../../todos/presentation/controllers/todo_controller.dart';
import '../../../todos/presentation/screens/todo_screen.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/event_input.dart';
import '../controllers/calendar_controller.dart';
import '../linked_item_presentation.dart';
import '../widgets/event_editor_sheet.dart';
import '../widgets/month_calendar.dart';
import 'event_detail_screen.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarControllerProvider);
    final anniversaryOccurrences = ref.watch(
      visibleAnniversaryOccurrencesProvider,
    );
    final selectedAnniversaries = ref.watch(
      selectedDateAnniversaryOccurrencesProvider,
    );
    final controller = ref.read(calendarControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Couple Calendar'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: '이전 달',
            onPressed: controller.goToPreviousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Center(
            child: Text(
              dates.formatMonthLabel(state.focusedMonth),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: '다음 달',
            onPressed: controller.goToNextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 92),
          children: [
            if (state.errorMessage != null)
              _ErrorBanner(message: state.errorMessage!),
            MonthCalendar(
              focusedMonth: state.focusedMonth,
              selectedDate: state.selectedDate,
              events: state.events,
              anniversaries: anniversaryOccurrences,
              onDateSelected: controller.selectDate,
            ),
            _SelectedDayPanel(
              selectedDate: state.selectedDate,
              events: state.selectedDateEvents,
              anniversaries: selectedAnniversaries,
              isLoading: state.isLoading,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isSaving
            ? null
            : () => showEventEditorSheet(
                context: context,
                initialDate: state.selectedDate,
                onAddLinkedItem: (context) =>
                    _pickTodoLinkedItem(context, ref, state.selectedDate),
                onSave: (input) => _createEventWithLinkedItems(ref, input),
              ),
        icon: const Icon(Icons.add),
        label: const Text('일정'),
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
      final completion = ref
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

  Future<LinkedItem?> _pickTodoLinkedItem(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) async {
    final selection = await showModalBottomSheet<_TodoSelection>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _TodoPickerSheet(todoState: ref.read(todoControllerProvider)),
    );
    if (selection == null) {
      return null;
    }
    return LinkedItem(
      type: LinkedItemType.todo,
      targetId: selection.item.id,
      targetPath: '/todos/${selection.item.id}',
      title: selection.item.title,
      subtitle: selection.category.title,
      date: dates.dateOnly(selectedDate),
      preview: '버킷리스트 연결 예정',
      createdAt: DateTime.now(),
    );
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
      createdAt: completion.createdAt,
    );
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
                        category.title,
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

class _SelectedDayPanel extends StatelessWidget {
  const _SelectedDayPanel({
    required this.selectedDate,
    required this.events,
    required this.anniversaries,
    required this.isLoading,
  });

  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final List<AnniversaryOccurrence> anniversaries;
  final bool isLoading;

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
          Text(
            dates.formatDateLabel(selectedDate),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
          _LinkedSummary(events: events),
          _LinkedPhotoSummary(events: events),
          if (_linkedItemsForEvents(events).isNotEmpty ||
              _linkedPhotosForEvents(events).isNotEmpty)
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
                return _EventTile(event: event);
              },
            ),
        ],
      ),
    );
  }
}

class _LinkedSummary extends StatelessWidget {
  const _LinkedSummary({required this.events});

  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final linkedItems = _linkedItemsForEvents(events);
    if (linkedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: linkedItems.map((item) {
        return ActionChip(
          avatar: Text(linkedItemEmoji(item.type)),
          label: Text(item.title),
          onPressed: () => _openLinkedItem(context, item),
        );
      }).toList(),
    );
  }
}

class _LinkedPhotoSummary extends StatelessWidget {
  const _LinkedPhotoSummary({required this.events});

  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final photos = _linkedPhotosForEvents(events);
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: photos.map((item) {
          return InkWell(
            onTap: () => _openLinkedItem(context, item),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    );
  }
}

List<LinkedItem> _linkedItemsForEvents(List<CalendarEvent> events) {
  return events.expand((event) => event.linkedItems).toList();
}

List<LinkedItem> _linkedPhotosForEvents(List<CalendarEvent> events) {
  return _linkedItemsForEvents(events)
      .where(
        (item) => item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty,
      )
      .toList();
}

void _openLinkedItem(BuildContext context, LinkedItem item) {
  final screen = switch (item.type) {
    LinkedItemType.todo => const TodoScreen(),
    LinkedItemType.dateRecord => const DateRecordScreen(),
    LinkedItemType.conflict => const RecordPlaceholderScreen(
      title: '싸움 기록',
      body: '싸움 기록 상세 화면은 아직 준비 중이에요.',
    ),
    LinkedItemType.review => const RecordPlaceholderScreen(
      title: '리뷰',
      body: '리뷰 상세 화면은 아직 준비 중이에요.',
    ),
    LinkedItemType.anniversary => const AnniversaryScreen(),
    LinkedItemType.place => const DateRecordScreen(),
  };
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final color = Color(event.colorValue);
    final timeLabel = event.isAllDay
        ? '하루 종일'
        : '${dates.formatTimeLabel(event.startAt)} - ${dates.formatTimeLabel(event.endAt)}';

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
          [timeLabel, if (event.memo.isNotEmpty) event.memo].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
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
