package daterecords_test

import (
	"context"
	"testing"
	"time"

	memorydaterecords "couple-calendar-api/internal/adapters/persistence/memory/daterecords"
	"couple-calendar-api/internal/application/authz"
	"couple-calendar-api/internal/application/daterecords"
)

func TestCreateAndLinkDateRecord(t *testing.T) {
	now := time.Date(2026, 5, 20, 12, 0, 0, 0, time.UTC)
	service := daterecords.NewService(
		memorydaterecords.NewDateRecordRepository(),
		authz.AllowAllAuthorizer{},
		fixedClock{now: now},
	)

	record, err := service.Create(context.Background(), daterecords.CreateInput{
		CoupleID: "couple-1",
		UserID:   "user-1",
		Title:    "남산 데이트",
		Date:     now,
		Memo:     "좋았다",
	})
	if err != nil {
		t.Fatalf("Create() error = %v", err)
	}

	linked, err := service.LinkCalendarEvent(context.Background(), "couple-1", record.ID, "event-1", "user-1")
	if err != nil {
		t.Fatalf("LinkCalendarEvent() error = %v", err)
	}
	if linked.LinkedEventID == nil || *linked.LinkedEventID != "event-1" {
		t.Fatalf("LinkedEventID = %v, want event-1", linked.LinkedEventID)
	}

	unlinked, err := service.UnlinkCalendarEvent(context.Background(), "couple-1", record.ID, "event-1", "user-1")
	if err != nil {
		t.Fatalf("UnlinkCalendarEvent() error = %v", err)
	}
	if unlinked.LinkedEventID != nil {
		t.Fatalf("LinkedEventID = %v, want nil", *unlinked.LinkedEventID)
	}
}

type fixedClock struct {
	now time.Time
}

func (c fixedClock) Now() time.Time {
	return c.now
}
