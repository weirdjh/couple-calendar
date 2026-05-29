import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/app_shell.dart';
import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../../domain/models/anniversary.dart';
import '../../domain/services/anniversary_calculator.dart';
import '../controllers/anniversary_controller.dart';

class AnniversaryScreen extends ConsumerWidget {
  const AnniversaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(anniversaryControllerProvider);
    final anniversariesWithNext =
        state.anniversaries.map((anniversary) {
          final next = nextAnniversaryOccurrence(
            anniversary: anniversary,
            fromDate: DateTime.now(),
          );
          return _AnniversaryListItem(anniversary: anniversary, next: next);
        }).toList()..sort((left, right) {
          final leftDate = left.next?.date;
          final rightDate = right.next?.date;
          if (leftDate == null && rightDate == null) {
            return left.anniversary.title.compareTo(right.anniversary.title);
          }
          if (leftDate == null) {
            return 1;
          }
          if (rightDate == null) {
            return -1;
          }
          return leftDate.compareTo(rightDate);
        });

    return Scaffold(
      appBar: AppBar(
        title: const Text('기념일'),
        actions: [
          IconButton(
            tooltip: '기념일 추가',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnniversaryEditScreen()),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (state.errorMessage != null) ...[
              _ErrorPanel(message: state.errorMessage!),
              const SizedBox(height: 12),
            ],
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.anniversaries.isEmpty)
              _EmptyPanel(
                text: '등록된 기념일이 없어요.',
                actionLabel: '기념일 추가',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AnniversaryEditScreen(),
                  ),
                ),
              )
            else ...[
              _NextAnniversaryPanel(
                item: anniversariesWithNext.firstWhere(
                  (item) => item.next != null,
                  orElse: () => anniversariesWithNext.first,
                ),
                onOpenCalendar: anniversariesWithNext.first.next == null
                    ? null
                    : () => _openCalendar(
                        context,
                        ref,
                        anniversariesWithNext.first.next!.date,
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                '전체 기념일',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...anniversariesWithNext.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AnniversaryTile(
                    anniversary: item.anniversary,
                    next: item.next,
                    onOpenCalendar: item.next == null
                        ? null
                        : () => _openCalendar(context, ref, item.next!.date),
                    onEdit: () => _openEditScreen(context, item.anniversary),
                    onDelete: () =>
                        _confirmDelete(context, ref, item.anniversary),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openCalendar(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) async {
    await ref.read(calendarControllerProvider.notifier).selectDate(date);
    ref.read(selectedAppTabProvider.notifier).selectCalendar();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _openEditScreen(BuildContext context, Anniversary anniversary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnniversaryEditScreen(anniversary: anniversary),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Anniversary anniversary,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('기념일 삭제'),
          content: Text('${anniversary.title} 기념일을 삭제할까요?'),
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
        .read(anniversaryControllerProvider.notifier)
        .deleteAnniversary(anniversary.id);
  }
}

class AnniversaryEditScreen extends ConsumerStatefulWidget {
  const AnniversaryEditScreen({super.key, this.anniversary});

  final Anniversary? anniversary;

  @override
  ConsumerState<AnniversaryEditScreen> createState() =>
      _AnniversaryEditScreenState();
}

class _AnniversaryEditScreenState extends ConsumerState<AnniversaryEditScreen> {
  final _titleController = TextEditingController();
  var _baseDate = dates.dateOnly(DateTime.now());
  var _calendarType = AnniversaryCalendarType.solar;
  var _repeatRule = AnniversaryRepeatRule.every100DaysAndYearly;

  bool get _isEditing => widget.anniversary != null;

  @override
  void initState() {
    super.initState();
    final anniversary = widget.anniversary;
    if (anniversary == null) {
      return;
    }
    _titleController.text = anniversary.title;
    _baseDate = anniversary.baseDate;
    _calendarType = anniversary.calendarType;
    _repeatRule = anniversary.repeatRule;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anniversaryState = ref.watch(anniversaryControllerProvider);
    final errorMessage = anniversaryState.errorMessage;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '기념일 수정' : '기념일 추가')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AnniversaryForm(
              titleController: _titleController,
              baseDate: _baseDate,
              calendarType: _calendarType,
              repeatRule: _repeatRule,
              onCalendarTypeChanged: _changeCalendarType,
              onRepeatRuleChanged: (rule) => setState(() => _repeatRule = rule),
              onPickDate: _pickDate,
              onSave: _save,
              saveLabel: _isEditing ? '기념일 수정' : '기념일 저장',
              isSaving: anniversaryState.isSaving,
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

  void _changeCalendarType(AnniversaryCalendarType calendarType) {
    setState(() => _calendarType = calendarType);
  }

  Future<void> _pickDate() async {
    if (_calendarType == AnniversaryCalendarType.lunar) {
      final picked = await showDialog<DateTime>(
        context: context,
        builder: (_) => _LunarDateInputDialog(initialDate: _baseDate),
      );
      if (picked == null) {
        return;
      }
      setState(() => _baseDate = dates.dateOnly(picked));
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _baseDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() => _baseDate = dates.dateOnly(picked));
  }

  Future<void> _save() async {
    final controller = ref.read(anniversaryControllerProvider.notifier);
    final source = widget.anniversary;
    final anniversary = source == null
        ? await controller.addAnniversary(
            title: _titleController.text,
            baseDate: _baseDate,
            repeatRule: _repeatRule,
            calendarType: _calendarType,
          )
        : await controller.updateAnniversary(
            anniversaryId: source.id,
            title: _titleController.text,
            baseDate: _baseDate,
            repeatRule: _repeatRule,
            calendarType: _calendarType,
          );
    if (anniversary == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _LunarDateInputDialog extends StatefulWidget {
  const _LunarDateInputDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_LunarDateInputDialog> createState() => _LunarDateInputDialogState();
}

class _LunarDateInputDialogState extends State<_LunarDateInputDialog> {
  late final TextEditingController _yearController;
  late final TextEditingController _monthController;
  late final TextEditingController _dayController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _yearController = TextEditingController(
      text: widget.initialDate.year.toString(),
    );
    _monthController = TextEditingController(
      text: widget.initialDate.month.toString(),
    );
    _dayController = TextEditingController(
      text: widget.initialDate.day.toString(),
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('음력 날짜 입력'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _NumberField(controller: _yearController, label: '년'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(controller: _monthController, label: '월'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(controller: _dayController, label: '일'),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('선택')),
      ],
    );
  }

  void _submit() {
    final year = int.tryParse(_yearController.text.trim());
    final month = int.tryParse(_monthController.text.trim());
    final day = int.tryParse(_dayController.text.trim());
    if (year == null || month == null || day == null) {
      setState(() => _errorMessage = '연, 월, 일을 숫자로 입력해 주세요.');
      return;
    }
    if (year < 1900 || year > 2049) {
      setState(() => _errorMessage = '음력 날짜는 1900년부터 2049년까지 지원해요.');
      return;
    }
    if (month < 1 || month > 12 || day < 1 || day > 30) {
      setState(() => _errorMessage = '올바른 음력 월/일을 입력해 주세요.');
      return;
    }
    Navigator.of(context).pop(DateTime(year, month, day));
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _AnniversaryForm extends StatelessWidget {
  const _AnniversaryForm({
    required this.titleController,
    required this.baseDate,
    required this.calendarType,
    required this.repeatRule,
    required this.onCalendarTypeChanged,
    required this.onRepeatRuleChanged,
    required this.onPickDate,
    required this.onSave,
    required this.saveLabel,
    required this.isSaving,
  });

  final TextEditingController titleController;
  final DateTime baseDate;
  final AnniversaryCalendarType calendarType;
  final AnniversaryRepeatRule repeatRule;
  final ValueChanged<AnniversaryCalendarType> onCalendarTypeChanged;
  final ValueChanged<AnniversaryRepeatRule> onRepeatRuleChanged;
  final VoidCallback onPickDate;
  final Future<void> Function() onSave;
  final String saveLabel;
  final bool isSaving;

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
          _FormLabel('이름'),
          const SizedBox(height: 8),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: '예: 처음 만난 날, 결혼기념일, 엄마 생신',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _FormLabel('달력 기준'),
          const SizedBox(height: 8),
          SegmentedButton<AnniversaryCalendarType>(
            segments: AnniversaryCalendarType.values.map((candidate) {
              return ButtonSegment(
                value: candidate,
                label: Text(anniversaryCalendarTypeLabel(candidate)),
              );
            }).toList(),
            selected: {calendarType},
            onSelectionChanged: (selection) =>
                onCalendarTypeChanged(selection.single),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(
              calendarType == AnniversaryCalendarType.lunar
                  ? '음력 기준 날짜'
                  : '기준 날짜',
            ),
            subtitle: Text(_inputDateLabel(baseDate, calendarType)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: onPickDate,
          ),
          const SizedBox(height: 8),
          _FormLabel('기념 조건'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AnniversaryRepeatRule.values.map((candidate) {
              return ChoiceChip(
                selected: candidate == repeatRule,
                label: Text(anniversaryRepeatRuleLabel(candidate)),
                onSelected: (_) => onRepeatRuleChanged(candidate),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(isSaving ? '저장 중' : saveLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnniversaryTile extends StatelessWidget {
  const _AnniversaryTile({
    required this.anniversary,
    required this.next,
    required this.onOpenCalendar,
    required this.onEdit,
    required this.onDelete,
  });

  final Anniversary anniversary;
  final AnniversaryOccurrence? next;
  final VoidCallback? onOpenCalendar;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final nextOccurrence = next;
    final daysLeft = nextOccurrence?.date
        .difference(dates.dateOnly(DateTime.now()))
        .inDays;
    return ListTile(
      onTap: onOpenCalendar,
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
        child: const Icon(Icons.celebration_outlined),
      ),
      title: Text(
        anniversary.title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        [
          _baseDateLabel(
            anniversary.baseDate,
            anniversary.calendarType,
            anniversary.isLeapMonth,
          ),
          anniversaryRepeatRuleLabel(anniversary.repeatRule),
          if (nextOccurrence != null)
            '다음 ${nextOccurrence.label}: ${dates.formatDateLabel(nextOccurrence.date)}',
          if (daysLeft != null) daysLeft == 0 ? '오늘' : '$daysLeft일 남음',
        ].join(' · '),
      ),
      trailing: PopupMenuButton<_AnniversaryAction>(
        tooltip: '기념일 메뉴',
        onSelected: (action) {
          switch (action) {
            case _AnniversaryAction.openCalendar:
              onOpenCalendar?.call();
            case _AnniversaryAction.edit:
              onEdit();
            case _AnniversaryAction.delete:
              onDelete();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _AnniversaryAction.openCalendar,
            enabled: onOpenCalendar != null,
            child: const Text('캘린더에서 보기'),
          ),
          const PopupMenuItem(
            value: _AnniversaryAction.edit,
            child: Text('수정'),
          ),
          const PopupMenuItem(
            value: _AnniversaryAction.delete,
            child: Text('삭제'),
          ),
        ],
      ),
    );
  }
}

enum _AnniversaryAction { openCalendar, edit, delete }

class _NextAnniversaryPanel extends StatelessWidget {
  const _NextAnniversaryPanel({
    required this.item,
    required this.onOpenCalendar,
  });

  final _AnniversaryListItem item;
  final VoidCallback? onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final occurrence = item.next;
    final daysLeft = occurrence?.date
        .difference(dates.dateOnly(DateTime.now()))
        .inDays;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '다음 기념일',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            occurrence == null
                ? item.anniversary.title
                : '${item.anniversary.title} · ${occurrence.label}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            occurrence == null
                ? '다가오는 날짜를 계산할 수 없어요.'
                : [
                    dates.formatDateLabel(occurrence.date),
                    if (daysLeft != null)
                      daysLeft == 0 ? '오늘' : '$daysLeft일 남음',
                  ].join(' · '),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          if (onOpenCalendar != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onOpenCalendar,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('캘린더에서 보기'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnniversaryListItem {
  const _AnniversaryListItem({required this.anniversary, required this.next});

  final Anniversary anniversary;
  final AnniversaryOccurrence? next;
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
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

String anniversaryCalendarTypeLabel(AnniversaryCalendarType type) {
  return switch (type) {
    AnniversaryCalendarType.solar => '양력',
    AnniversaryCalendarType.lunar => '음력',
  };
}

String anniversaryRepeatRuleLabel(AnniversaryRepeatRule rule) {
  return switch (rule) {
    AnniversaryRepeatRule.every100Days => '100일마다',
    AnniversaryRepeatRule.yearly => '1년마다',
    AnniversaryRepeatRule.every100DaysAndYearly => '100일 + 1년마다',
  };
}

String _baseDateLabel(
  DateTime date,
  AnniversaryCalendarType calendarType,
  bool isLeapMonth,
) {
  final prefix = anniversaryCalendarTypeLabel(calendarType);
  final leapLabel = calendarType == AnniversaryCalendarType.lunar && isLeapMonth
      ? ' 윤달'
      : '';
  if (calendarType == AnniversaryCalendarType.lunar) {
    return '$prefix$leapLabel ${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
  return '$prefix ${dates.formatDateLabel(date)}';
}

String _inputDateLabel(DateTime date, AnniversaryCalendarType calendarType) {
  final label = dates.formatDateLabel(date);
  if (calendarType == AnniversaryCalendarType.lunar) {
    return '$label 음력 날짜로 저장해요.';
  }
  return label;
}
