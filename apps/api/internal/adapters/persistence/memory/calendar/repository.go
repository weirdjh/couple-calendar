package calendar

import (
	"context"
	"sync"
	"time"

	"couple-calendar-api/internal/application/calendar"
)

type CalendarEventRepository struct {
	mu     sync.RWMutex
	events map[string]calendar.Event
}

func NewCalendarEventRepository() *CalendarEventRepository {
	return &CalendarEventRepository{events: map[string]calendar.Event{}}
}

func (r *CalendarEventRepository) List(ctx context.Context, coupleID string, visibleStart time.Time, visibleEnd time.Time) ([]calendar.Event, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	events := []calendar.Event{}
	for _, event := range r.events {
		if event.CoupleID != coupleID || event.DeletedAt != nil {
			continue
		}
		if event.StartAt.Before(visibleEnd) && !event.EndAt.Before(visibleStart) {
			events = append(events, event)
		}
	}
	return events, nil
}

func (r *CalendarEventRepository) Create(ctx context.Context, event calendar.Event) (calendar.Event, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.events[key(event.CoupleID, event.ID)] = event
	return event, nil
}

func (r *CalendarEventRepository) Get(ctx context.Context, coupleID string, eventID string) (calendar.Event, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	event, ok := r.events[key(coupleID, eventID)]
	if !ok || event.DeletedAt != nil {
		return calendar.Event{}, calendar.ErrEventNotFound
	}
	return event, nil
}

func (r *CalendarEventRepository) Update(ctx context.Context, event calendar.Event) (calendar.Event, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, ok := r.events[key(event.CoupleID, event.ID)]; !ok {
		return calendar.Event{}, calendar.ErrEventNotFound
	}
	r.events[key(event.CoupleID, event.ID)] = event
	return event, nil
}

func (r *CalendarEventRepository) Delete(ctx context.Context, coupleID string, eventID string, deletedAt time.Time) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	event, ok := r.events[key(coupleID, eventID)]
	if !ok || event.DeletedAt != nil {
		return calendar.ErrEventNotFound
	}
	event.DeletedAt = &deletedAt
	event.UpdatedAt = deletedAt
	r.events[key(coupleID, eventID)] = event
	return nil
}

func key(coupleID string, eventID string) string {
	return coupleID + "/" + eventID
}
