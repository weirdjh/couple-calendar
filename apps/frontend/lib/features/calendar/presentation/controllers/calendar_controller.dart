import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/calendar_date_utils.dart';
import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../data/repositories/calendar_event_repository.dart';
import '../../data/repositories/api_calendar_event_repository.dart';
import '../../data/repositories/firestore_calendar_event_repository.dart';
import '../../data/repositories/mock_calendar_event_repository.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/event_input.dart';

final calendarEventRepositoryProvider = Provider<CalendarEventRepository>((
  ref,
) {
  if (useApi) {
    return ApiCalendarEventRepository(baseUrl: apiBaseUrl);
  }
  if (useFirebase) {
    return FirestoreCalendarEventRepository();
  }
  return MockCalendarEventRepository();
});

final calendarControllerProvider =
    NotifierProvider<CalendarController, CalendarState>(CalendarController.new);

class CalendarState {
  const CalendarState({
    required this.focusedMonth,
    required this.selectedDate,
    this.events = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  List<CalendarEvent> get selectedDateEvents {
    final selected = dateOnly(selectedDate);
    return events.where((event) {
      final start = dateOnly(event.startAt);
      final end = event.isAllDay
          ? dateOnly(event.endAt).subtract(const Duration(days: 1))
          : dateOnly(event.endAt);
      return !selected.isBefore(start) && !selected.isAfter(end);
    }).toList()..sort(compareEventsForUi);
  }

  CalendarState copyWith({
    DateTime? focusedMonth,
    DateTime? selectedDate,
    List<CalendarEvent>? events,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CalendarState(
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class CalendarController extends Notifier<CalendarState> {
  late final CalendarEventRepository _repository;

  @override
  CalendarState build() {
    _repository = ref.watch(calendarEventRepositoryProvider);
    ref.watch(sessionControllerProvider.select((state) => state.currentCouple));
    final today = dateOnly(DateTime.now());
    final initial = CalendarState(
      focusedMonth: monthStart(today),
      selectedDate: today,
      isLoading: true,
    );
    Future.microtask(_loadVisibleMonth);
    return initial;
  }

  Future<void> selectDate(DateTime date) async {
    final selected = dateOnly(date);
    final monthChanged =
        selected.month != state.focusedMonth.month ||
        selected.year != state.focusedMonth.year;
    state = state.copyWith(
      selectedDate: selected,
      focusedMonth: monthChanged ? monthStart(selected) : state.focusedMonth,
      clearError: true,
    );
    if (monthChanged) {
      await _loadVisibleMonth();
    }
  }

  Future<void> goToPreviousMonth() async {
    state = state.copyWith(
      focusedMonth: DateTime(
        state.focusedMonth.year,
        state.focusedMonth.month - 1,
      ),
      clearError: true,
    );
    await _loadVisibleMonth();
  }

  Future<void> goToNextMonth() async {
    state = state.copyWith(
      focusedMonth: nextMonth(state.focusedMonth),
      clearError: true,
    );
    await _loadVisibleMonth();
  }

  Future<void> goToMonth(DateTime month) async {
    final targetMonth = monthStart(month);
    state = state.copyWith(
      focusedMonth: targetMonth,
      selectedDate: targetMonth,
      clearError: true,
    );
    await _loadVisibleMonth();
  }

  Future<void> goToToday() {
    return selectDate(DateTime.now());
  }

  Future<void> refreshVisibleMonth() {
    return _loadVisibleMonth();
  }

  Future<CalendarEvent?> createEvent(EventInput input) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }
    if (input.title.trim().isEmpty) {
      state = state.copyWith(errorMessage: '제목을 입력해 주세요.');
      return null;
    }
    if (!input.endAt.isAfter(input.startAt)) {
      state = state.copyWith(errorMessage: '종료 일시는 시작 일시보다 뒤여야 해요.');
      return null;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final event = await _repository.createEvent(
        coupleId: couple.id,
        userId: user.id,
        input: input,
      );
      state = state.copyWith(
        selectedDate: dateOnly(input.startAt),
        focusedMonth: monthStart(input.startAt),
      );
      await _loadVisibleMonth();
      state = state.copyWith(isSaving: false);
      return event;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '일정을 저장하지 못했어요.');
      return null;
    }
  }

  Future<CalendarEvent?> updateEventFromInput({
    required String eventId,
    required EventInput input,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }
    final event = state.events.where((item) => item.id == eventId).firstOrNull;
    if (event == null) {
      state = state.copyWith(errorMessage: '일정을 찾을 수 없어요.');
      return null;
    }
    if (input.title.trim().isEmpty) {
      state = state.copyWith(errorMessage: '제목을 입력해 주세요.');
      return null;
    }
    if (!input.endAt.isAfter(input.startAt)) {
      state = state.copyWith(errorMessage: '종료 일시는 시작 일시보다 뒤여야 해요.');
      return null;
    }
    if (!event.canEditFor(user.id)) {
      state = state.copyWith(errorMessage: '상대 일정은 수정할 수 없어요.');
      return null;
    }

    final now = DateTime.now();
    final reminders = input.reminderOffsetMinutes == null
        ? <Reminder>[]
        : [
            Reminder(
              id: event.reminders.isEmpty
                  ? 'reminder-${event.id}'
                  : event.reminders.first.id,
              eventId: event.id,
              remindAt: input.startAt.subtract(
                Duration(minutes: input.reminderOffsetMinutes!),
              ),
              offsetMinutes: input.reminderOffsetMinutes!,
              createdAt: event.reminders.isEmpty
                  ? now
                  : event.reminders.first.createdAt,
              updatedAt: now,
            ),
          ];

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repository.updateEvent(
        coupleId: couple.id,
        userId: user.id,
        event: event.copyWith(
          title: input.title.trim(),
          startAt: input.startAt,
          endAt: input.endAt,
          isAllDay: input.isAllDay,
          memo: input.memo.trim(),
          kind: input.kind,
          colorValue: input.colorValue,
          ownership: input.ownership,
          ownerUserId: input.ownership == EventOwnership.shared
              ? event.effectiveOwnerUserId
              : user.id,
          reminders: reminders,
          linkedItems: input.linkedItems,
        ),
      );
      await _loadVisibleMonth();
      state = state.copyWith(
        selectedDate: dateOnly(input.startAt),
        focusedMonth: monthStart(input.startAt),
        isSaving: false,
      );
      return updated;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '일정을 수정하지 못했어요.');
      return null;
    }
  }

  Future<CalendarEvent?> addLinkedItem({
    required String eventId,
    required LinkedItem linkedItem,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }

    final event = state.events.where((item) => item.id == eventId).firstOrNull;
    if (event == null) {
      state = state.copyWith(errorMessage: '일정을 찾을 수 없어요.');
      return null;
    }
    if (!event.canEditFor(user.id)) {
      state = state.copyWith(errorMessage: '상대 일정에는 링크를 추가할 수 없어요.');
      return null;
    }

    final alreadyLinked = event.linkedItems.any(
      (item) =>
          item.type == linkedItem.type && item.targetId == linkedItem.targetId,
    );
    if (alreadyLinked) {
      return event;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repository.updateEvent(
        coupleId: couple.id,
        userId: user.id,
        event: event.copyWith(
          kind: linkedItem.type == LinkedItemType.dateRecord
              ? CalendarEventKind.date
              : event.kind,
          linkedItems: [...event.linkedItems, linkedItem],
        ),
      );
      await _loadVisibleMonth();
      state = state.copyWith(isSaving: false);
      return updated;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '링크를 추가하지 못했어요.');
      return null;
    }
  }

