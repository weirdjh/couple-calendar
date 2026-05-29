import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../links/domain/models/linked_item.dart';
import '../../../photos/domain/models/photo_attachment.dart';
import '../../data/repositories/api_date_record_repository.dart';
import '../../data/repositories/date_record_repository.dart';
import '../../data/repositories/firestore_date_record_repository.dart';
import '../../data/repositories/mock_date_record_repository.dart';
import '../../domain/models/date_record.dart';

final dateRecordRepositoryProvider = Provider<DateRecordRepository>((ref) {
  if (useApi) {
    return ApiDateRecordRepository(baseUrl: apiBaseUrl);
  }
  if (useFirebase) {
    return FirestoreDateRecordRepository();
  }
  return MockDateRecordRepository();
});

final dateRecordControllerProvider =
    NotifierProvider<DateRecordController, DateRecordState>(
      DateRecordController.new,
    );

class DateRecordState {
  const DateRecordState({
    this.records = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final List<DateRecord> records;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  DateRecord? recordById(String recordId) {
    return records.where((record) => record.id == recordId).firstOrNull;
  }

  DateRecordState copyWith({
    List<DateRecord>? records,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DateRecordState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class DateRecordController extends Notifier<DateRecordState> {
  late final DateRecordRepository _repository;

  @override
  DateRecordState build() {
    _repository = ref.watch(dateRecordRepositoryProvider);
    final session = ref.watch(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      return const DateRecordState();
    }
    Future.microtask(_loadDateRecords);
    return const DateRecordState(isLoading: true);
  }

  Future<DateRecord?> addRecord({
    required String title,
    required DateTime date,
    String memo = '',
    String placeName = '',
    String placeAddress = '',
    List<String> photoLabels = const [],
    List<LinkedItem> linkedItems = const [],
    String? linkedEventId,
  }) async {
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

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final record = await _repository.createRecord(
        coupleId: couple.id,
        userId: user.id,
        draft: DateRecordDraft(
          title: trimmedTitle,
          date: date,
          memo: memo.trim(),
          placeName: placeName.trim(),
          placeAddress: placeAddress.trim(),
          photoLabels: photoLabels,
          linkedItems: linkedItems,
          linkedEventId: linkedEventId,
        ),
      );
      state = state.copyWith(
        records: [record, ...state.records],
        isSaving: false,
      );
      return record;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '데이트 기록을 저장하지 못했어요.',
      );
      return null;
    }
  }

  Future<DateRecord?> linkCalendarEvent({
    required String recordId,
    required String eventId,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repository.linkCalendarEvent(
        coupleId: couple.id,
        userId: user.id,
        recordId: recordId,
        eventId: eventId,
      );
      state = state.copyWith(
        records: state.records
            .map((record) => record.id == recordId ? updated : record)
            .toList(),
        isSaving: false,
      );
      return updated;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '일정 연결을 저장하지 못했어요.',
      );
      return null;
    }
  }

  Future<DateRecord?> unlinkCalendarEvent({
    required String? recordId,
    required String eventId,
  }) async {
    if (recordId == null) {
      return null;
    }
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repository.unlinkCalendarEvent(
        coupleId: couple.id,
        userId: user.id,
        recordId: recordId,
        eventId: eventId,
      );
      if (updated == null) {
        state = state.copyWith(isSaving: false);
        return null;
      }
      state = state.copyWith(
        records: state.records
            .map((record) => record.id == recordId ? updated : record)
            .toList(),
        isSaving: false,
      );
      return updated;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '일정 연결을 해제하지 못했어요.',
      );
      return null;
    }
  }

  Future<DateRecord?> updateRecord({
    required String recordId,
    required String title,
    required DateTime date,
    String memo = '',
    String placeName = '',
    String placeAddress = '',
    List<String> photoLabels = const [],
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: '데이트 제목을 입력해 주세요.');
      return null;
    }
    final user = ref.read(sessionControllerProvider).currentUser;
    if (user == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }

    final record = state.recordById(recordId);
    if (record == null) {
      state = state.copyWith(errorMessage: '데이트 기록을 찾을 수 없어요.');
      return null;
    }
    final updatedRecord = record.copyWith(
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
      photos: photoAttachmentsFromLabels(photoLabels),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _repository.updateRecord(
        coupleId: record.coupleId,
        userId: user.id,
        record: updatedRecord,
      );
      state = state.copyWith(
        records: state.records
            .map((item) => item.id == recordId ? saved : item)
            .toList(),
        isSaving: false,
      );
      return saved;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '데이트 기록을 수정하지 못했어요.',
      );
      return null;
    }
  }

  Future<void> deleteRecord(String recordId) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return;
    }
    final exists = state.records.any((record) => record.id == recordId);
    if (!exists) {
      state = state.copyWith(errorMessage: '데이트 기록을 찾을 수 없어요.');
      return;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.deleteRecord(
        coupleId: couple.id,
        userId: user.id,
        recordId: recordId,
      );
      state = state.copyWith(
        records: state.records
            .where((record) => record.id != recordId)
            .toList(),
        isSaving: false,
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '데이트 기록을 삭제하지 못했어요.',
      );
    }
  }

  Future<DateRecord?> addLinkedItem({
    required String recordId,
    required LinkedItem linkedItem,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repository.addLinkedItem(
        coupleId: couple.id,
        userId: user.id,
        recordId: recordId,
        linkedItem: linkedItem,
      );
      state = state.copyWith(
        records: state.records
            .map((record) => record.id == recordId ? updated : record)
            .toList(),
        isSaving: false,
      );
      return updated;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '연결 정보를 저장하지 못했어요.',
      );
      return null;
    }
  }

  Future<DateRecord?> removeLinkedItem({
    required String recordId,
    required LinkedItem linkedItem,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repository.removeLinkedItem(
        coupleId: couple.id,
        userId: user.id,
        recordId: recordId,
        linkedItem: linkedItem,
      );
      state = state.copyWith(
        records: state.records
            .map((record) => record.id == recordId ? updated : record)
            .toList(),
        isSaving: false,
      );
      return updated;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '연결 정보를 해제하지 못했어요.',
      );
      return null;
    }
  }

  Future<void> refreshDateRecords() {
    return _loadDateRecords();
  }

  Future<void> _loadDateRecords() async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = const DateRecordState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final records = await _repository.fetchDateRecords(
        coupleId: couple.id,
        userId: user.id,
      );
      state = state.copyWith(records: records, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '데이트 기록을 불러오지 못했어요.',
      );
    }
  }
}
