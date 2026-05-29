import 'package:calendar/features/date_records/data/repositories/date_record_repository.dart';
import 'package:calendar/features/date_records/data/repositories/mock_date_record_repository.dart';
import 'package:calendar/features/links/domain/models/linked_item.dart';
import 'package:calendar/features/reviews/data/repositories/mock_review_repository.dart';
import 'package:calendar/features/reviews/data/repositories/review_repository.dart';
import 'package:calendar/features/reviews/domain/models/review.dart';
import 'package:calendar/features/todos/data/repositories/mock_todo_repository.dart';
import 'package:calendar/features/todos/data/repositories/todo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const coupleId = 'couple-test';
  const userId = 'user-test';

  group('TodoRepository contract', () {
    test(
      'creates and updates category, item, and completion records',
      () async {
        final repository = MockTodoRepository();

        final initial = await repository.fetchTodos(
          coupleId: coupleId,
          userId: userId,
        );
        expect(initial.categories, isNotEmpty);
        expect(initial.items, isNotEmpty);

        final category = await repository.createCategory(
          coupleId: coupleId,
          userId: userId,
          draft: const TodoCategoryDraft(title: '전시 보기', emoji: '🖼️'),
        );
        final updatedCategory = await repository.updateCategory(
          coupleId: coupleId,
          category: category.copyWith(title: '전시 보러 가기'),
        );

        final item = await repository.createItem(
          coupleId: coupleId,
          userId: userId,
          draft: TodoItemDraft(
            categoryId: updatedCategory.id,
            title: '국립현대미술관 가기',
            note: '서울관',
          ),
        );
        final updatedItem = await repository.updateItem(
          coupleId: coupleId,
          item: item.copyWith(note: '서울관 주말 예약'),
        );

        final completedAt = DateTime(2026, 5, 18);
        final completion = await repository.createCompletion(
          coupleId: coupleId,
          userId: userId,
          draft: TodoCompletionDraft(
            itemId: updatedItem.id,
            completedAt: completedAt,
            calendarEventId: 'event-test',
            memo: '완료',
          ),
        );

        var snapshot = await repository.fetchTodos(
          coupleId: coupleId,
          userId: userId,
        );
        expect(
          snapshot.categories.where((item) => item.title == '전시 보러 가기'),
          isNotEmpty,
        );
        expect(
          snapshot.items.where((item) => item.note == '서울관 주말 예약'),
          isNotEmpty,
        );
        expect(
          snapshot.completions.where((item) => item.id == completion.id),
          isNotEmpty,
        );

        await repository.deleteCompletion(
          coupleId: coupleId,
          userId: userId,
          completionId: completion.id,
        );
        snapshot = await repository.fetchTodos(
          coupleId: coupleId,
          userId: userId,
        );
        expect(
          snapshot.completions.where((item) => item.id == completion.id),
          isEmpty,
        );
      },
    );
  });

  group('DateRecordRepository contract', () {
    test('creates, updates, links, and unlinks records', () async {
      final repository = MockDateRecordRepository();
      final date = DateTime(2026, 5, 18);
      final linkedItem = LinkedItem(
        type: LinkedItemType.todo,
        targetId: 'todo-completion-test',
        targetPath: '/todos/todo-item-test/completions/todo-completion-test',
        title: '남산 가기',
        emoji: '⛰️',
        createdAt: date,
      );

      final record = await repository.createRecord(
        coupleId: coupleId,
        userId: userId,
        draft: DateRecordDraft(
          title: '남산 데이트',
          date: date,
          memo: '날씨 좋음',
          placeName: '남산',
          linkedItems: [linkedItem],
        ),
      );
      final updated = await repository.updateRecord(
        coupleId: coupleId,
        userId: userId,
        record: record.copyWith(memo: '야경 좋음'),
      );
      expect(updated.memo, '야경 좋음');

      final linked = await repository.linkCalendarEvent(
        coupleId: coupleId,
        userId: userId,
        recordId: record.id,
        eventId: 'event-test',
      );
      expect(linked.linkedEventId, 'event-test');

      final reviewLink = LinkedItem(
        type: LinkedItemType.review,
        targetId: 'review-test',
        targetPath: '/reviews/review-test',
        title: '와인 리뷰',
        createdAt: date,
      );
      final withReview = await repository.addLinkedItem(
        coupleId: coupleId,
        userId: userId,
        recordId: record.id,
        linkedItem: reviewLink,
      );
      expect(
        withReview.linkedItems.where(
          (item) =>
              item.type == LinkedItemType.review &&
              item.targetId == 'review-test',
        ),
        isNotEmpty,
      );

      final withoutReview = await repository.removeLinkedItem(
        coupleId: coupleId,
        userId: userId,
        recordId: record.id,
        linkedItem: reviewLink,
      );
      expect(
        withoutReview.linkedItems.where(
          (item) =>
              item.type == LinkedItemType.review &&
              item.targetId == 'review-test',
        ),
        isEmpty,
      );

      final unlinked = await repository.unlinkCalendarEvent(
        coupleId: coupleId,
        userId: userId,
        recordId: record.id,
        eventId: 'event-test',
      );
      expect(unlinked?.linkedEventId, isNull);

      await repository.deleteRecord(
        coupleId: coupleId,
        userId: userId,
        recordId: record.id,
      );
      final records = await repository.fetchDateRecords(
        coupleId: coupleId,
        userId: userId,
      );
      expect(records.where((item) => item.id == record.id), isEmpty);
    });
  });

  group('ReviewRepository contract', () {
    test('creates, updates, and deletes reviews', () async {
      final repository = MockReviewRepository();

      final review = await repository.createReview(
        coupleId: coupleId,
        userId: userId,
        draft: const ReviewDraft(
          type: ReviewType.wine,
          title: '피노 누아',
          rating: 4.0,
          memo: '가볍게 마시기 좋음',
          photoLabels: ['와인 라벨'],
          dateRecordId: 'date-record-test',
        ),
      );
      final updated = await repository.updateReview(
        coupleId: coupleId,
        userId: userId,
        review: review.copyWith(rating: 4.5, memo: '다시 마실 의향 있음'),
      );
      expect(updated.rating, 4.5);
      expect(updated.memo, '다시 마실 의향 있음');

      var reviews = await repository.fetchReviews(
        coupleId: coupleId,
        userId: userId,
      );
      expect(reviews.where((item) => item.id == review.id), isNotEmpty);

      await repository.deleteReview(
        coupleId: coupleId,
        reviewId: review.id,
        userId: userId,
      );
      reviews = await repository.fetchReviews(
        coupleId: coupleId,
        userId: userId,
      );
      expect(reviews.where((item) => item.id == review.id), isEmpty);
    });
  });
}
