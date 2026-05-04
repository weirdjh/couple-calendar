import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../calendar/domain/models/calendar_event.dart';
import '../../../calendar/domain/models/event_input.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../../domain/models/date_record.dart';
import '../controllers/date_record_controller.dart';

class DateRecordScreen extends ConsumerStatefulWidget {
  const DateRecordScreen({super.key});

  @override
  ConsumerState<DateRecordScreen> createState() => _DateRecordScreenState();
}

class _DateRecordScreenState extends ConsumerState<DateRecordScreen> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _placeNameController = TextEditingController();
  final _placeAddressController = TextEditingController();
  final _photoController = TextEditingController();
  final _photoLabels = <String>[];
  var _date = dates.dateOnly(DateTime.now());

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
    final state = ref.watch(dateRecordControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('데이트 기록')),
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
              date: _date,
              onPickDate: _pickDate,
              onAddPhoto: _addPhoto,
              onRemovePhoto: (label) {
                setState(() => _photoLabels.remove(label));
              },
              onSave: _saveRecord,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 10),
              _ErrorPanel(message: state.errorMessage!),
            ],
            const SizedBox(height: 20),
            Text(
              '기록 목록',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (state.records.isEmpty)
              const _EmptyPanel(text: '데이트 기록이 아직 없어요.')
            else
              ...state.records.map((record) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DateRecordTile(record: record),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
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

  Future<void> _saveRecord() async {
    final provisionalRecord = ref
        .read(dateRecordControllerProvider.notifier)
        .addRecord(
          title: _titleController.text,
          date: _date,
          memo: _memoController.text,
          placeName: _placeNameController.text,
          placeAddress: _placeAddressController.text,
          photoLabels: _photoLabels,
        );
    if (provisionalRecord == null) {
      return;
    }

    final linkedItem = LinkedItem(
      type: LinkedItemType.dateRecord,
      targetId: provisionalRecord.id,
      targetPath: '/records/dates/${provisionalRecord.id}',
      title: provisionalRecord.title,
      subtitle: provisionalRecord.place?.name,
      date: provisionalRecord.date,
      thumbnailUrl: provisionalRecord.photoLabels.firstOrNull,
      preview: provisionalRecord.memo,
      createdAt: DateTime.now(),
    );
    final event = await ref
        .read(calendarControllerProvider.notifier)
        .createEvent(
          EventInput(
            title: provisionalRecord.title,
            startAt: provisionalRecord.date,
            endAt: provisionalRecord.date.add(const Duration(days: 1)),
            isAllDay: true,
            memo: provisionalRecord.memo,
            colorValue: 0xFF5D8C61,
            linkedItems: [linkedItem],
          ),
        );

    if (event == null) {
      return;
    }
    ref
        .read(dateRecordControllerProvider.notifier)
        .linkCalendarEvent(recordId: provisionalRecord.id, eventId: event.id);

    _titleController.clear();
    _memoController.clear();
    _placeNameController.clear();
    _placeAddressController.clear();
    _photoController.clear();
    setState(_photoLabels.clear);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('데이트 기록을 캘린더에 연결했어요.')));
    }
  }
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
    required this.onSave,
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
  final VoidCallback onSave;

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
            leading: const Icon(Icons.event_outlined),
            title: const Text('날짜'),
            subtitle: Text(dates.formatDateLabel(date)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: onPickDate,
          ),
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
              label: const Text('기록 저장'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRecordTile extends StatelessWidget {
  const _DateRecordTile({required this.record});

  final DateRecord record;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: const Icon(Icons.place_outlined),
      title: Text(
        record.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        [
          dates.formatDateLabel(record.date),
          if (record.place != null) record.place!.name,
          if (record.photoLabels.isNotEmpty) '사진 ${record.photoLabels.length}',
        ].join(' · '),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
