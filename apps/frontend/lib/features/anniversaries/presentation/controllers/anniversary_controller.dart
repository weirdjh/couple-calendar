import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../../core/time/calendar_date_utils.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../../data/repositories/anniversary_repository.dart';
import '../../data/repositories/api_anniversary_repository.dart';
import '../../data/repositories/firestore_anniversary_repository.dart';
import '../../data/repositories/mock_anniversary_repository.dart';
import '../../domain/models/anniversary.dart';
import '../../domain/services/anniversary_calculator.dart';

final anniversaryRepositoryProvider = Provider<AnniversaryRepository>((ref) {
  if (useApi) {
    return ApiAnniversaryRepository(baseUrl: apiBaseUrl);
  }
  if (useFirebase) {
    return FirestoreAnniversaryRepository();
  }
  return MockAnniversaryRepository();
});

final anniversaryControllerProvider =
    NotifierProvider<AnniversaryController, AnniversaryState>(
      AnniversaryController.new,
    );

final anniversariesProvider = Provider<List<Anniversary>>((ref) {
  return ref.watch(anniversaryControllerProvider).anniversaries;
});

class AnniversaryState {
  const AnniversaryState({
    this.anniversaries = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final List<Anniversary> anniversaries;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  AnniversaryState copyWith({
    List<Anniversary>? anniversaries,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnniversaryState(
      anniversaries: anniversaries ?? this.anniversaries,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AnniversaryController extends Notifier<AnniversaryState> {
  late final AnniversaryRepository _repository;

  @override
  AnniversaryState build() {
    _repository = ref.watch(anniversaryRepositoryProvider);
    final session = ref.watch(sessionControllerProvider);
    if (session.currentUser == null || session.currentCouple == null) {
      return const AnniversaryState();
    }
    Future.microtask(_loadAnniversaries);
    return const AnniversaryState(isLoading: true);
  }

  Future<Anniversary?> addAnniversary({
    required String title,
    required DateTime baseDate,
    required AnniversaryRepeatRule repeatRule,
    required AnniversaryCalendarType calendarType,
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
      state = state.copyWith(errorMessage: '기념일 이름을 입력해 주세요.');
      return null;
    }

    final storedBaseDate = _storedBaseDate(
      baseDate: baseDate,
      calendarType: calendarType,
    );

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final anniversary = await _repository.createAnniversary(
        coupleId: couple.id,
        userId: user.id,
        draft: AnniversaryDraft(
          title: trimmedTitle,
          baseDate: storedBaseDate.date,
          repeatRule: repeatRule,
          calendarType: calendarType,
          isLeapMonth: storedBaseDate.isLeapMonth,
        ),
      );
      state = state.copyWith(
        anniversaries: [...state.anniversaries, anniversary],
        isSaving: false,
      );
      return anniversary;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '기념일을 저장하지 못했어요.');
      return null;
    }
  }

  Future<Anniversary?> updateAnniversary({
    required String anniversaryId,
    required String title,
    required DateTime baseDate,
    required AnniversaryRepeatRule repeatRule,
    required AnniversaryCalendarType calendarType,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final couple = session.currentCouple;
    final user = session.currentUser;
    if (couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }
    if (user == null) {
      state = state.copyWith(errorMessage: '로그인이 필요해요.');
      return null;
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: '기념일 이름을 입력해 주세요.');
      return null;
    }

    final index = state.anniversaries.indexWhere(
      (anniversary) => anniversary.id == anniversaryId,
    );
    if (index == -1) {
      state = state.copyWith(errorMessage: '기념일을 찾을 수 없어요.');
      return null;
    }

    final storedBaseDate = _storedBaseDate(
      baseDate: baseDate,
      calendarType: calendarType,
    );
    final draft = state.anniversaries[index].copyWith(
      title: trimmedTitle,
      baseDate: storedBaseDate.date,
      repeatRule: repeatRule,
      calendarType: calendarType,
      isLeapMonth: storedBaseDate.isLeapMonth,
    );

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repository.updateAnniversary(
        coupleId: couple.id,
        userId: user.id,
        anniversary: draft,
      );
      final next = [...state.anniversaries];
      next[index] = updated;
      state = state.copyWith(anniversaries: next, isSaving: false);
      return updated;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '기념일을 수정하지 못했어요.');
      return null;
    }
  }

  Future<void> deleteAnniversary(String anniversaryId) async {
    final couple = ref.read(sessionControllerProvider).currentCouple;
    final user = ref.read(sessionControllerProvider).currentUser;
    if (couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return;
    }
    if (user == null) {
      state = state.copyWith(errorMessage: '로그인이 필요해요.');
      return;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.deleteAnniversary(
        coupleId: couple.id,
        anniversaryId: anniversaryId,
        userId: user.id,
      );
      state = state.copyWith(
        anniversaries: state.anniversaries
            .where((anniversary) => anniversary.id != anniversaryId)
            .toList(),
        isSaving: false,
      );
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '기념일을 삭제하지 못했어요.');
    }
  }

  Future<void> refreshAnniversaries() {
    return _loadAnniversaries();
  }

  ({DateTime date, bool isLeapMonth}) _storedBaseDate({
    required DateTime baseDate,
    required AnniversaryCalendarType calendarType,
  }) {
    final normalized = dateOnly(baseDate);
    if (calendarType == AnniversaryCalendarType.solar) {
      return (date: normalized, isLeapMonth: false);
    }
    return (date: normalized, isLeapMonth: false);
  }

  Future<void> _loadAnniversaries() async {
    final couple = ref.read(sessionControllerProvider).currentCouple;
    final user = ref.read(sessionControllerProvider).currentUser;
    if (couple == null || user == null) {
      state = const AnniversaryState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final anniversaries = await _repository.fetchAnniversaries(
        coupleId: couple.id,
        userId: user.id,
      );
      state = state.copyWith(anniversaries: anniversaries, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: '기념일을 불러오지 못했어요.');
    }
  }
}

final visibleAnniversaryOccurrencesProvider =
    Provider<List<AnniversaryOccurrence>>((ref) {
      final calendarState = ref.watch(calendarControllerProvider);
      final anniversaries = ref.watch(anniversariesProvider);
      final range = visibleMonthRange(calendarState.focusedMonth);

      return anniversaries
          .expand(
            (anniversary) => calculateAnniversaryOccurrences(
              anniversary: anniversary,
              visibleRange: range,
            ),
          )
          .toList();
    });

final selectedDateAnniversaryOccurrencesProvider =
    Provider<List<AnniversaryOccurrence>>((ref) {
      final calendarState = ref.watch(calendarControllerProvider);
      final occurrences = ref.watch(visibleAnniversaryOccurrencesProvider);
      return occurrences
          .where(
            (occurrence) =>
                isSameDate(occurrence.date, calendarState.selectedDate),
          )
          .toList();
    });

final nextAnniversaryOccurrenceProvider = Provider<AnniversaryOccurrence?>((
  ref,
) {
  final anniversaries = ref.watch(anniversariesProvider);
  final upcoming =
      anniversaries
          .map(
            (anniversary) => nextAnniversaryOccurrence(
              anniversary: anniversary,
              fromDate: DateTime.now(),
            ),
          )
          .nonNulls
          .toList()
        ..sort((left, right) => left.date.compareTo(right.date));
  if (upcoming.isEmpty) {
    return null;
  }
  return upcoming.first;
});

final upcomingAnniversaryOccurrencesProvider =
    Provider<List<AnniversaryOccurrence>>((ref) {
      final anniversaries = ref.watch(anniversariesProvider);
      final now = DateTime.now();
      final today = dateOnly(now);

      final occurrences =
          anniversaries
              .map(
                (anniversary) => nextAnniversaryOccurrence(
                  anniversary: anniversary,
                  fromDate: today,
                ),
              )
              .nonNulls
              .toList()
            ..sort((left, right) => left.date.compareTo(right.date));
      return occurrences;
    });
