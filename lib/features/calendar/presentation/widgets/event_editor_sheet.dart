import 'package:flutter/material.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../domain/models/calendar_event.dart';
import '../../domain/models/event_input.dart';
import '../linked_item_presentation.dart';

Future<void> showEventEditorSheet({
  required BuildContext context,
  required DateTime initialDate,
  required Future<void> Function(EventInput input) onSave,
  String sheetTitle = '새 일정',
  String initialTitle = '',
  String initialMemo = '',
  bool initialIsAllDay = false,
  int initialColorValue = 0xFF4D7C8A,
  int? initialDurationHours,
  int? initialReminderOffsetMinutes = 60,
  List<LinkedItem> initialLinkedItems = const [],
  List<LinkedItem> previewLinkedItems = const [],
  Future<LinkedItem?> Function(BuildContext context)? onAddLinkedItem,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return EventEditorSheet(
        initialDate: initialDate,
        sheetTitle: sheetTitle,
        initialTitle: initialTitle,
        initialMemo: initialMemo,
        initialIsAllDay: initialIsAllDay,
        initialColorValue: initialColorValue,
        initialDurationHours: initialDurationHours,
        initialReminderOffsetMinutes: initialReminderOffsetMinutes,
        initialLinkedItems: initialLinkedItems,
        previewLinkedItems: previewLinkedItems,
        onAddLinkedItem: onAddLinkedItem,
        onSave: onSave,
      );
    },
  );
}

class EventEditorSheet extends StatefulWidget {
  const EventEditorSheet({
    required this.initialDate,
    required this.onSave,
    this.sheetTitle = '새 일정',
    this.initialTitle = '',
    this.initialMemo = '',
    this.initialIsAllDay = false,
    this.initialColorValue = 0xFF4D7C8A,
    this.initialDurationHours,
    this.initialReminderOffsetMinutes = 60,
    this.initialLinkedItems = const [],
    this.previewLinkedItems = const [],
    this.onAddLinkedItem,
    super.key,
  });

  final DateTime initialDate;
  final Future<void> Function(EventInput input) onSave;
  final String sheetTitle;
  final String initialTitle;
  final String initialMemo;
  final bool initialIsAllDay;
  final int initialColorValue;
  final int? initialDurationHours;
  final int? initialReminderOffsetMinutes;
  final List<LinkedItem> initialLinkedItems;
  final List<LinkedItem> previewLinkedItems;
  final Future<LinkedItem?> Function(BuildContext context)? onAddLinkedItem;

  @override
  State<EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<EventEditorSheet> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _linkedItems = <LinkedItem>[];
  late var _eventDate = dates.dateOnly(widget.initialDate);
  late var _isAllDay = widget.initialIsAllDay;
  late var _startHour = widget.initialDate.hour == 0
      ? 19
      : widget.initialDate.hour;
  late var _durationHours = widget.initialDurationHours ?? 2;
  late int? _reminderOffsetMinutes = widget.initialReminderOffsetMinutes;
  late var _colorValue = widget.initialColorValue;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle;
    _memoController.text = widget.initialMemo;
    _linkedItems.addAll(widget.initialLinkedItems);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.sheetTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('날짜'),
                subtitle: Text(dates.formatDateLabel(_eventDate)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('하루 종일'),
                value: _isAllDay,
                onChanged: (value) => setState(() => _isAllDay = value),
              ),
              if (!_isAllDay) ...[
                Row(
                  children: [
                    Expanded(
                      child: _NumberPickerField(
                        label: '시작',
                        value: _startHour,
                        min: 0,
                        max: 23,
                        suffix: '시',
                        onChanged: (value) =>
                            setState(() => _startHour = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NumberPickerField(
                        label: '길이',
                        value: _durationHours,
                        min: 1,
                        max: 12,
                        suffix: '시간',
                        onChanged: (value) =>
                            setState(() => _durationHours = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: '메모',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              Text('색상', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [0xFF4D7C8A, 0xFFC67C4E, 0xFF7C6A9E, 0xFF5D8C61].map((
                  value,
                ) {
                  final selected = value == _colorValue;
                  return ChoiceChip(
                    showCheckmark: false,
                    label: const SizedBox(width: 18, height: 18),
                    selected: selected,
                    avatar: CircleAvatar(backgroundColor: Color(value)),
                    onSelected: (_) => setState(() => _colorValue = value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int?>(
                initialValue: _reminderOffsetMinutes,
                decoration: const InputDecoration(
                  labelText: '알림',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('없음')),
                  DropdownMenuItem(value: 10, child: Text('10분 전')),
                  DropdownMenuItem(value: 60, child: Text('1시간 전')),
                  DropdownMenuItem(value: 1440, child: Text('하루 전')),
                ],
                onChanged: (value) =>
                    setState(() => _reminderOffsetMinutes = value),
              ),
              if (widget.previewLinkedItems.isNotEmpty ||
                  _linkedItems.isNotEmpty ||
                  widget.onAddLinkedItem != null) ...[
                const SizedBox(height: 14),
                Text('연결', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._linkedItems.map((item) {
                      return InputChip(
                        avatar: Text(linkedItemEmoji(item.type)),
                        label: Text(item.title),
                        onDeleted: () =>
                            setState(() => _linkedItems.remove(item)),
                      );
                    }),
                    ...widget.previewLinkedItems.map((item) {
                      return Chip(
                        avatar: Text(linkedItemEmoji(item.type)),
                        label: Text('${item.title} 예정'),
                      );
                    }),
                    if (widget.onAddLinkedItem != null)
                      ActionChip(
                        avatar: const Icon(Icons.add_link, size: 18),
                        label: const Text('버킷리스트 연결'),
                        onPressed: _addLinkedItem,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) {
      return;
    }
    setState(() => _eventDate = dates.dateOnly(picked));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목을 입력해 주세요.')));
      return;
    }

    setState(() => _isSaving = true);
    final start = _isAllDay
        ? _eventDate
        : DateTime(
            _eventDate.year,
            _eventDate.month,
            _eventDate.day,
            _startHour,
          );
    final end = _isAllDay
        ? start.add(const Duration(days: 1))
        : start.add(Duration(hours: _durationHours));

    await widget.onSave(
      EventInput(
        title: title,
        startAt: start,
        endAt: end,
        isAllDay: _isAllDay,
        memo: _memoController.text,
        colorValue: _colorValue,
        photoLabels: const [],
        reminderOffsetMinutes: _reminderOffsetMinutes,
        linkedItems: List.unmodifiable(_linkedItems),
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _addLinkedItem() async {
    final picker = widget.onAddLinkedItem;
    if (picker == null) {
      return;
    }
    final item = await picker(context);
    if (item == null) {
      return;
    }
    final alreadyLinked = _linkedItems.any(
      (linkedItem) =>
          linkedItem.type == item.type && linkedItem.targetId == item.targetId,
    );
    if (alreadyLinked) {
      return;
    }
    setState(() => _linkedItems.add(item));
  }
}

class _NumberPickerField extends StatelessWidget {
  const _NumberPickerField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '$label 줄이기',
            onPressed: value <= min ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$value$suffix',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: '$label 늘리기',
            onPressed: value >= max ? null : () => onChanged(value + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
