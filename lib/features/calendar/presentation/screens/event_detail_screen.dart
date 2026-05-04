import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../anniversaries/presentation/screens/anniversary_screen.dart';
import '../../../date_records/presentation/screens/date_record_screen.dart';
import '../../../records/presentation/screens/record_placeholder_screen.dart';
import '../../../todos/domain/models/todo_item.dart';
import '../../../todos/presentation/controllers/todo_controller.dart';
import '../../../todos/presentation/screens/todo_screen.dart';
import '../../domain/models/calendar_event.dart';
import '../controllers/calendar_controller.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 상세'),
        actions: [
          IconButton(
            tooltip: '편집',
            onPressed: () => _editEvent(context, ref, event),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '삭제',
            onPressed: () async {
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
              await ref
                  .read(calendarControllerProvider.notifier)
                  .deleteEvent(event.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Header(event: event),
            const SizedBox(height: 18),
            _Section(
              title: '메모',
              icon: Icons.notes_outlined,
              child: Text(
                event.memo.isEmpty ? '메모가 없어요.' : event.memo,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: '알림',
              icon: Icons.notifications_outlined,
              child: event.reminders.isEmpty
                  ? const Text('설정된 알림이 없어요.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: event.reminders.map((reminder) {
                        return Text(
                          '${_reminderLabel(reminder.offsetMinutes)} · ${dates.formatDateLabel(reminder.remindAt)} ${dates.formatTimeLabel(reminder.remindAt)}',
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: '연결된 항목',
              icon: Icons.link,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.linkedItems.isEmpty)
                    const Text('아직 연결된 항목이 없어요.')
                  else
                    ...event.linkedItems.map((item) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _openLinkedItem(context, item),
                        leading: Icon(_linkedItemIcon(item.type)),
                        title: Text(item.title),
                        subtitle: item.subtitle == null
                            ? null
                            : Text(item.subtitle!),
                        trailing: IconButton(
                          tooltip: '연결 해제',
                          onPressed: () =>
                              _unlinkItem(context, ref, event, item),
                          icon: const Icon(Icons.link_off),
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _linkTodoItem(context, ref, event),
                      icon: const Icon(Icons.add_link),
                      label: const Text('버킷리스트 연결'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _editEvent(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) async {
    final durationHours = event.endAt.difference(event.startAt).inHours;
    await showEventEditorSheet(
      context: context,
      sheetTitle: '일정 편집',
      initialDate: event.startAt,
      initialTitle: event.title,
      initialMemo: event.memo,
      initialIsAllDay: event.isAllDay,
      initialColorValue: event.colorValue,
      initialDurationHours: durationHours <= 0 ? 1 : durationHours,
      initialReminderOffsetMinutes: event.reminders.isEmpty
          ? null
          : event.reminders.first.offsetMinutes,
      initialLinkedItems: event.linkedItems,
      onSave: (input) => ref
          .read(calendarControllerProvider.notifier)
          .updateEventFromInput(eventId: event.id, input: input),
    );
  }

  Future<void> _linkTodoItem(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) async {
    final selection = await showModalBottomSheet<_TodoSelection>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _TodoPickerSheet(todoState: ref.read(todoControllerProvider)),
    );
    if (selection == null || !context.mounted) {
      return;
    }

    final completedAt = dates.dateOnly(event.startAt);
    final completion = ref
        .read(todoControllerProvider.notifier)
        .addCompletion(
          itemId: selection.item.id,
          completedAt: completedAt,
          calendarEventId: event.id,
        );
    if (completion == null) {
      return;
    }

    await ref
        .read(calendarControllerProvider.notifier)
        .addLinkedItem(
          eventId: event.id,
          linkedItem: LinkedItem(
            type: LinkedItemType.todo,
            targetId: completion.id,
            targetPath:
                '/todos/${selection.item.id}/completions/${completion.id}',
            title: selection.item.title,
            subtitle: selection.category.title,
            date: completedAt,
            preview: '버킷리스트 달성',
            createdAt: completion.createdAt,
          ),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('버킷리스트를 일정에 연결했어요.')));
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
        title: const Text('연결을 해제할까요?'),
        content: Text('${item.title} 연결을 이 일정에서 제거해요.'),
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
        .read(calendarControllerProvider.notifier)
        .removeLinkedItem(eventId: event.id, linkedItem: item);
    if (item.type == LinkedItemType.todo) {
      ref.read(todoControllerProvider.notifier).removeCompletion(item.targetId);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결을 해제했어요.')));
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

class _Header extends StatelessWidget {
  const _Header({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final color = Color(event.colorValue);
    final dateLabel = event.isAllDay
        ? '${dates.formatDateLabel(event.startAt)} · 하루 종일'
        : '${dates.formatDateLabel(event.startAt)} ${dates.formatTimeLabel(event.startAt)} - ${dates.formatTimeLabel(event.endAt)}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
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
          const SizedBox(height: 6),
          Text(
            '작성자: ${event.createdBy}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
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

IconData _linkedItemIcon(LinkedItemType type) {
  return switch (type) {
    LinkedItemType.todo => Icons.check_circle_outline,
    LinkedItemType.dateRecord => Icons.place_outlined,
    LinkedItemType.conflict => Icons.favorite_border,
    LinkedItemType.anniversary => Icons.celebration_outlined,
    LinkedItemType.review => Icons.star_border,
    LinkedItemType.place => Icons.map_outlined,
  };
}
