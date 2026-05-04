import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/app_shell.dart';
import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../anniversaries/presentation/controllers/anniversary_controller.dart';
import '../../../calendar/domain/models/calendar_event.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../../../calendar/presentation/linked_item_presentation.dart';
import '../../../calendar/presentation/widgets/event_editor_sheet.dart';
import '../../../calendar/presentation/widgets/month_calendar.dart';
import '../../domain/models/todo_item.dart';
import '../controllers/todo_controller.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('버킷리스트')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AddCategoryPanel(
              controller: _categoryController,
              onAdd: _addCategory,
            ),
            if (todoState.errorMessage != null) ...[
              const SizedBox(height: 10),
              _ErrorPanel(message: todoState.errorMessage!),
            ],
            const SizedBox(height: 18),
            if (todoState.categories.isEmpty)
              const _EmptyPanel(text: '아직 카테고리가 없어요.')
            else
              ...todoState.categories.map((category) {
                final items = todoState.itemsForCategory(category.id);
                final completionCount = todoState.completionCountForCategory(
                  category.id,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CategoryPanel(
                    category: category,
                    items: items,
                    completionCount: completionCount,
                    completionsForItem: todoState.completionsForItem,
                    onAddItem: _addItem,
                    onCompleteItem: _completeItem,
                    onOpenCompletion: _openCompletionOnCalendar,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _addCategory() {
    ref
        .read(todoControllerProvider.notifier)
        .addCategory(_categoryController.text);
    _categoryController.clear();
  }

  void _addItem(String categoryId, String title, String note) {
    ref
        .read(todoControllerProvider.notifier)
        .addItem(categoryId: categoryId, title: title, note: note);
  }

  Future<void> _completeItem(TodoItem item) async {
    final action = await showModalBottomSheet<_CompletionAction>(
      context: context,
      builder: (context) => const _CompletionActionSheet(),
    );
    if (action == null) {
      return;
    }
    var completedAt = dates.dateOnly(DateTime.now());
    final calendarController = ref.read(calendarControllerProvider.notifier);

    CalendarEvent? event;
    if (action == _CompletionAction.createEvent) {
      final choice = await _pickEventDateForNewEvent(item);
      if (choice == null) {
        return;
      }
      completedAt = choice.date;
      event = await _createEventWithEditor(item, choice.date);
      if (event != null) {
        completedAt = dates.dateOnly(event.startAt);
      }
    } else {
      if (!mounted) {
        return;
      }
      final choice = await _pickExistingEvent(item);
      if (choice == null) {
        return;
      }
      completedAt = choice.date;
      event = choice.event ?? await _createEventWithEditor(item, choice.date);
      if (event != null) {
        completedAt = dates.dateOnly(event.startAt);
      }
    }

    if (event == null) {
      return;
    }

    final completion = ref
        .read(todoControllerProvider.notifier)
        .addCompletion(
          itemId: item.id,
          completedAt: completedAt,
          calendarEventId: event.id,
        );
    if (completion == null) {
      return;
    }

    await calendarController.addLinkedItem(
      eventId: event.id,
      linkedItem: _linkedItemForCompletion(item, completion),
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('달성 기록을 캘린더에 연결했어요.')));
    }
  }

  Future<_EventLinkChoice?> _pickExistingEvent(TodoItem item) async {
    return showModalBottomSheet<_EventLinkChoice>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ExistingEventPickerSheet(
        item: item,
        title: '기존 일정에 연결',
        allowEventSelection: true,
      ),
    );
  }

  Future<_EventLinkChoice?> _pickEventDateForNewEvent(TodoItem item) async {
    return showModalBottomSheet<_EventLinkChoice>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ExistingEventPickerSheet(
        item: item,
        title: '새 일정 날짜 선택',
        allowEventSelection: false,
      ),
    );
  }

  Future<CalendarEvent?> _createEventWithEditor(
    TodoItem item,
    DateTime initialDate,
  ) async {
    CalendarEvent? createdEvent;
    await showEventEditorSheet(
      context: context,
      initialDate: initialDate,
      initialTitle: item.title,
      initialMemo: '버킷리스트를 달성했어요.',
      initialIsAllDay: true,
      initialColorValue: 0xFF4D7C8A,
      previewLinkedItems: [_previewLinkedItemForItem(item, initialDate)],
      onSave: (input) async {
        createdEvent = await ref
            .read(calendarControllerProvider.notifier)
            .createEvent(input);
      },
    );
    return createdEvent;
  }

  Future<void> _openCompletionOnCalendar(TodoCompletion completion) async {
    await ref
        .read(calendarControllerProvider.notifier)
        .selectDate(completion.completedAt);
    ref.read(selectedAppTabProvider.notifier).selectCalendar();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _EventLinkChoice {
  const _EventLinkChoice({required this.date, this.event});

  final DateTime date;
  final CalendarEvent? event;
}

class _ExistingEventPickerSheet extends ConsumerWidget {
  const _ExistingEventPickerSheet({
    required this.item,
    required this.title,
    required this.allowEventSelection,
  });

  final TodoItem item;
  final String title;
  final bool allowEventSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarControllerProvider);
    final anniversaries = ref.watch(visibleAnniversaryOccurrencesProvider);
    final controller = ref.read(calendarControllerProvider.notifier);
    final selectedDate = dates.dateOnly(calendarState.selectedDate);
    final events = calendarState.selectedDateEvents;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: '이전 달',
                  onPressed: controller.goToPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      dates.formatMonthLabel(calendarState.focusedMonth),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '다음 달',
                  onPressed: controller.goToNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            MonthCalendar(
              focusedMonth: calendarState.focusedMonth,
              selectedDate: calendarState.selectedDate,
              events: calendarState.events,
              anniversaries: anniversaries,
              showEventTitles: true,
              onDateSelected: controller.selectDate,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                dates.formatDateLabel(selectedDate),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            if (events.isEmpty || !allowEventSelection)
              _NoEventChoice(
                date: selectedDate,
                message: allowEventSelection
                    ? '이 날짜에는 아직 일정이 없어요.'
                    : '이 날짜에 새 일정을 만들어요.',
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _EventChoiceTile(
                      event: event,
                      onTap: () => Navigator.of(
                        context,
                      ).pop(_EventLinkChoice(date: selectedDate, event: event)),
                    );
                  },
                ),
              ),
            if (events.isNotEmpty && allowEventSelection) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_EventLinkChoice(date: selectedDate)),
                  icon: const Icon(Icons.add),
                  label: const Text('선택한 날짜에 새 일정 편집하기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoEventChoice extends StatelessWidget {
  const _NoEventChoice({required this.date, required this.message});

  final DateTime date;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_EventLinkChoice(date: date)),
            icon: const Icon(Icons.add),
            label: const Text('새 일정 편집하기'),
          ),
        ],
      ),
    );
  }
}

