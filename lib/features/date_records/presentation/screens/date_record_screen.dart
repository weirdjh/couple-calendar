import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../date_records/application/date_record_service.dart';
import '../../../calendar/domain/models/calendar_event.dart';
import '../../../calendar/domain/models/event_input.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../../../calendar/presentation/linked_item_presentation.dart';
import '../../../calendar/presentation/screens/event_detail_screen.dart';
import '../../../reviews/domain/models/review.dart';
import '../../../reviews/presentation/controllers/review_controller.dart';
import '../../../reviews/presentation/screens/review_screen.dart';
import '../../../todos/application/bucket_completion_service.dart';
import '../../../todos/domain/models/todo_item.dart';
import '../../../todos/presentation/controllers/todo_controller.dart';
import '../../../todos/presentation/screens/todo_screen.dart';
import '../../domain/models/date_record.dart';
import '../controllers/date_record_controller.dart';

class DateRecordScreen extends ConsumerStatefulWidget {
  const DateRecordScreen({this.highlightedRecordId, super.key});

  final String? highlightedRecordId;

  @override
  ConsumerState<DateRecordScreen> createState() => _DateRecordScreenState();
}

class _DateRecordScreenState extends ConsumerState<DateRecordScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dateRecordControllerProvider);
    final isHighlightingLink = widget.highlightedRecordId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('데이트 기록'),
        actions: [
          IconButton(
            tooltip: '데이트 기록 추가',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DateRecordEditScreen()),
            ),
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
            if (state.errorMessage != null) ...[
              _ErrorPanel(message: state.errorMessage!),
              const SizedBox(height: 12),
            ],
            if (state.records.isEmpty)
              _EmptyPanel(
                text: '데이트 기록이 아직 없어요.',
                actionLabel: '첫 데이트 기록 만들기',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DateRecordEditScreen(),
                  ),
                ),
              )
            else
              ...state.records.map((record) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DateRecordTile(
                    record: record,
                    isHighlighted: record.id == widget.highlightedRecordId,
                    onOpenRecord: () => _openRecordDetail(record.id),
                    onOpenEvent: record.linkedEventId == null
                        ? null
                        : () => _openLinkedCalendarEvent(record.linkedEventId!),
                    onOpenLinkedItem: _openLinkedRecordItem,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _openRecordDetail(String recordId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DateRecordDetailScreen(recordId)));
  }

  void _openLinkedCalendarEvent(String eventId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventId)),
    );
  }

  void _openLinkedRecordItem(LinkedItem item) {
    if (item.type == LinkedItemType.todo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TodoScreen(
            highlightedItemId: todoItemIdForLinkedItem(item),
            highlightedCompletionId: todoCompletionIdForLinkedItem(item),
          ),
        ),
      );
    }
    if (item.type == LinkedItemType.review) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReviewDetailScreen(item.targetId)),
      );
    }
  }
}

class DateRecordDetailScreen extends ConsumerWidget {
  const DateRecordDetailScreen(this.recordId, {super.key});

  final String? recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = recordId;
    final record = id == null
        ? null
        : ref.watch(dateRecordControllerProvider).recordById(id);

