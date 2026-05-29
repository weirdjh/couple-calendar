import 'package:calendar/core/api/api_client.dart';
import 'package:calendar/core/time/calendar_date_utils.dart';
import 'package:calendar/features/auth/data/repositories/auth_repository.dart';
import 'package:calendar/features/auth/domain/models/app_user.dart';
import 'package:calendar/features/auth/presentation/controllers/session_controller.dart';
import 'package:calendar/features/calendar/data/repositories/calendar_event_repository.dart';
import 'package:calendar/features/calendar/domain/models/calendar_event.dart';
import 'package:calendar/features/calendar/domain/models/event_input.dart';
import 'package:calendar/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:calendar/features/couple/data/repositories/couple_repository.dart';
import 'package:calendar/features/couple/domain/models/couple.dart';
import 'package:calendar/features/reviews/data/repositories/review_repository.dart';
import 'package:calendar/features/reviews/domain/models/review.dart';
import 'package:calendar/features/reviews/presentation/controllers/review_controller.dart';
import 'package:calendar/features/todos/data/repositories/todo_repository.dart';
import 'package:calendar/features/todos/domain/models/todo_item.dart';
import 'package:calendar/features/todos/presentation/controllers/todo_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CalendarController exposes repository load failures as UI state',
    () async {
      final container = _containerWith(
        calendarRepository: const _ThrowingCalendarRepository(),
      );
      addTearDown(container.dispose);
      await _settleSession(container);

      container.read(calendarControllerProvider);
      await _flushMicrotasks();

      final state = container.read(calendarControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.events, isEmpty);
      expect(state.errorMessage, '일정을 불러오지 못했어요.');
    },
  );

  test(
    'TodoController resets saving state when repository create fails',
    () async {
      final container = _containerWith(
        todoRepository: const _ThrowingTodoRepository(),
      );
      addTearDown(container.dispose);
      await _settleSession(container);

      container.read(todoControllerProvider);
      await _flushMicrotasks();

      final result = await container
          .read(todoControllerProvider.notifier)
          .addCategory(title: '등산하기', emoji: '⛰️');

      final state = container.read(todoControllerProvider);
      expect(result, isNull);
      expect(state.isSaving, isFalse);
      expect(state.categories, isEmpty);
      expect(state.errorMessage, '카테고리를 저장하지 못했어요.');
    },
  );

  test(
    'ReviewController resets saving state when repository create fails',
    () async {
      final container = _containerWith(
        reviewRepository: const _ThrowingReviewRepository(),
      );
      addTearDown(container.dispose);
      await _settleSession(container);

      container.read(reviewControllerProvider);
      await _flushMicrotasks();

      final result = await container
          .read(reviewControllerProvider.notifier)
          .addReview(type: ReviewType.movie, title: '영화 리뷰', rating: 4.5);

      final state = container.read(reviewControllerProvider);
      expect(result, isNull);
      expect(state.isSaving, isFalse);
      expect(state.reviews, isEmpty);
      expect(state.errorMessage, '리뷰를 저장하지 못했어요.');
    },
  );
}

ProviderContainer _containerWith({
  CalendarEventRepository calendarRepository = const _EmptyCalendarRepository(),
  TodoRepository todoRepository = const _EmptyTodoRepository(),
  ReviewRepository reviewRepository = const _EmptyReviewRepository(),
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        const _FakeAuthRepository(AppUser(id: 'user-a', displayName: '나')),
      ),
      coupleRepositoryProvider.overrideWithValue(
        _FakeCoupleRepository(_testCouple()),
      ),
      calendarEventRepositoryProvider.overrideWithValue(calendarRepository),
      todoRepositoryProvider.overrideWithValue(todoRepository),
      reviewRepositoryProvider.overrideWithValue(reviewRepository),
    ],
  );
}