class _EventChoiceTile extends StatelessWidget {
  const _EventChoiceTile({required this.event, required this.onTap});

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeLabel = event.isAllDay
        ? '하루 종일'
        : '${dates.formatTimeLabel(event.startAt)} - ${dates.formatTimeLabel(event.endAt)}';
    return ListTile(
      onTap: onTap,
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(
        event.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        [
          timeLabel,
          if (event.memo.isNotEmpty) event.memo,
          '연결 ${event.linkedItems.length}개',
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Wrap(
        spacing: 4,
        children: event.linkedItems.map((item) {
          return Text(linkedItemEmoji(item.type));
        }).toList(),
      ),
    );
  }
}

LinkedItem _linkedItemForCompletion(TodoItem item, TodoCompletion completion) {
  return LinkedItem(
    type: LinkedItemType.todo,
    targetId: completion.id,
    targetPath: '/todos/${item.id}/completions/${completion.id}',
    title: item.title,
    subtitle: item.note.isEmpty ? null : item.note,
    date: completion.completedAt,
    preview: '버킷리스트 달성',
    createdAt: completion.createdAt,
  );
}

LinkedItem _previewLinkedItemForItem(TodoItem item, DateTime date) {
  return LinkedItem(
    type: LinkedItemType.todo,
    targetId: item.id,
    targetPath: '/todos/${item.id}',
    title: item.title,
    subtitle: item.note.isEmpty ? null : item.note,
    date: date,
    preview: '버킷리스트 연결 예정',
    createdAt: DateTime.now(),
  );
}

enum _CompletionAction { createEvent, linkExistingEvent }

class _CompletionActionSheet extends StatelessWidget {
  const _CompletionActionSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('새 캘린더 일정 만들기'),
              subtitle: const Text('달성 날짜에 새 일정을 만들고 연결해요.'),
              onTap: () =>
                  Navigator.of(context).pop(_CompletionAction.createEvent),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('기존 일정에 연결하기'),
              subtitle: const Text('달성 날짜의 기존 일정 중 하나를 선택해요.'),
              onTap: () => Navigator.of(
                context,
              ).pop(_CompletionAction.linkExistingEvent),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryPanel extends StatelessWidget {
  const _AddCategoryPanel({required this.controller, required this.onAdd});

  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '카테고리 만들기',
                hintText: '예: 등산 하기',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => onAdd(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: '카테고리 추가',
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _CategoryPanel extends StatefulWidget {
  const _CategoryPanel({
    required this.category,
    required this.items,
    required this.completionCount,
    required this.completionsForItem,
    required this.onAddItem,
    required this.onCompleteItem,
    required this.onOpenCompletion,
  });

  final TodoCategory category;
  final List<TodoItem> items;
  final int completionCount;
  final List<TodoCompletion> Function(String itemId) completionsForItem;
  final void Function(String categoryId, String title, String note) onAddItem;
  final ValueChanged<TodoItem> onCompleteItem;
  final ValueChanged<TodoCompletion> onOpenCompletion;

  @override
  State<_CategoryPanel> createState() => _CategoryPanelState();
}

class _CategoryPanelState extends State<_CategoryPanel> {
  final _itemController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _noteController.dispose();
    super.dispose();
  }

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
              Expanded(
                child: Text(
                  widget.category.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${widget.items.length}개 항목 · ${widget.completionCount}회 달성',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _itemController,
                  decoration: const InputDecoration(
                    labelText: '세부 항목',
                    hintText: '예: 남산 가기',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '항목 추가',
                onPressed: _addItem,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '메모',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.items.isEmpty)
            const _EmptyPanel(text: '세부 항목이 아직 없어요.')
          else
            ...widget.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BucketItemTile(
                  item: item,
                  completions: widget.completionsForItem(item.id),
                  onComplete: () => widget.onCompleteItem(item),
                  onOpenCompletion: widget.onOpenCompletion,
                ),
              );
            }),
        ],
      ),
    );
  }

  void _addItem() {
    widget.onAddItem(
      widget.category.id,
      _itemController.text,
      _noteController.text,
    );
    _itemController.clear();
    _noteController.clear();
  }
}

class _BucketItemTile extends StatelessWidget {
  const _BucketItemTile({
    required this.item,
    required this.completions,
    required this.onComplete,
    required this.onOpenCompletion,
  });

  final TodoItem item;
  final List<TodoCompletion> completions;
  final VoidCallback onComplete;
  final ValueChanged<TodoCompletion> onOpenCompletion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (item.note.isNotEmpty)
                      Text(
                        item.note,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onComplete,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('달성'),
              ),
            ],
          ),
          if (completions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: completions.map((completion) {
                return ActionChip(
                  avatar: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(dates.formatDateLabel(completion.completedAt)),
                  onPressed: () => onOpenCompletion(completion),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
