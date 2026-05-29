package calendar

import (
	"context"
	"time"

	domain "couple-calendar-api/internal/domain/calendar"
	"couple-calendar-api/internal/domain/links"
)

type Event = domain.Event
type EventKind = domain.EventKind
type EventOwnership = domain.EventOwnership
type LinkedItem = links.LinkedItem
type Reminder = domain.Reminder

const (
	EventKindSchedule = domain.EventKindSchedule
	EventKindDate     = domain.EventKindDate

	EventOwnershipPersonal = domain.EventOwnershipPersonal
	EventOwnershipShared   = domain.EventOwnershipShared
)

var (
	ErrInvalidEvent     = domain.ErrInvalidEvent
	ErrEventNotFound    = domain.ErrEventNotFound
	ErrForbidden        = domain.ErrForbidden
	ErrInvalidDateRange = domain.ErrInvalidDateRange
)

type EventRepository interface {
	List(ctx context.Context, coupleID string, visibleStart time.Time, visibleEnd time.Time) ([]Event, error)
	Create(ctx context.Context, event Event) (Event, error)
	Get(ctx context.Context, coupleID string, eventID string) (Event, error)
	Update(ctx context.Context, event Event) (Event, error)
	Delete(ctx context.Context, coupleID string, eventID string, deletedAt time.Time) error
}