Future<void> _settleSession(ProviderContainer container) async {
  container.read(sessionControllerProvider);
  await _flushMicrotasks();
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeAuthRepository implements AuthRepository {
  const _FakeAuthRepository(this.user);

  final AppUser? user;

  @override
  AppUser? currentUser() => user;
}

class _FakeCoupleRepository implements CoupleRepository {
  const _FakeCoupleRepository(this.couple);

  final Couple couple;

  @override
  Future<Couple?> currentCouple({required String userId}) async => couple;

  @override
  Future<Couple> createCouple({
    required String userId,
    required String partnerName,
  }) async {
    return couple;
  }

  @override
  Future<Couple> joinCouple({
    required String userId,
    required String inviteCode,
  }) async {
    return couple;
  }

  @override
  Future<void> resetCouple({required String userId}) async {}
}

class _EmptyCalendarRepository implements CalendarEventRepository {
  const _EmptyCalendarRepository();

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required String coupleId,
    required String userId,
    required DateRange visibleRange,
  }) async {
    return const [];
  }

  @override
  Future<CalendarEvent> createEvent({
    required String coupleId,
    required String userId,
    required EventInput input,
  }) async {
    throw const ApiException(500, 'not implemented');
  }

  @override
  Future<CalendarEvent> updateEvent({
    required String coupleId,
    required String userId,
    required CalendarEvent event,
  }) async {
    throw const ApiException(500, 'not implemented');
  }

  @override
  Future<void> deleteEvent({
    required String coupleId,
    required String eventId,
    required String userId,
  }) async {
    throw const ApiException(500, 'not implemented');
  }
}

class _ThrowingCalendarRepository extends _EmptyCalendarRepository {
  const _ThrowingCalendarRepository();

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required String coupleId,
    required String userId,
    required DateRange visibleRange,
  }) async {
    throw const ApiException(403, '{"error":"forbidden"}');
  }
}

class _EmptyTodoRepository implements TodoRepository {
  const _EmptyTodoRepository();

  @override
  Future<TodoSnapshot> fetchTodos({
    required String coupleId,
    required String userId,
  }) async {
    return const TodoSnapshot();
  }

  @override
  Future<TodoCategory> createCategory({
    required String coupleId,
    required String userId,
    required TodoCategoryDraft draft,
  }) async {
    throw const ApiException(500, 'not implemented');
  }

  @override
  Future<TodoCompletion> createCompletion({
    required String coupleId,
    required String userId,
    required TodoCompletionDraft draft,
  }) async {
    throw const ApiException(500, 'not implemented');
  }

  @override
  Future<TodoItem> createItem({
    required String coupleId,
    required String userId,
    required TodoItemDraft draft,
  }) async {
    throw const ApiException(500, 'not implemented');
  }

  @override
  Future<void> deleteCompletion({
    required String coupleId,
    required String userId,
    required String completionId,
  }) async {
    throw const ApiException(500, 'not implemented');
  }

  @override
  Future<TodoCategory> updateCategory({
    required String coupleId,
    required TodoCategory category,
  }) async {
    throw const ApiException(500, 'not implemented');
  }

  @override
  Future<TodoItem> updateItem({
    required String coupleId,
    required TodoItem item,
  }) async {
    throw const ApiException(500, 'not implemented');
  }
}

class _ThrowingTodoRepository extends _EmptyTodoRepository {
  const _ThrowingTodoRepository();

  @override
  Future<TodoCategory> createCategory({
    required String coupleId,
    required String userId,
    required TodoCategoryDraft draft,
  }) async {
    throw const ApiException(403, '{"error":"forbidden"}');
  }
}

class _EmptyReviewRepository implements ReviewRepository {
  const _EmptyReviewRepository();

  @override
  Future<List<Review>> fetchReviews({
    required String coupleId,
    required String userId,
  }) async {
    return const [];
  }

  @override
  Future<Review> createReview({
    required String coupleId,
    required String userId,
    required ReviewDraft draft,
  }) async {
    throw const ApiException(500, 'not implemented');
  }

  @override
  Future<void> deleteReview({
    required String coupleId,
    required String reviewId,
    required String userId,
  }) async {
    throw const ApiException(500, 'not implemented');
  }

  @override
  Future<Review> updateReview({
    required String coupleId,
    required String userId,
    required Review review,
  }) async {
    throw const ApiException(500, 'not implemented');
  }
}

class _ThrowingReviewRepository extends _EmptyReviewRepository {
  const _ThrowingReviewRepository();

  @override
  Future<Review> createReview({
    required String coupleId,
    required String userId,
    required ReviewDraft draft,
  }) async {
    throw const ApiException(403, '{"error":"forbidden"}');
  }
}

Couple _testCouple() {
  return Couple(
    id: 'couple-test',
    memberIds: const ['user-a', 'user-b'],
    inviteCode: 'LOVE-TEST',
    partnerDisplayName: '상대방',
    createdAt: DateTime(2026),
  );
}