    if (record == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('데이트 기록을 찾을 수 없어요.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('데이트 상세'),
        actions: [
          IconButton(
            tooltip: '편집',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DateRecordEditScreen(recordId: record.id),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '삭제',
            onPressed: () => _deleteRecord(context, ref, record),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _DateRecordHeader(record: record),
            const SizedBox(height: 12),
            _DetailSection(
              icon: Icons.notes_outlined,
              title: '메모',
              child: Text(record.memo.isEmpty ? '메모가 없어요.' : record.memo),
            ),
            const SizedBox(height: 12),
            _DetailSection(
              icon: Icons.photo_outlined,
              title: '사진',
              child: record.photoLabels.isEmpty
                  ? const Text('아직 사진이 없어요.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: record.photoLabels
                          .map(
                            (label) => Chip(
                              avatar: const Icon(Icons.photo_outlined),
                              label: Text(label),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 12),
            _DetailSection(
              icon: Icons.link,
              title: '연결',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.linkedItems.isEmpty)
                    const Text('없음')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: record.linkedItems.map((item) {
                        return InputChip(
                          avatar: Icon(linkedItemTypeIcon(item.type), size: 18),
                          label: Text(item.title),
                          onPressed: () =>
                              _openLinkedRecordItem(context, ref, record, item),
                          onDeleted: () =>
                              _unlinkRecordItem(context, ref, record, item),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _addReview(context, ref, record),
                        icon: const Icon(Icons.star_border),
                        label: const Text('리뷰'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _addBucketItem(context, ref, record),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('버킷'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    DateRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제?'),
        content: Text(record.title),
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
    await ref.read(dateRecordServiceProvider).deleteRecord(record);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _unlinkRecordItem(
    BuildContext context,
    WidgetRef ref,
    DateRecord record,
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
    if (confirmed != true) {
      return;
    }
    await ref
        .read(dateRecordControllerProvider.notifier)
        .removeLinkedItem(recordId: record.id, linkedItem: item);
    if (item.type == LinkedItemType.review) {
      await ref
          .read(reviewControllerProvider.notifier)
          .unlinkDateRecord(item.targetId);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('해제됨')));
    }
  }

  Future<void> _addBucketItem(
    BuildContext context,
    WidgetRef ref,
    DateRecord record,
  ) async {
    final selection = await showModalBottomSheet<_TodoSelection>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _TodoPickerSheet(todoState: ref.read(todoControllerProvider)),
    );
    if (selection == null) {
      return;
    }

    final completion = await ref
        .read(todoControllerProvider.notifier)
        .addCompletion(
          itemId: selection.item.id,
          completedAt: record.date,
          calendarEventId: record.linkedEventId ?? '',
        );
    if (completion == null) {
      return;
    }
    await ref
        .read(dateRecordControllerProvider.notifier)
        .addLinkedItem(
          recordId: record.id,
          linkedItem: linkedItemForTodoCompletion(
            item: selection.item,
            completion: completion,
            category: selection.category,
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결됨')));
    }
  }

  Future<void> _linkReviewToRecord(
    WidgetRef ref,
    DateRecord record,
    Review review,
  ) async {
    await ref
        .read(reviewControllerProvider.notifier)
        .linkDateRecord(reviewId: review.id, dateRecordId: record.id);
    await ref
        .read(dateRecordControllerProvider.notifier)
        .addLinkedItem(
          recordId: record.id,
          linkedItem: linkedItemForReview(review),
        );
  }

  void _openLinkedRecordItem(
    BuildContext context,
    WidgetRef ref,
    DateRecord record,
    LinkedItem item,
  ) {
    if (item.type == LinkedItemType.todo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TodoScreen(
            highlightedItemId: todoItemIdForLinkedItem(item),
            highlightedCompletionId: todoCompletionIdForLinkedItem(item),
          ),
        ),
      );
    }
    if (item.type == LinkedItemType.review) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReviewDetailScreen(item.targetId)),
      );
    }
  }

  Future<void> _addReview(
    BuildContext context,
    WidgetRef ref,
    DateRecord record,
  ) async {
    final review = await Navigator.of(context).push<Review>(
      MaterialPageRoute(
        builder: (_) => ReviewEditScreen(dateRecordId: record.id),
      ),
    );
    if (review == null) {
      return;
    }
    await _linkReviewToRecord(ref, record, review);
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
                children: todoState.categories.map((category) {
                  final items = todoState.itemsForCategory(category.id);
                  return ExpansionTile(
                    initiallyExpanded: true,
                    leading: Text(category.emoji),
                    title: Text(category.title),
                    children: items.map((item) {
                      return ListTile(
                        title: Text(item.title),
                        subtitle: item.note.isEmpty ? null : Text(item.note),
                        onTap: () => Navigator.of(
                          context,
                        ).pop(_TodoSelection(category: category, item: item)),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateRecordEditScreen extends ConsumerStatefulWidget {
  const DateRecordEditScreen({this.recordId, this.initialDate, super.key});

  final String? recordId;
  final DateTime? initialDate;

  @override
  ConsumerState<DateRecordEditScreen> createState() =>
      _DateRecordEditScreenState();
}

class _DateRecordEditScreenState extends ConsumerState<DateRecordEditScreen> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _placeNameController = TextEditingController();
  final _placeAddressController = TextEditingController();
  final _photoController = TextEditingController();
  final _photoLabels = <String>[];
  DateTime? _date;
  var _didSeed = false;

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _placeNameController.dispose();
    _placeAddressController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.recordId == null
        ? null
        : ref.watch(dateRecordControllerProvider).recordById(widget.recordId!);
    if (widget.recordId != null && record == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('데이트 기록을 찾을 수 없어요.')),
      );
    }
    _seed(record);
    final isEditing = record != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '데이트 편집' : '데이트 기록 추가')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _DateRecordForm(
              titleController: _titleController,
              memoController: _memoController,
              placeNameController: _placeNameController,
              placeAddressController: _placeAddressController,
              photoController: _photoController,
              photoLabels: _photoLabels,
              date: _date!,
              onPickDate: _pickDate,
              onAddPhoto: _addPhoto,
              onRemovePhoto: (label) {
                setState(() => _photoLabels.remove(label));
              },
              linkedEventId: record?.linkedEventId,
              onDisconnectCalendar:
                  record == null || record.linkedEventId == null
                  ? null
                  : () => _disconnectCalendarEvent(record),
              onSave: () => _save(record),
              actionLabel: isEditing ? '변경 저장' : '기록 저장',
            ),
          ],
        ),
      ),
    );
  }

  void _seed(DateRecord? record) {
    if (_didSeed) {
      return;
    }
    _didSeed = true;
    if (record == null) {
      _date = dates.dateOnly(widget.initialDate ?? DateTime.now());
      return;
    }
    _titleController.text = record.title;
    _memoController.text = record.memo;
    _placeNameController.text = record.place?.name ?? '';
    _placeAddressController.text = record.place?.address ?? '';
    _photoLabels
      ..clear()
      ..addAll(record.photoLabels);
    _date = record.date;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) {
      return;
    }
    setState(() => _date = dates.dateOnly(picked));
  }

  void _addPhoto() {
    final label = _photoController.text.trim();
    if (label.isEmpty) {
      return;
    }
    setState(() {
      _photoLabels.add(label);
      _photoController.clear();
    });
  }

  Future<void> _disconnectCalendarEvent(DateRecord record) async {
    await ref.read(dateRecordServiceProvider).unlinkRecordFromEvent(record);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('해제됨')));
    }
  }

