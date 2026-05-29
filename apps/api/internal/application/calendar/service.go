package calendar

import (
	"context"
	"strings"
	"time"

	"couple-calendar-api/internal/application/authz"
	"couple-calendar-api/internal/platform/clock"
	"couple-calendar-api/internal/platform/idgen"
)

type EventService struct {
	repository EventRepository
	authorizer authz.CoupleAuthorizer
	clock      clock.Clock
	ids        idgen.Generator
}

func NewEventService(repository EventRepository, authorizer authz.CoupleAuthorizer, clock clock.Clock) EventService {
	return EventService{
		repository: repository,
		authorizer: authorizer,
		clock:      clock,
		ids:        idgen.Crypto{},
	}
}

type CreateEventInput struct {
	CoupleID              string
	UserID                string
	Title                 string
	StartAt               time.Time
	EndAt                 time.Time
	IsAllDay              bool
	Memo                  string
	Kind                  EventKind
	ColorValue            int
	Ownership             EventOwnership
	LinkedItems           []LinkedItem
	ReminderOffsetMinutes *int
}

type UpdateEventInput struct {
	CoupleID              string
	EventID               string
	UserID                string
	Title                 string
	StartAt               time.Time
	EndAt                 time.Time
	IsAllDay              bool
	Memo                  string
	Kind                  EventKind
	ColorValue            int
	Ownership             EventOwnership
	WatcherUserIDs        []string
	LinkedItems           []LinkedItem
	ReminderOffsetMinutes *int
}

func (s EventService) List(ctx context.Context, coupleID string, visibleStart time.Time, visibleEnd time.Time) ([]Event, error) {
	if coupleID == "" || !visibleStart.Before(visibleEnd) {
		return nil, ErrInvalidDateRange
	}
	return s.repository.List(ctx, coupleID, visibleStart.UTC(), visibleEnd.UTC())
}

func (s EventService) ListForUser(ctx context.Context, coupleID string, userID string, visibleStart time.Time, visibleEnd time.Time) ([]Event, error) {
	if userID == "" {
		return nil, ErrInvalidEvent
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return nil, err
	}
	return s.List(ctx, coupleID, visibleStart, visibleEnd)
}

