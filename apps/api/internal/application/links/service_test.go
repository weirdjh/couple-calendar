package links_test

import (
	"context"
	"errors"
	"testing"
	"time"

	memorycalendar "couple-calendar-api/internal/adapters/persistence/memory/calendar"
	memorydaterecords "couple-calendar-api/internal/adapters/persistence/memory/daterecords"
	memoryreviews "couple-calendar-api/internal/adapters/persistence/memory/reviews"
	memorytodos "couple-calendar-api/internal/adapters/persistence/memory/todos"
	"couple-calendar-api/internal/application/authz"
	"couple-calendar-api/internal/application/calendar"
	"couple-calendar-api/internal/application/daterecords"
	"couple-calendar-api/internal/application/links"
	"couple-calendar-api/internal/application/reviews"
	"couple-calendar-api/internal/application/todos"
)

type fixedClock struct {
	now time.Time
}

func (c fixedClock) Now() time.Time {
	return c.now
}

type fixture struct {
	ctx            context.Context
	now            time.Time
	coupleID       string
	userID         string
	events         *memorycalendar.CalendarEventRepository
	records        *memorydaterecords.DateRecordRepository
	reviews        *memoryreviews.Repository
	todos          *memorytodos.Repository
	eventService   calendar.EventService
	reviewService  reviews.Service
	todoService    todos.Service
	linkService    links.Service
	dateRecordServ daterecords.Service
}

func newFixture() fixture {
	now := time.Date(2026, 5, 22, 9, 0, 0, 0, time.UTC)
	events := memorycalendar.NewCalendarEventRepository()
	records := memorydaterecords.NewDateRecordRepository()
	reviewsRepo := memoryreviews.NewRepository()
	todosRepo := memorytodos.NewRepository()
	clock := fixedClock{now: now}
	authorizer := authz.AllowAllAuthorizer{}
	eventService := calendar.NewEventService(events, authorizer, clock)
	return fixture{
		ctx:            context.Background(),
		now:            now,
		coupleID:       "couple-1",
		userID:         "user-1",
		events:         events,
		records:        records,
		reviews:        reviewsRepo,
		todos:          todosRepo,
		eventService:   eventService,
		reviewService:  reviews.NewService(reviewsRepo, authorizer, clock),
		todoService:    todos.NewService(todosRepo, authorizer, clock),
		linkService:    links.NewService(events, records, reviewsRepo, todosRepo, eventService, authorizer, clock),
		dateRecordServ: daterecords.NewService(records, authorizer, clock),
	}
}

func TestLinkReviewToDateRecordUpdatesBothSides(t *testing.T) {
	f := newFixture()
	record := createDateRecord(t, f)
	review := createReview(t, f)

	result, err := f.linkService.LinkReviewToDateRecord(f.ctx, f.coupleID, f.userID, review.ID, record.ID)
	if err != nil {
		t.Fatalf("LinkReviewToDateRecord() error = %v", err)
	}
	if result.Review.DateRecordID == nil || *result.Review.DateRecordID != record.ID {
		t.Fatalf("Review.DateRecordID = %v, want %s", result.Review.DateRecordID, record.ID)
	}

	storedRecord, err := f.records.Get(f.ctx, f.coupleID, record.ID)
	if err != nil {
		t.Fatalf("record Get() error = %v", err)
	}
	if len(storedRecord.LinkedItems) != 1 {
		t.Fatalf("record linked item count = %d, want 1", len(storedRecord.LinkedItems))
	}
	if storedRecord.LinkedItems[0].Type != "review" || storedRecord.LinkedItems[0].TargetID != review.ID {
		t.Fatalf("record linked item = %+v, want review %s", storedRecord.LinkedItems[0], review.ID)
	}
}