  Future<void> _save(DateRecord? record) async {
    if (record == null) {
      final createdRecord = await _createRecord();
      if (createdRecord == null) {
        return;
      }
    } else {
      if (record.linkedEventId != null) {
        await ref
            .read(calendarControllerProvider.notifier)
            .selectDate(record.date);
      }
      final updatedRecord = await ref
          .read(dateRecordControllerProvider.notifier)
          .updateRecord(
            recordId: record.id,
            title: _titleController.text,
            date: _date!,
            memo: _memoController.text,
            placeName: _placeNameController.text,
            placeAddress: _placeAddressController.text,
            photoLabels: _photoLabels,
          );
      if (updatedRecord == null) {
        return;
      }
      await _ensureCalendarEvent(updatedRecord);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<DateRecord?> _createRecord() async {
    final provisionalRecord = await ref
        .read(dateRecordControllerProvider.notifier)
        .addRecord(
          title: _titleController.text,
          date: _date!,
          memo: _memoController.text,
          placeName: _placeNameController.text,
          placeAddress: _placeAddressController.text,
          photoLabels: _photoLabels,
        );
    if (provisionalRecord == null) {
      return null;
    }

    await _ensureCalendarEvent(provisionalRecord);
    return provisionalRecord;
  }

  Future<void> _ensureCalendarEvent(DateRecord record) async {
    if (record.linkedEventId != null) {
      await _syncLinkedCalendarEvent(ref, record);
      return;
    }
    final event = await ref
        .read(calendarControllerProvider.notifier)
        .createEvent(
          EventInput(
            title: record.title,
            startAt: record.date,
            endAt: record.date.add(const Duration(days: 1)),
            isAllDay: true,
            kind: CalendarEventKind.date,
            memo: record.memo,
            colorValue: 0xFFE77AA2,
            ownership: EventOwnership.shared,
            linkedItems: [_linkedItemForRecord(record)],
          ),
        );
    if (event == null) {
      return;
    }
    await ref
        .read(dateRecordControllerProvider.notifier)
        .linkCalendarEvent(recordId: record.id, eventId: event.id);
  }

  Future<void> _syncLinkedCalendarEvent(
    WidgetRef ref,
    DateRecord record,
  ) async {
    final eventId = record.linkedEventId;
    if (eventId == null) {
      return;
    }
    final event = ref
        .read(calendarControllerProvider)
        .events
        .where((item) => item.id == eventId)
        .firstOrNull;
    if (event == null) {
      return;
    }

    final dateRecordLink = _linkedItemForRecord(
      record,
      emoji: record.linkedItems.firstOrNull?.emoji,
    );
    final linkedItems = [
      for (final item in event.linkedItems)
        if (item.type == LinkedItemType.dateRecord &&
            dateRecordIdForLinkedItem(item) == record.id)
          dateRecordLink
        else
          item,
    ];

    await ref
        .read(calendarControllerProvider.notifier)
        .updateEventFromInput(
          eventId: event.id,
          input: EventInput(
            title: record.title,
            startAt: record.date,
            endAt: record.date.add(const Duration(days: 1)),
            isAllDay: true,
            kind: CalendarEventKind.date,
            memo: record.memo,
            colorValue: event.colorValue,
            ownership: event.ownership,
            reminderOffsetMinutes: event.reminders.firstOrNull?.offsetMinutes,
            linkedItems: linkedItems,
          ),
        );
  }
}

LinkedItem _linkedItemForRecord(DateRecord record, {String? emoji}) {
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

class _DateRecordForm extends StatelessWidget {
  const _DateRecordForm({
    required this.titleController,
    required this.memoController,
    required this.placeNameController,
    required this.placeAddressController,
    required this.photoController,
    required this.photoLabels,
    required this.date,
    required this.onPickDate,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.linkedEventId,
    required this.onDisconnectCalendar,
    required this.onSave,
    required this.actionLabel,
  });

  final TextEditingController titleController;
  final TextEditingController memoController;
  final TextEditingController placeNameController;
  final TextEditingController placeAddressController;
  final TextEditingController photoController;
  final List<String> photoLabels;
  final DateTime date;
  final VoidCallback onPickDate;
  final VoidCallback onAddPhoto;
  final ValueChanged<String> onRemovePhoto;
  final String? linkedEventId;
  final VoidCallback? onDisconnectCalendar;
  final VoidCallback onSave;
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
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: '데이트 제목',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(calendarEventLinkIcon),
            title: const Text('날짜'),
            subtitle: Text(dates.formatDateLabel(date)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: onPickDate,
          ),
          if (linkedEventId != null) ...[
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(calendarEventLinkIcon),
              title: const Text('일정'),
              subtitle: const Text('연결됨'),
              trailing: IconButton(
                tooltip: '해제',
                onPressed: onDisconnectCalendar,
                icon: const Icon(Icons.link_off),
              ),
            ),
          ],
          TextField(
            controller: placeNameController,
            decoration: const InputDecoration(
              labelText: '장소 이름',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: placeAddressController,
            decoration: const InputDecoration(
              labelText: '주소 또는 설명',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: memoController,
            decoration: const InputDecoration(
              labelText: '메모',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: photoController,
                  decoration: const InputDecoration(
                    labelText: '사진 메모 또는 파일명',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '사진 추가',
                onPressed: onAddPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
              ),
            ],
          ),
          if (photoLabels.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: photoLabels.map((label) {
                return InputChip(
                  avatar: const Icon(Icons.photo_outlined, size: 18),
                  label: Text(label),
                  onDeleted: () => onRemovePhoto(label),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.check),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRecordTile extends StatelessWidget {
  const _DateRecordTile({
    required this.record,
    required this.isHighlighted,
    required this.onOpenRecord,
    required this.onOpenEvent,
    required this.onOpenLinkedItem,
  });

  final DateRecord record;
  final bool isHighlighted;
  final VoidCallback onOpenRecord;
  final VoidCallback? onOpenEvent;
  final ValueChanged<LinkedItem> onOpenLinkedItem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final linkedToCalendar = record.linkedEventId != null;
    return ListTile(
      tileColor: isHighlighted
          ? scheme.primaryContainer.withValues(alpha: 0.60)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isHighlighted ? scheme.primary : scheme.outlineVariant,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      leading: const Icon(Icons.place_outlined),
      onTap: onOpenRecord,
      title: Text(
        record.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              dates.formatDateLabel(record.date),
              if (record.place != null) record.place!.name,
              if (record.photoLabels.isNotEmpty)
                '사진 ${record.photoLabels.length}',
            ].join(' · '),
          ),
          if (linkedToCalendar) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _LinkedStatusIcon(
                  icon: calendarEventLinkIcon,
                  tooltip: '일정 보기',
                  color: scheme.primary,
                  onPressed: onOpenEvent,
                ),
                if (record.photoLabels.isNotEmpty)
                  _LinkedStatusIcon(
                    icon: Icons.photo_outlined,
                    tooltip: '사진',
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
          if (record.linkedItems.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: record.linkedItems.map((item) {
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(linkedItemTypeIcon(item.type), size: 18),
                  label: Text(item.title),
                  onPressed: () => onOpenLinkedItem(item),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkedStatusIcon extends StatelessWidget {
  const _LinkedStatusIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Icon(this.icon, size: 16, color: color),
    );
    return Tooltip(
      message: tooltip,
      child: onPressed == null
          ? icon
          : InkResponse(onTap: onPressed, radius: 18, child: icon),
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

class _DateRecordHeader extends StatelessWidget {
  const _DateRecordHeader({required this.record});

  final DateRecord record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            avatar: Icon(
              record.linkedEventId == null
                  ? dateRecordLinkIcon
                  : calendarEventLinkIcon,
              size: 18,
            ),
            label: Text(_compactDateLabel(record.date)),
            backgroundColor: scheme.surface,
          ),
          const SizedBox(height: 10),
          Text(
            record.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (record.place != null) ...[
            const SizedBox(height: 8),
            Text(
              [
                record.place!.name,
                if (record.place!.address != null) record.place!.address!,
              ].join(' · '),
            ),
          ],
        ],
      ),
    );
  }
}

String _compactDateLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month.$day';
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
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

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
