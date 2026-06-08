import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/app_shell.dart';
import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../anniversaries/presentation/controllers/anniversary_controller.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../calendar/domain/models/calendar_event.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../../../calendar/presentation/linked_item_presentation.dart';
import '../../../calendar/presentation/widgets/event_editor_sheet.dart';
import '../../../calendar/presentation/widgets/month_calendar.dart';
import '../../../links/application/linked_content_service.dart';
import '../../application/bucket_completion_service.dart';
import '../../domain/models/todo_item.dart';
import '../controllers/todo_controller.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({
    this.highlightedItemId,
    this.highlightedCompletionId,
    super.key,
  });

  final String? highlightedItemId;
  final String? highlightedCompletionId;

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoControllerProvider);
    final isHighlightingLink =
        widget.highlightedItemId != null ||
        widget.highlightedCompletionId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('버킷리스트'),
        actions: [
          IconButton(
            tooltip: '버킷리스트 카테고리 추가',
            onPressed: _openAddCategoryScreen,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (isHighlightingLink) ...[
              const _LinkedTargetBanner(),
              const SizedBox(height: 12),
            ],
            if (todoState.errorMessage != null) ...[
              _ErrorPanel(message: todoState.errorMessage!),
              const SizedBox(height: 12),
            ],
            if (todoState.categories.isEmpty)
              _EmptyPanel(
                text: '아직 버킷리스트 카테고리가 없어요.',
                actionLabel: '카테고리 추가',
                onAction: _openAddCategoryScreen,
              )
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
                    highlightedItemId: widget.highlightedItemId,
                    highlightedCompletionId: widget.highlightedCompletionId,
                    onAddItem: _openAddItemScreen,
                    onOpenCategoryEditor: _openEditCategoryScreen,
                    onOpenItem: _openItemDetail,
                    onCompleteItem: _completeItem,
                    onOpenCompletion: _openCompletionOnCalendar,
                    onDeleteCompletion: _confirmDeleteCompletion,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _openAddCategoryScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BucketCategoryEditScreen()));
  }

  void _openEditCategoryScreen(TodoCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BucketCategoryEditScreen(category: category),
      ),
    );
  }

  void _openAddItemScreen(TodoCategory category) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BucketItemEditScreen(category)));
  }

  void _openItemDetail(TodoItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BucketItemDetailScreen(itemId: item.id),
      ),
    );
  }

  Future<void> _completeItem(TodoItem item) async {
    final action = await showModalBottomSheet<_CompletionAction>(
      context: context,
      builder: (context) => const _CompletionActionSheet(),
    );
    if (action == null) {
      return;
    }
    CalendarEvent? event;
    final category = ref.read(todoControllerProvider).categoryForItem(item.id);
    if (action == _CompletionAction.createEvent) {
      final choice = await _pickEventDateForNewEvent(item);
      if (choice == null) {
        return;
      }
      event = await _createEventWithEditor(item, choice.date);
    } else {
      if (!mounted) {
        return;
      }
      final choice = await _pickExistingEvent(item);
      if (choice == null) {
        return;
      }
      event = choice.event ?? await _createEventWithEditor(item, choice.date);
    }

    if (event == null) {
      return;
    }

    final result = await ref
        .read(bucketCompletionServiceProvider)
        .completeItemForEvent(item: item, event: event, category: category);
    if (result != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결됨')));
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
      initialColorValue: 0xFF4169E1,
      initialOwnership: EventOwnership.shared,
      previewLinkedItems: [
        previewLinkedItemForTodoItem(
          item: item,
          date: initialDate,
          category: ref.read(todoControllerProvider).categoryForItem(item.id),
        ),
      ],
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

  Future<void> _confirmDeleteCompletion(TodoCompletion completion) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('삭제?'),
          content: const Text('달성'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) {
      return;
    }
    await ref
        .read(linkedContentServiceProvider)
        .removeTodoCompletionEverywhere(completion.id);
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
    final currentUserId =
        ref.watch(sessionControllerProvider).currentUser?.id ?? '';
    final controller = ref.read(calendarControllerProvider.notifier);
    final selectedDate = dates.dateOnly(calendarState.selectedDate);
    final events = calendarState.selectedDateEvents;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.88,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
              Expanded(
                child: ListView(
                  children: [
                    MonthCalendar(
                      focusedMonth: calendarState.focusedMonth,
                      selectedDate: calendarState.selectedDate,
                      events: calendarState.events,
                      anniversaries: anniversaries,
                      showEventTitles: true,
                      currentUserId: currentUserId,
                      onDateSelected: controller.selectDate,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dates.formatDateLabel(selectedDate),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
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
                      ...events.map((event) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _EventChoiceTile(
                            event: event,
                            onTap: () => Navigator.of(context).pop(
                              _EventLinkChoice(
                                date: selectedDate,
                                event: event,
                              ),
                            ),
                          ),
                        );
                      }),
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
            ],
          ),
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
    final timeLabel = dates.formatEventRangeLabel(
      startAt: event.startAt,
      endAt: event.endAt,
      isAllDay: event.isAllDay,
    );
    return ListTile(
      onTap: onTap,
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(
        event.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        [timeLabel, if (event.memo.isNotEmpty) event.memo].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Wrap(
        spacing: 4,
        children: event.linkedItems.map((item) {
          return Icon(linkedItemTypeIcon(item.type), size: 18);
        }).toList(),
      ),
    );
  }
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
              title: const Text('새 일정'),
              onTap: () =>
                  Navigator.of(context).pop(_CompletionAction.createEvent),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('기존 일정'),
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

class BucketItemDetailScreen extends ConsumerWidget {
  const BucketItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoState = ref.watch(todoControllerProvider);
    final item = todoState.itemById(itemId);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('버킷리스트 항목을 찾을 수 없어요.')),
      );
    }
    final category = todoState.categoryById(item.categoryId);
    final completions = todoState.completionsForItem(item.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('버킷리스트 상세'),
        actions: [
          if (category != null)
            IconButton(
              tooltip: '항목 편집',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BucketItemEditScreen(category, item: item),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _BucketItemHeader(item: item, category: category),
            const SizedBox(height: 12),
            _BucketDetailSection(
              icon: Icons.notes_outlined,
              title: '메모',
              child: Text(item.note.isEmpty ? '메모가 없어요.' : item.note),
            ),
            const SizedBox(height: 12),
            _BucketDetailSection(
              icon: Icons.calendar_month_outlined,
              title: '달성 기록',
              child: completions.isEmpty
                  ? const Text('아직 달성 기록이 없어요.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: completions.map((completion) {
                        return InputChip(
                          avatar: const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                          ),
                          label: Text(
                            dates.formatDateLabel(completion.completedAt),
                          ),
                          onPressed: () => _openCompletionOnCalendar(
                            context,
                            ref,
                            completion,
                          ),
                          onDeleted: () => _confirmDeleteCompletion(
                            context,
                            ref,
                            completion,
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCompletionOnCalendar(
    BuildContext context,
    WidgetRef ref,
    TodoCompletion completion,
  ) async {
    await ref
        .read(calendarControllerProvider.notifier)
        .selectDate(completion.completedAt);
    ref.read(selectedAppTabProvider.notifier).selectCalendar();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _confirmDeleteCompletion(
    BuildContext context,
    WidgetRef ref,
    TodoCompletion completion,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('삭제?'),
          content: const Text('달성'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) {
      return;
    }
    await ref
        .read(linkedContentServiceProvider)
        .removeTodoCompletionEverywhere(completion.id);
  }
}

class _BucketItemHeader extends StatelessWidget {
  const _BucketItemHeader({required this.item, required this.category});

  final TodoItem item;
  final TodoCategory? category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            avatar: Text(category?.emoji ?? '🧭'),
            label: Text(category?.title ?? '버킷리스트'),
            backgroundColor: scheme.surface,
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _BucketDetailSection extends StatelessWidget {
  const _BucketDetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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

class BucketCategoryEditScreen extends ConsumerStatefulWidget {
  const BucketCategoryEditScreen({this.category, super.key});

  final TodoCategory? category;

  @override
  ConsumerState<BucketCategoryEditScreen> createState() =>
      _BucketCategoryEditScreenState();
}

class _BucketCategoryEditScreenState
    extends ConsumerState<BucketCategoryEditScreen> {
  final _categoryController = TextEditingController();
  final _categoryEmojiController = TextEditingController(text: '🧭');
  var _didSeed = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _categoryEmojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = ref.watch(todoControllerProvider).errorMessage;
    _seed();
    final isEditing = widget.category != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '카테고리 편집' : '카테고리 추가')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AddCategoryPanel(
              controller: _categoryController,
              emojiController: _categoryEmojiController,
              onAdd: _addCategory,
              actionLabel: isEditing ? '변경 저장' : '카테고리 저장',
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorPanel(message: errorMessage),
            ],
          ],
        ),
      ),
    );
  }

  void _seed() {
    if (_didSeed) {
      return;
    }
    _didSeed = true;
    final category = widget.category;
    if (category == null) {
      return;
    }
    _categoryController.text = category.title;
    _categoryEmojiController.text = category.emoji;
  }

  Future<void> _addCategory() async {
    final category = widget.category;
    final controller = ref.read(todoControllerProvider.notifier);
    final added = await (category == null
        ? controller.addCategory(
            title: _categoryController.text,
            emoji: _categoryEmojiController.text,
          )
        : controller.updateCategory(
            categoryId: category.id,
            title: _categoryController.text,
            emoji: _categoryEmojiController.text,
          ));
    if (added == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class BucketItemEditScreen extends ConsumerStatefulWidget {
  const BucketItemEditScreen(this.category, {this.item, super.key});

  final TodoCategory category;
  final TodoItem? item;

  @override
  ConsumerState<BucketItemEditScreen> createState() =>
      _BucketItemEditScreenState();
}

class _BucketItemEditScreenState extends ConsumerState<BucketItemEditScreen> {
  final _itemController = TextEditingController();
  final _noteController = TextEditingController();
  var _didSeed = false;

  @override
  void dispose() {
    _itemController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = ref.watch(todoControllerProvider).errorMessage;
    _seed();
    final isEditing = widget.item != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '항목 편집' : '항목 추가')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${widget.category.emoji} ${widget.category.title}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(
                labelText: '세부 항목',
                hintText: '예: 남산 가기',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '메모',
                border: OutlineInputBorder(),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorPanel(message: errorMessage),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.check),
                label: Text(isEditing ? '변경 저장' : '항목 저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _seed() {
    if (_didSeed) {
      return;
    }
    _didSeed = true;
    final item = widget.item;
    if (item == null) {
      return;
    }
    _itemController.text = item.title;
    _noteController.text = item.note;
  }

  Future<void> _addItem() async {
    final item = widget.item;
    final controller = ref.read(todoControllerProvider.notifier);
    final added = await (item == null
        ? controller.addItem(
            categoryId: widget.category.id,
            title: _itemController.text,
            note: _noteController.text,
          )
        : controller.updateItem(
            itemId: item.id,
            title: _itemController.text,
            note: _noteController.text,
          ));
    if (added == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _AddCategoryPanel extends StatelessWidget {
  const _AddCategoryPanel({
    required this.controller,
    required this.emojiController,
    required this.onAdd,
    required this.actionLabel,
  });

  final TextEditingController controller;
  final TextEditingController emojiController;
  final VoidCallback onAdd;
  final String actionLabel;

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
        children: [
          Row(
            children: [
              SizedBox(
                width: 76,
                child: TextField(
                  controller: emojiController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '이모지',
                    hintText: '⛰️',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.center,
                  onTap: () => _pickEmoji(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: '카테고리 이름',
                    hintText: '예: 등산 하기',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.check),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickEmoji(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => const _EmojiPickerSheet(),
    );
    if (selected == null) {
      return;
    }
    emojiController.text = selected;
  }
}

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet();

  static const emojis = [
    '🧭',
    '⛰️',
    '🍷',
    '🎬',
    '🍽️',
    '☕',
    '🌊',
    '🎡',
    '🏕️',
    '🚲',
    '🎨',
    '🎵',
  ];

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
              '카테고리 이모지 선택',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: emojis.map((emoji) {
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pop(emoji),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
    required this.highlightedItemId,
    required this.highlightedCompletionId,
    required this.onAddItem,
    required this.onOpenCategoryEditor,
    required this.onOpenItem,
    required this.onCompleteItem,
    required this.onOpenCompletion,
    required this.onDeleteCompletion,
  });

  final TodoCategory category;
  final List<TodoItem> items;
  final int completionCount;
  final List<TodoCompletion> Function(String itemId) completionsForItem;
  final String? highlightedItemId;
  final String? highlightedCompletionId;
  final ValueChanged<TodoCategory> onAddItem;
  final ValueChanged<TodoCategory> onOpenCategoryEditor;
  final ValueChanged<TodoItem> onOpenItem;
  final ValueChanged<TodoItem> onCompleteItem;
  final ValueChanged<TodoCompletion> onOpenCompletion;
  final ValueChanged<TodoCompletion> onDeleteCompletion;

  @override
  State<_CategoryPanel> createState() => _CategoryPanelState();
}

class _CategoryPanelState extends State<_CategoryPanel> {
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
                  '${widget.category.emoji} ${widget.category.title}',
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
              const SizedBox(width: 8),
              IconButton(
                tooltip: '카테고리 편집',
                onPressed: () => widget.onOpenCategoryEditor(widget.category),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton.filledTonal(
                tooltip: '버킷리스트 항목 추가',
                onPressed: () => widget.onAddItem(widget.category),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.items.isEmpty)
            _EmptyPanel(
              text: '세부 항목이 아직 없어요.',
              actionLabel: '항목 추가',
              onAction: () => widget.onAddItem(widget.category),
            )
          else
            ...widget.items.map((item) {
              final isHighlightedItem = item.id == widget.highlightedItemId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BucketItemTile(
                  item: item,
                  completions: widget.completionsForItem(item.id),
                  isHighlighted: isHighlightedItem,
                  highlightedCompletionId: widget.highlightedCompletionId,
                  onOpen: () => widget.onOpenItem(item),
                  onComplete: () => widget.onCompleteItem(item),
                  onOpenCompletion: widget.onOpenCompletion,
                  onDeleteCompletion: widget.onDeleteCompletion,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _BucketItemTile extends StatelessWidget {
  const _BucketItemTile({
    required this.item,
    required this.completions,
    required this.isHighlighted,
    required this.highlightedCompletionId,
    required this.onOpen,
    required this.onComplete,
    required this.onOpenCompletion,
    required this.onDeleteCompletion,
  });

  final TodoItem item;
  final List<TodoCompletion> completions;
  final bool isHighlighted;
  final String? highlightedCompletionId;
  final VoidCallback onOpen;
  final VoidCallback onComplete;
  final ValueChanged<TodoCompletion> onOpenCompletion;
  final ValueChanged<TodoCompletion> onDeleteCompletion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isHighlighted
          ? scheme.primaryContainer.withValues(alpha: 0.60)
          : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHighlighted ? scheme.primary : Colors.transparent,
              width: isHighlighted ? 2 : 1,
            ),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
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
                    final isHighlightedCompletion =
                        completion.id == highlightedCompletionId;
                    return InputChip(
                      avatar: Icon(
                        isHighlightedCompletion
                            ? Icons.check_circle_outline
                            : Icons.calendar_month_outlined,
                        size: 18,
                      ),
                      backgroundColor: isHighlightedCompletion
                          ? scheme.primaryContainer
                          : null,
                      side: isHighlightedCompletion
                          ? BorderSide(color: scheme.primary)
                          : null,
                      label: Text(
                        dates.formatDateLabel(completion.completedAt),
                      ),
                      onPressed: () => onOpenCompletion(completion),
                      onDeleted: () => onDeleteCompletion(completion),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkedTargetBanner extends StatelessWidget {
  const _LinkedTargetBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.link),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '연결됨',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          Text(text),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
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