func (s EventService) Create(ctx context.Context, input CreateEventInput) (Event, error) {
	title := strings.TrimSpace(input.Title)
	if input.CoupleID == "" || input.UserID == "" || title == "" || input.StartAt.IsZero() {
		return Event{}, ErrInvalidEvent
	}

	endAt := input.EndAt
	if endAt.IsZero() {
		endAt = input.StartAt
	}
	if endAt.Before(input.StartAt) {
		return Event{}, ErrInvalidEvent
	}

	now := s.clock.Now()
	eventID := s.ids.NewID("evt")
	ownership := input.Ownership
	if ownership == "" {
		ownership = EventOwnershipPersonal
	}
	kind := input.Kind
	if kind == "" {
		kind = EventKindSchedule
	}
	colorValue := input.ColorValue
	if colorValue == 0 {
		colorValue = 0xFF4D7C8A
	}

	event := Event{
		ID:             eventID,
		CoupleID:       input.CoupleID,
		Title:          title,
		StartAt:        input.StartAt.UTC(),
		EndAt:          endAt.UTC(),
		IsAllDay:       input.IsAllDay,
		Memo:           strings.TrimSpace(input.Memo),
		Kind:           kind,
		ColorValue:     colorValue,
		Ownership:      ownership,
		OwnerUserID:    input.UserID,
		WatcherUserIDs: []string{},
		Reminders:      buildReminders(eventID, input.StartAt.UTC(), input.ReminderOffsetMinutes, now),
		LinkedItems:    append([]LinkedItem{}, input.LinkedItems...),
		CreatedBy:      input.UserID,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
	return s.repository.Create(ctx, event)
}

func (s EventService) Update(ctx context.Context, input UpdateEventInput) (Event, error) {
	title := strings.TrimSpace(input.Title)
	if input.CoupleID == "" || input.EventID == "" || input.UserID == "" || title == "" || input.StartAt.IsZero() {
		return Event{}, ErrInvalidEvent
	}
	if input.EndAt.IsZero() || input.EndAt.Before(input.StartAt) {
		return Event{}, ErrInvalidEvent
	}

	event, err := s.repository.Get(ctx, input.CoupleID, input.EventID)
	if err != nil {
		return Event{}, err
	}
	if !event.CanEdit(input.UserID) && !isWatchOnlyUpdate(event, input) {
		return Event{}, ErrForbidden
	}

	now := s.clock.Now()
	kind := input.Kind
	if kind == "" {
		kind = event.Kind
	}
	ownership := input.Ownership
	if ownership == "" {
		ownership = event.Ownership
	}
	colorValue := input.ColorValue
	if colorValue == 0 {
		colorValue = event.ColorValue
	}

	event.Title = title
	event.StartAt = input.StartAt.UTC()
	event.EndAt = input.EndAt.UTC()
	event.IsAllDay = input.IsAllDay
	event.Memo = strings.TrimSpace(input.Memo)
	event.Kind = kind
	event.ColorValue = colorValue
	event.Ownership = ownership
	if ownership == EventOwnershipPersonal && event.CanEdit(input.UserID) {
		event.OwnerUserID = input.UserID
	}
	event.WatcherUserIDs = append([]string{}, input.WatcherUserIDs...)
	event.Reminders = buildReminders(event.ID, input.StartAt.UTC(), input.ReminderOffsetMinutes, now)
	event.LinkedItems = append([]LinkedItem{}, input.LinkedItems...)
	event.UpdatedAt = now

	return s.repository.Update(ctx, event)
}

func isWatchOnlyUpdate(event Event, input UpdateEventInput) bool {
	if event.Ownership != EventOwnershipPersonal || event.OwnerUserID == input.UserID {
		return false
	}
	if strings.TrimSpace(input.Title) != event.Title ||
		!input.StartAt.UTC().Equal(event.StartAt.UTC()) ||
		!input.EndAt.UTC().Equal(event.EndAt.UTC()) ||
		input.IsAllDay != event.IsAllDay ||
		strings.TrimSpace(input.Memo) != event.Memo ||
		input.Kind != event.Kind ||
		input.ColorValue != event.ColorValue ||
		input.Ownership != event.Ownership ||
		!sameReminderOffset(input.ReminderOffsetMinutes, event.Reminders) ||
		!sameLinkedItems(input.LinkedItems, event.LinkedItems) {
		return false
	}
	return watcherChangeIsOnlyForUser(
		event.WatcherUserIDs,
		input.WatcherUserIDs,
		input.UserID,
	)
}

func sameReminderOffset(offset *int, reminders []Reminder) bool {
	if len(reminders) == 0 {
		return offset == nil
	}
	return offset != nil && *offset == reminders[0].OffsetMinutes
}

func watcherChangeIsOnlyForUser(before []string, after []string, userID string) bool {
	beforeSet := stringSet(before)
	afterSet := stringSet(after)
	for id := range beforeSet {
		if id == userID {
			continue
		}
		if !afterSet[id] {
			return false
		}
	}
	for id := range afterSet {
		if id == userID {
			continue
		}
		if !beforeSet[id] {
			return false
		}
	}
	return beforeSet[userID] != afterSet[userID]
}

func stringSet(values []string) map[string]bool {
	set := map[string]bool{}
	for _, value := range values {
		set[value] = true
	}
	return set
}

func sameLinkedItems(left []LinkedItem, right []LinkedItem) bool {
	if len(left) != len(right) {
		return false
	}
	for index := range left {
		if !sameLinkedItem(left[index], right[index]) {
			return false
		}
	}
	return true
}

func sameLinkedItem(left LinkedItem, right LinkedItem) bool {
	return left.Type == right.Type &&
		left.TargetID == right.TargetID &&
		left.TargetPath == right.TargetPath &&
		left.Title == right.Title &&
		left.Subtitle == right.Subtitle &&
		sameOptionalTime(left.Date, right.Date) &&
		left.ThumbnailURL == right.ThumbnailURL &&
		left.Preview == right.Preview &&
		left.Emoji == right.Emoji &&
		left.CreatedAt.UTC().Equal(right.CreatedAt.UTC())
}

func sameOptionalTime(left *time.Time, right *time.Time) bool {
	if left == nil || right == nil {
		return left == nil && right == nil
	}
	return left.UTC().Equal(right.UTC())
}

func (s EventService) Delete(ctx context.Context, coupleID string, eventID string, userID string) error {
	if coupleID == "" || eventID == "" || userID == "" {
		return ErrInvalidEvent
	}
	event, err := s.repository.Get(ctx, coupleID, eventID)
	if err != nil {
		return err
	}
	if !event.CanEdit(userID) {
		return ErrForbidden
	}
	return s.repository.Delete(ctx, coupleID, eventID, s.clock.Now())
}

func buildReminders(eventID string, startAt time.Time, offsetMinutes *int, now time.Time) []Reminder {
	if offsetMinutes == nil {
		return []Reminder{}
	}
	return []Reminder{{
		ID:            "reminder-" + eventID,
		EventID:       eventID,
		RemindAt:      startAt.Add(-time.Duration(*offsetMinutes) * time.Minute),
		OffsetMinutes: *offsetMinutes,
		Enabled:       true,
		CreatedAt:     now,
		UpdatedAt:     now,
	}}
}
