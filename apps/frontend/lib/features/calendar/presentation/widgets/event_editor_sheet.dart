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
  int initialColorValue = 0xFF4169E1,
  EventOwnership initialOwnership = EventOwnership.personal,
  DateTime? initialEndAt,
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
        initialOwnership: initialOwnership,
        initialEndAt: initialEndAt,
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
    this.initialColorValue = 0xFF4169E1,
    this.initialOwnership = EventOwnership.personal,
    this.initialEndAt,
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
  final EventOwnership initialOwnership;
  final DateTime? initialEndAt;
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
  late var _startDate = dates.dateOnly(widget.initialDate);
  late var _isAllDay = widget.initialIsAllDay;
  late var _startTime = _initialStartTime();
  late var _endDate = _initialEndDate();
  late var _endTime = _initialEndTime();
  late int? _reminderOffsetMinutes = widget.initialReminderOffsetMinutes;
  late var _colorValue = widget.initialColorValue;
  late var _ownership = widget.initialOwnership;
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
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FractionallySizedBox(
          heightFactor: 0.94,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.sheetTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        autofocus: widget.initialTitle.isEmpty,
                        style: Theme.of(context).textTheme.titleLarge,
                        decoration: const InputDecoration(
                          hintText: '일정 제목',
                          prefixIcon: Icon(Icons.edit_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _EventEditorSection(
                        icon: Icons.schedule_outlined,
                        title: '언제',
                        child: Column(
                          children: [
                            _DateTimeRow(
                              label: '시작',
                              date: _startDate,
                              time: _startTime,
                              showTime: !_isAllDay,
                              onPickDate: () => _pickDate(isStart: true),
                              onPickTime: () => _pickTime(isStart: true),
                            ),
                            const SizedBox(height: 8),
                            _DateTimeRow(
                              label: '종료',
                              date: _endDate,
                              time: _endTime,
                              showTime: !_isAllDay,
                              onPickDate: () => _pickDate(isStart: false),
                              onPickTime: () => _pickTime(isStart: false),
                            ),
                            const SizedBox(height: 4),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('하루 종일'),
                              subtitle: const Text('시간 없이 날짜만 표시해요.'),
                              value: _isAllDay,
                              onChanged: (value) =>
                                  setState(() => _isAllDay = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EventEditorSection(
                        icon: Icons.people_outline,
                        title: '누구의 일정인가요?',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SegmentedButton<EventOwnership>(
                              expandedInsets: EdgeInsets.zero,
                              segments: const [
                                ButtonSegment(
                                  value: EventOwnership.personal,
                                  icon: Icon(Icons.person_outline),
                                  label: Text('내 일정'),
                                ),
                                ButtonSegment(
                                  value: EventOwnership.shared,
                                  icon: Icon(Icons.favorite_outline),
                                  label: Text('우리 일정'),
                                ),
                              ],
                              selected: {_ownership},
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _ownership = selection.single;
                                  _colorValue =
                                      _ownership == EventOwnership.shared
                                      ? 0xFF7C6EE6
                                      : 0xFF4169E1;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '캘린더 색상',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children:
                                  [
                                    0xFF4169E1,
                                    0xFF7C6EE6,
                                    0xFFE85D75,
                                    0xFF16A085,
                                  ].map((value) {
                                    final selected = value == _colorValue;
                                    return ChoiceChip(
                                      showCheckmark: selected,
                                      label: const SizedBox(
                                        width: 18,
                                        height: 18,
                                      ),
                                      selected: selected,
                                      avatar: CircleAvatar(
                                        backgroundColor: Color(value),
                                      ),
                                      onSelected: (_) =>
                                          setState(() => _colorValue = value),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EventEditorSection(
                        icon: Icons.notifications_none,
                        title: '알림',
                        child: DropdownButtonFormField<int?>(
                          initialValue: _reminderOffsetMinutes,
                          decoration: const InputDecoration(hintText: '알림 시점'),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('알림 없음')),
                            DropdownMenuItem(value: 10, child: Text('10분 전')),
                            DropdownMenuItem(value: 60, child: Text('1시간 전')),
                            DropdownMenuItem(value: 1440, child: Text('하루 전')),
                          ],
                          onChanged: (value) =>
                              setState(() => _reminderOffsetMinutes = value),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EventEditorSection(
                        icon: Icons.notes_outlined,
                        title: '메모',
                        child: TextField(
                          controller: _memoController,
                          decoration: const InputDecoration(
                            hintText: '일정에 필요한 내용을 남겨보세요.',
                          ),
                          minLines: 3,
                          maxLines: 6,
                        ),
                      ),
                      if (widget.previewLinkedItems.isNotEmpty ||
                          _linkedItems.isNotEmpty ||
                          widget.onAddLinkedItem != null) ...[
                        const SizedBox(height: 14),
                        _EventEditorSection(
                          icon: Icons.link,
                          title: '연결된 기록',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._linkedItems.map((item) {
                                return InputChip(
                                  avatar: Icon(
                                    linkedItemTypeIcon(item.type),
                                    size: 18,
                                  ),
                                  label: Text(item.title),
                                  onDeleted: () =>
                                      setState(() => _linkedItems.remove(item)),
                                );
                              }),
                              ...widget.previewLinkedItems.map((item) {
                                return Chip(
                                  avatar: Icon(
                                    linkedItemTypeIcon(item.type),
                                    size: 18,
                                  ),
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
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: SizedBox(
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
                    label: const Text('일정 저장'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _initialEndDate() {
    final endAt = widget.initialEndAt;
    if (endAt == null) {
      return dates.dateOnly(_defaultEndAt());
    }
    if (widget.initialIsAllDay) {
      return dates.dateOnly(endAt).subtract(const Duration(days: 1));
    }
    return dates.dateOnly(endAt);
  }

  TimeOfDay _initialStartTime() {
    if (widget.initialDate.hour == 0 && widget.initialDate.minute == 0) {
      return const TimeOfDay(hour: 19, minute: 0);
    }
    return TimeOfDay.fromDateTime(widget.initialDate);
  }

  TimeOfDay _initialEndTime() {
    final endAt = widget.initialEndAt;
    if (endAt != null) {
      return TimeOfDay.fromDateTime(endAt);
    }
    return TimeOfDay.fromDateTime(_defaultEndAt());
  }

  DateTime _defaultEndAt() {
    final start = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    return start.add(Duration(hours: widget.initialDurationHours ?? 2));
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      final pickedDate = dates.dateOnly(picked);
      if (isStart) {
        final delta = pickedDate.difference(_startDate);
        _startDate = pickedDate;
        _endDate = _endDate.add(delta);
      } else {
        _endDate = pickedDate;
      }
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
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
        ? _startDate
        : DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _startTime.hour,
            _startTime.minute,
          );
    final end = _isAllDay
        ? _endDate.add(const Duration(days: 1))
        : DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            _endTime.hour,
            _endTime.minute,
          );

    if (!end.isAfter(start)) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종료 일시는 시작 일시보다 뒤여야 해요.')));
      return;
    }

    await widget.onSave(
      EventInput(
        title: title,
        startAt: start,
        endAt: end,
        isAllDay: _isAllDay,
        memo: _memoController.text,
        colorValue: _colorValue,
        ownership: _ownership,
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

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.label,
    required this.date,
    required this.time,
    required this.showTime,
    required this.onPickDate,
    required this.onPickTime,
  });

  final String label;
  final DateTime date;
  final TimeOfDay time;
  final bool showTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStart = label == '시작';
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onPickDate,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isStart ? Icons.play_arrow_rounded : Icons.stop_rounded,
                        size: 18,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(date),
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showTime) ...[
            Container(
              width: 1,
              height: 38,
              color: theme.colorScheme.outlineVariant,
            ),
            InkWell(
              onTap: onPickTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 17,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(_formatTime(time), style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${value.month}월 ${value.day}일 ${weekdays[value.weekday - 1]}요일';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _EventEditorSection extends StatelessWidget {
  const _EventEditorSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
