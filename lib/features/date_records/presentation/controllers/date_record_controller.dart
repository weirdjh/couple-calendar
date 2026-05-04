import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/session_controller.dart';
import '../../domain/models/date_record.dart';

final dateRecordControllerProvider =
    NotifierProvider<DateRecordController, DateRecordState>(
      DateRecordController.new,
    );

class DateRecordState {
  const DateRecordState({this.records = const [], this.errorMessage});

  final List<DateRecord> records;
  final String? errorMessage;

  DateRecordState copyWith({
    List<DateRecord>? records,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DateRecordState(
      records: records ?? this.records,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class DateRecordController extends Notifier<DateRecordState> {
  var _nextId = 2;

  @override
  DateRecordState build() {
    final session = ref.watch(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      return const DateRecordState();
    }

    final now = DateTime.now();
    return DateRecordState(
      records: [
        DateRecord(
          id: 'date-record-1',
          coupleId: couple.id,
          title: '성수 산책',
          date: DateTime(now.year, now.month, now.day - 1),
          memo: '카페 갔다가 서울숲 걷기',
          place: const PlaceSnapshot(
            provider: PlaceProvider.manual,
            name: '서울숲',
            address: '서울 성동구',
          ),
          photoLabels: const ['서울숲 사진'],
          createdBy: user.id,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
  }

  DateRecord? addRecord({
    required String title,
    required DateTime date,
    String memo = '',
    String placeName = '',
    String placeAddress = '',
    List<String> photoLabels = const [],
    String? linkedEventId,
  }) {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: '데이트 제목을 입력해 주세요.');
      return null;
    }

    final now = DateTime.now();
    final record = DateRecord(
      id: 'date-record-${_nextId++}',
      coupleId: couple.id,
      title: trimmedTitle,
      date: date,
      memo: memo.trim(),
      place: placeName.trim().isEmpty
          ? null
          : PlaceSnapshot(
              provider: PlaceProvider.manual,
              name: placeName.trim(),
              address: placeAddress.trim().isEmpty ? null : placeAddress.trim(),
            ),
      photoLabels: List.unmodifiable(
        photoLabels
            .map((label) => label.trim())
            .where((label) => label.isNotEmpty),
      ),
      linkedEventId: linkedEventId,
      createdBy: user.id,
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      records: [record, ...state.records],
      clearError: true,
    );
    return record;
  }

  void linkCalendarEvent({required String recordId, required String eventId}) {
    final updatedRecords = state.records.map((record) {
      if (record.id != recordId) {
        return record;
      }
      return record.copyWith(linkedEventId: eventId, updatedAt: DateTime.now());
    }).toList();
    state = state.copyWith(records: updatedRecords, clearError: true);
  }
}