func TestDeleteDateRecordEverywhereCleansLinkedDomains(t *testing.T) {
	f := newFixture()
	event := createEvent(t, f)
	ensured, err := f.linkService.EnsureDateRecordForEvent(f.ctx, f.coupleID, f.userID, event.ID)
	if err != nil {
		t.Fatalf("EnsureDateRecordForEvent() error = %v", err)
	}
	review := createReview(t, f)
	if _, err := f.linkService.LinkReviewToDateRecord(f.ctx, f.coupleID, f.userID, review.ID, ensured.RecordID); err != nil {
		t.Fatalf("LinkReviewToDateRecord() error = %v", err)
	}
	item := createTodoItem(t, f)
	if _, err := f.linkService.CompleteTodoItemForEvent(f.ctx, f.coupleID, f.userID, item.ID, event.ID); err != nil {
		t.Fatalf("CompleteTodoItemForEvent() error = %v", err)
	}

	if err := f.linkService.DeleteDateRecordEverywhere(f.ctx, f.coupleID, f.userID, ensured.RecordID); err != nil {
		t.Fatalf("DeleteDateRecordEverywhere() error = %v", err)
	}

	if _, err := f.records.Get(f.ctx, f.coupleID, ensured.RecordID); !errors.Is(err, daterecords.ErrDateRecordNotFound) {
		t.Fatalf("record Get() error = %v, want %v", err, daterecords.ErrDateRecordNotFound)
	}
	storedReview, err := f.reviews.Get(f.ctx, f.coupleID, review.ID)
	if err != nil {
		t.Fatalf("review Get() error = %v", err)
	}
	if storedReview.DateRecordID != nil {
		t.Fatalf("Review.DateRecordID = %v, want nil", *storedReview.DateRecordID)
	}
	snapshot, err := f.todos.Fetch(f.ctx, f.coupleID)
	if err != nil {
		t.Fatalf("todos Fetch() error = %v", err)
	}
	if len(snapshot.Completions) != 0 {
		t.Fatalf("completion count = %d, want 0", len(snapshot.Completions))
	}
	storedEvent, err := f.events.Get(f.ctx, f.coupleID, event.ID)
	if err != nil {
		t.Fatalf("event Get() error = %v", err)
	}
	if storedEvent.Kind != calendar.EventKindSchedule {
		t.Fatalf("event Kind = %q, want %q", storedEvent.Kind, calendar.EventKindSchedule)
	}
	if len(storedEvent.LinkedItems) != 0 {
		t.Fatalf("event linked item count = %d, want 0", len(storedEvent.LinkedItems))
	}
}

func createEvent(t *testing.T, f fixture) calendar.Event {
	t.Helper()
	event, err := f.eventService.Create(f.ctx, calendar.CreateEventInput{
		CoupleID:  f.coupleID,
		UserID:    f.userID,
		Title:     "데이트",
		StartAt:   f.now.Add(24 * time.Hour),
		EndAt:     f.now.Add(26 * time.Hour),
		Ownership: calendar.EventOwnershipShared,
	})
	if err != nil {
		t.Fatalf("event Create() error = %v", err)
	}
	return event
}

func createDateRecord(t *testing.T, f fixture) daterecords.DateRecord {
	t.Helper()
	record, err := f.dateRecordServ.Create(f.ctx, daterecords.CreateInput{
		CoupleID: f.coupleID,
		UserID:   f.userID,
		Title:    "데이트 기록",
		Date:     f.now,
	})
	if err != nil {
		t.Fatalf("date record Create() error = %v", err)
	}
	return record
}

func createReview(t *testing.T, f fixture) reviews.Review {
	t.Helper()
	review, err := f.reviewService.Create(f.ctx, f.coupleID, f.userID, reviews.Draft{
		Type:   "movie",
		Title:  "영화 리뷰",
		Rating: 4,
	})
	if err != nil {
		t.Fatalf("review Create() error = %v", err)
	}
	return review
}

func createTodoItem(t *testing.T, f fixture) todos.Item {
	t.Helper()
	category, err := f.todoService.CreateCategory(f.ctx, f.coupleID, f.userID, todos.CategoryDraft{
		Title: "버킷",
		Emoji: "✅",
	})
	if err != nil {
		t.Fatalf("category Create() error = %v", err)
	}
	item, err := f.todoService.CreateItem(f.ctx, f.coupleID, f.userID, todos.ItemDraft{
		CategoryID: category.ID,
		Title:      "버킷 아이템",
	})
	if err != nil {
		t.Fatalf("item Create() error = %v", err)
	}
	return item
}