  Future<CalendarEvent?> removeLinkedItem({
    required String eventId,
    required LinkedItem linkedItem,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }

    final event = state.events.where((item) => item.id == eventId).firstOrNull;
    if (event == null) {
      state = state.copyWith(errorMessage: '일정을 찾을 수 없어요.');
      return null;
    }
    if (!event.canEditFor(user.id)) {
      state = state.copyWith(errorMessage: '상대 일정의 링크는 해제할 수 없어요.');
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repository.updateEvent(
        coupleId: couple.id,
        userId: user.id,
        event: event.copyWith(
          linkedItems: event.linkedItems
              .where(
                (item) =>
                    item.type != linkedItem.type ||
                    item.targetId != linkedItem.targetId,
              )
              .toList(),
        ),
      );
      await _loadVisibleMonth();
      state = state.copyWith(isSaving: false);
      return updated;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '링크를 해제하지 못했어요.');
      return null;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return;
    }
    final event = state.events.where((item) => item.id == eventId).firstOrNull;
    if (event == null) {
      state = state.copyWith(errorMessage: '일정을 찾을 수 없어요.');
      return;
    }
    if (!event.canEditFor(user.id)) {
      state = state.copyWith(errorMessage: '상대 일정은 삭제할 수 없어요.');
      return;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.deleteEvent(
        coupleId: couple.id,
        eventId: eventId,
        userId: user.id,
      );
      await _loadVisibleMonth();
      state = state.copyWith(isSaving: false);
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '일정을 삭제하지 못했어요.');
    }
  }

  Future<CalendarEvent?> toggleWatchEvent(String eventId) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }

    final event = state.events.where((item) => item.id == eventId).firstOrNull;
    if (event == null) {
      state = state.copyWith(errorMessage: '일정을 찾을 수 없어요.');
      return null;
    }
    if (!event.isPartnerOwnedFor(user.id)) {
      state = state.copyWith(errorMessage: '상대 일정만 지켜볼 수 있어요.');
      return null;
    }

    final watchers = event.isWatchedBy(user.id)
        ? event.watcherUserIds.where((id) => id != user.id).toList()
        : [...event.watcherUserIds, user.id];

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repository.updateEvent(
        coupleId: couple.id,
        userId: user.id,
        event: event.copyWith(watcherUserIds: watchers),
      );
      await _loadVisibleMonth();
      state = state.copyWith(isSaving: false);
      return updated;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '지켜보기 설정을 바꾸지 못했어요.',
      );
      return null;
    }
  }

  Future<void> _loadVisibleMonth() async {
    final couple = ref.read(sessionControllerProvider).currentCouple;
    final user = ref.read(sessionControllerProvider).currentUser;
    if (couple == null || user == null) {
      state = state.copyWith(events: const [], isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final events = await _repository.fetchEvents(
        coupleId: couple.id,
        userId: user.id,
        visibleRange: visibleMonthRange(state.focusedMonth),
      );
      state = state.copyWith(events: events, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: '일정을 불러오지 못했어요.');
    }
  }
}

int compareEventsForUi(CalendarEvent left, CalendarEvent right) {
  if (left.isAllDay != right.isAllDay) {
    return left.isAllDay ? -1 : 1;
  }
  final timeCompare = left.startAt.compareTo(right.startAt);
  if (timeCompare != 0) {
    return timeCompare;
  }
  return left.title.compareTo(right.title);
}
