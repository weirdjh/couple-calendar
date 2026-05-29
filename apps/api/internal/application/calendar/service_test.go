package calendar_test

import (
	"context"
	"testing"
	"time"

	memorycalendar "couple-calendar-api/internal/adapters/persistence/memory/calendar"
	memorycouples "couple-calendar-api/internal/adapters/persistence/memory/couples"
	"couple-calendar-api/internal/application/authz"
	"couple-calendar-api/internal/application/calendar"
	"couple-calendar-api/internal/application/couples"
)

type fixedClock struct {
	now time.Time
}

func (c fixedClock) Now() time.Time {
	return c.now
}

func TestCreateEventNormalizesDefaults(t *testing.T) {
	now := time.Date(2026, 5, 19, 12, 0, 0, 0, time.UTC)
	service := calendar.NewEventService(
		memorycalendar.NewCalendarEventRepository(),
		authz.AllowAllAuthorizer{},
		fixedClock{now: now},
	)

	event, err := service.Create(context.Background(), calendar.CreateEventInput{
		CoupleID: "couple-1",
		UserID:   "user-1",
		Title:    "  남산 가기  ",
		StartAt:  time.Date(2026, 6, 1, 10, 0, 0, 0, time.UTC),
		EndAt:    time.Date(2026, 6, 1, 12, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("Create() error = %v", err)
	}

	if event.Title != "남산 가기" {
		t.Fatalf("Title = %q", event.Title)
	}
	if event.Ownership != calendar.EventOwnershipPersonal {
		t.Fatalf("Ownership = %q", event.Ownership)
	}
	if event.Kind != calendar.EventKindSchedule {
		t.Fatalf("Kind = %q", event.Kind)
	}
	if event.OwnerUserID != "user-1" {
		t.Fatalf("OwnerUserID = %q", event.OwnerUserID)
	}
}

func TestDeleteEventRejectsPartnerOwnedPersonalEvent(t *testing.T) {
	now := time.Date(2026, 5, 19, 12, 0, 0, 0, time.UTC)
	repository := memorycalendar.NewCalendarEventRepository()
	service := calendar.NewEventService(repository, authz.AllowAllAuthorizer{}, fixedClock{now: now})
	event, err := service.Create(context.Background(), calendar.CreateEventInput{
		CoupleID:  "couple-1",
		UserID:    "user-1",
		Title:     "개인 일정",
		StartAt:   now,
		EndAt:     now.Add(time.Hour),
		Ownership: calendar.EventOwnershipPersonal,
	})
	if err != nil {
		t.Fatalf("Create() error = %v", err)
	}

	err = service.Delete(context.Background(), "couple-1", event.ID, "user-2")
	if err != calendar.ErrForbidden {
		t.Fatalf("Delete() error = %v, want %v", err, calendar.ErrForbidden)
	}
}

func TestUpdateEventAllowsSharedEventForPartner(t *testing.T) {
	now := time.Date(2026, 5, 19, 12, 0, 0, 0, time.UTC)
	service := calendar.NewEventService(
		memorycalendar.NewCalendarEventRepository(),
		authz.AllowAllAuthorizer{},
		fixedClock{now: now},
	)
	event, err := service.Create(context.Background(), calendar.CreateEventInput{
		CoupleID:  "couple-1",
		UserID:    "user-1",
		Title:     "우리 일정",
		StartAt:   now,
		EndAt:     now.Add(time.Hour),
		Ownership: calendar.EventOwnershipShared,
	})
	if err != nil {
		t.Fatalf("Create() error = %v", err)
	}

	updated, err := service.Update(context.Background(), calendar.UpdateEventInput{
		CoupleID:  "couple-1",
		EventID:   event.ID,
		UserID:    "user-2",
		Title:     "우리 일정 수정",
		StartAt:   now.Add(24 * time.Hour),
		EndAt:     now.Add(25 * time.Hour),
		Ownership: calendar.EventOwnershipShared,
	})
	if err != nil {
		t.Fatalf("Update() error = %v", err)
	}
	if updated.Title != "우리 일정 수정" {
		t.Fatalf("Title = %q", updated.Title)
	}
	if updated.OwnerUserID != "user-1" {
		t.Fatalf("OwnerUserID = %q", updated.OwnerUserID)
	}
}

func TestUpdateEventAllowsPartnerToWatchOnly(t *testing.T) {
	now := time.Date(2026, 5, 19, 12, 0, 0, 0, time.UTC)
	service := calendar.NewEventService(
		memorycalendar.NewCalendarEventRepository(),
		authz.AllowAllAuthorizer{},
		fixedClock{now: now},
	)
	event, err := service.Create(context.Background(), calendar.CreateEventInput{
		CoupleID:  "couple-1",
		UserID:    "user-1",
		Title:     "상대 개인 일정",
		StartAt:   now,
		EndAt:     now.Add(time.Hour),
		Ownership: calendar.EventOwnershipPersonal,
	})
	if err != nil {
		t.Fatalf("Create() error = %v", err)
	}

	updated, err := service.Update(context.Background(), calendar.UpdateEventInput{
		CoupleID:       "couple-1",
		EventID:        event.ID,
		UserID:         "user-2",
		Title:          event.Title,
		StartAt:        event.StartAt,
		EndAt:          event.EndAt,
		IsAllDay:       event.IsAllDay,
		Memo:           event.Memo,
		Kind:           event.Kind,
		ColorValue:     event.ColorValue,
		Ownership:      event.Ownership,
		WatcherUserIDs: []string{"user-2"},
		LinkedItems:    event.LinkedItems,
	})
	if err != nil {
		t.Fatalf("Update() error = %v", err)
	}
	if !updated.IsWatchedBy("user-2") {
		t.Fatalf("WatcherUserIDs = %v, want user-2", updated.WatcherUserIDs)
	}
	if updated.OwnerUserID != "user-1" {
		t.Fatalf("OwnerUserID = %q", updated.OwnerUserID)
	}
}

func TestUpdateEventRejectsPartnerContentChange(t *testing.T) {
	now := time.Date(2026, 5, 19, 12, 0, 0, 0, time.UTC)
	service := calendar.NewEventService(
		memorycalendar.NewCalendarEventRepository(),
		authz.AllowAllAuthorizer{},
		fixedClock{now: now},
	)
	event, err := service.Create(context.Background(), calendar.CreateEventInput{
		CoupleID:  "couple-1",
		UserID:    "user-1",
		Title:     "상대 개인 일정",
		StartAt:   now,
		EndAt:     now.Add(time.Hour),
		Ownership: calendar.EventOwnershipPersonal,
	})
	if err != nil {
		t.Fatalf("Create() error = %v", err)
	}

	_, err = service.Update(context.Background(), calendar.UpdateEventInput{
		CoupleID:       "couple-1",
		EventID:        event.ID,
		UserID:         "user-2",
		Title:          "몰래 수정",
		StartAt:        event.StartAt,
		EndAt:          event.EndAt,
		IsAllDay:       event.IsAllDay,
		Memo:           event.Memo,
		Kind:           event.Kind,
		ColorValue:     event.ColorValue,
		Ownership:      event.Ownership,
		WatcherUserIDs: []string{"user-2"},
		LinkedItems:    event.LinkedItems,
	})
	if err != calendar.ErrForbidden {
		t.Fatalf("Update() error = %v, want %v", err, calendar.ErrForbidden)
	}
}

func TestListForUserRejectsNonMember(t *testing.T) {
	now := time.Date(2026, 5, 19, 12, 0, 0, 0, time.UTC)
	coupleRepository := memorycouples.NewRepository()
	_, err := coupleRepository.Create(context.Background(), couples.Couple{
		ID:        "couple-1",
		MemberIDs: []string{"user-1"},
		CreatedAt: now,
	}, "user-1")
	if err != nil {
		t.Fatalf("Create couple error = %v", err)
	}
	service := calendar.NewEventService(
		memorycalendar.NewCalendarEventRepository(),
		authz.NewRepositoryAuthorizer(coupleRepository),
		fixedClock{now: now},
	)

	_, err = service.ListForUser(
		context.Background(),
		"couple-1",
		"user-2",
		now,
		now.Add(24*time.Hour),
	)
	if err != authz.ErrForbidden {
		t.Fatalf("ListForUser() error = %v, want %v", err, authz.ErrForbidden)
	}
}

func TestListForUserAllowsMember(t *testing.T) {
	now := time.Date(2026, 5, 19, 12, 0, 0, 0, time.UTC)
	coupleRepository := memorycouples.NewRepository()
	_, err := coupleRepository.Create(context.Background(), couples.Couple{
		ID:        "couple-1",
		MemberIDs: []string{"user-1"},
		CreatedAt: now,
	}, "user-1")
	if err != nil {
		t.Fatalf("Create couple error = %v", err)
	}
	service := calendar.NewEventService(
		memorycalendar.NewCalendarEventRepository(),
		authz.NewRepositoryAuthorizer(coupleRepository),
		fixedClock{now: now},
	)

	_, err = service.ListForUser(
		context.Background(),
		"couple-1",
		"user-1",
		now,
		now.Add(24*time.Hour),
	)
	if err != nil {
		t.Fatalf("ListForUser() error = %v", err)
	}
}
