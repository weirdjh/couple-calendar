package calendar

import (
	"context"
	"errors"
	"time"

	"cloud.google.com/go/firestore"
	firestoretransaction "couple-calendar-api/internal/adapters/persistence/firestore/transaction"
	"couple-calendar-api/internal/application/calendar"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type CalendarEventRepository struct {
	client *firestore.Client
}

func NewCalendarEventRepository(client *firestore.Client) CalendarEventRepository {
	return CalendarEventRepository{client: client}
}

func (r CalendarEventRepository) List(ctx context.Context, coupleID string, visibleStart time.Time, visibleEnd time.Time) ([]calendar.Event, error) {
	iter := r.events(coupleID).
		Where("deletedAt", "==", nil).
		Where("rangeStartAt", "<", visibleEnd.UTC()).
		Documents(ctx)
	defer iter.Stop()

	events := []calendar.Event{}
	for {
		doc, err := iter.Next()
		if errors.Is(err, iterator.Done) {
			break
		}
		if err != nil {
			return nil, err
		}
		event, err := eventFromDocument(doc)
		if err != nil {
			return nil, err
		}
		if !event.EndAt.UTC().Before(visibleStart.UTC()) {
			events = append(events, event)
		}
	}
	return events, nil
}

func (r CalendarEventRepository) Create(ctx context.Context, event calendar.Event) (calendar.Event, error) {
	err := firestoretransaction.Set(ctx, r.events(event.CoupleID).Doc(event.ID), eventToDocument(event))
	if err != nil {
		return calendar.Event{}, err
	}
	return event, nil
}

func (r CalendarEventRepository) Get(ctx context.Context, coupleID string, eventID string) (calendar.Event, error) {
	doc, err := r.events(coupleID).Doc(eventID).Get(ctx)
	if status.Code(err) == codes.NotFound {
		return calendar.Event{}, calendar.ErrEventNotFound
	}
	if err != nil {
		return calendar.Event{}, err
	}
	event, err := eventFromDocument(doc)
	if err != nil {
		return calendar.Event{}, err
	}
	if event.DeletedAt != nil {
		return calendar.Event{}, calendar.ErrEventNotFound
	}
	return event, nil
}

func (r CalendarEventRepository) Update(ctx context.Context, event calendar.Event) (calendar.Event, error) {
	err := firestoretransaction.Set(ctx, r.events(event.CoupleID).Doc(event.ID), eventToDocument(event))
	if err != nil {
		return calendar.Event{}, err
	}
	return event, nil
}

func (r CalendarEventRepository) Delete(ctx context.Context, coupleID string, eventID string, deletedAt time.Time) error {
	err := firestoretransaction.Update(ctx, r.events(coupleID).Doc(eventID), []firestore.Update{
		{Path: "deletedAt", Value: deletedAt.UTC()},
		{Path: "updatedAt", Value: deletedAt.UTC()},
	})
	if status.Code(err) == codes.NotFound {
		return calendar.ErrEventNotFound
	}
	return err
}

func (r CalendarEventRepository) events(coupleID string) *firestore.CollectionRef {
	return r.client.Collection("couples").Doc(coupleID).Collection("events")
}

func eventFromDocument(doc *firestore.DocumentSnapshot) (calendar.Event, error) {
	var stored eventDocument
	if err := doc.DataTo(&stored); err != nil {
		return calendar.Event{}, err
	}
	event := calendar.Event{
		ID:             doc.Ref.ID,
		CoupleID:       stored.CoupleID,
		Title:          stored.Title,
		StartAt:        stored.StartAt,
		EndAt:          stored.EndAt,
		IsAllDay:       stored.IsAllDay,
		Memo:           stored.Memo,
		Kind:           calendar.EventKind(stored.Kind),
		ColorValue:     stored.ColorValue,
		Ownership:      calendar.EventOwnership(stored.Ownership),
		OwnerUserID:    stored.OwnerUserID,
		WatcherUserIDs: stored.WatcherUserIDs,
		Reminders:      remindersFromDocuments(stored.Reminders),
		LinkedItems:    linkedItemsFromDocuments(stored.LinkedItems),
		CreatedBy:      stored.CreatedBy,
		CreatedAt:      stored.CreatedAt,
		UpdatedAt:      stored.UpdatedAt,
		DeletedAt:      stored.DeletedAt,
	}
	if event.Kind == "" {
		event.Kind = calendar.EventKindSchedule
	}
	if event.Ownership == "" {
		event.Ownership = calendar.EventOwnershipPersonal
	}
	if event.WatcherUserIDs == nil {
		event.WatcherUserIDs = []string{}
	}
	if event.Reminders == nil {
		event.Reminders = []calendar.Reminder{}
	}
	if event.LinkedItems == nil {
		event.LinkedItems = []calendar.LinkedItem{}
	}
	return event, nil
}

func eventToDocument(event calendar.Event) eventDocument {
	return eventDocument{
		CoupleID:       event.CoupleID,
		Title:          event.Title,
		StartAt:        event.StartAt.UTC(),
		EndAt:          event.EndAt.UTC(),
		RangeStartAt:   event.StartAt.UTC(),
		RangeEndAt:     event.EndAt.UTC(),
		IsAllDay:       event.IsAllDay,
		Memo:           event.Memo,
		Kind:           string(event.Kind),
		ColorValue:     event.ColorValue,
		Ownership:      string(event.Ownership),
		OwnerUserID:    event.OwnerUserID,
		WatcherUserIDs: event.WatcherUserIDs,
		Reminders:      remindersToDocuments(event.Reminders),
		LinkedItems:    linkedItemsToDocuments(event.LinkedItems),
		CreatedBy:      event.CreatedBy,
		CreatedAt:      event.CreatedAt.UTC(),
		UpdatedAt:      event.UpdatedAt.UTC(),
		DeletedAt:      event.DeletedAt,
	}
}

type eventDocument struct {
	CoupleID       string               `firestore:"coupleId"`
	Title          string               `firestore:"title"`
	StartAt        time.Time            `firestore:"startAt"`
	EndAt          time.Time            `firestore:"endAt"`
	RangeStartAt   time.Time            `firestore:"rangeStartAt"`
	RangeEndAt     time.Time            `firestore:"rangeEndAt"`
	IsAllDay       bool                 `firestore:"isAllDay"`
	Memo           string               `firestore:"memo"`
	Kind           string               `firestore:"kind"`
	ColorValue     int                  `firestore:"colorValue"`
	Ownership      string               `firestore:"ownership"`
	OwnerUserID    string               `firestore:"ownerUserId"`
	WatcherUserIDs []string             `firestore:"watcherUserIds"`
	Reminders      []reminderDocument   `firestore:"reminders"`
	LinkedItems    []linkedItemDocument `firestore:"linkedItems"`
	CreatedBy      string               `firestore:"createdBy"`
	CreatedAt      time.Time            `firestore:"createdAt"`
	UpdatedAt      time.Time            `firestore:"updatedAt"`
	DeletedAt      *time.Time           `firestore:"deletedAt"`
}

type reminderDocument struct {
	ID            string    `firestore:"id"`
	EventID       string    `firestore:"eventId"`
	RemindAt      time.Time `firestore:"remindAt"`
	OffsetMinutes int       `firestore:"offsetMinutes"`
	Enabled       bool      `firestore:"enabled"`
	CreatedAt     time.Time `firestore:"createdAt"`
	UpdatedAt     time.Time `firestore:"updatedAt"`
}

type linkedItemDocument struct {
	Type         string     `firestore:"type"`
	TargetID     string     `firestore:"targetId"`
	TargetPath   string     `firestore:"targetPath,omitempty"`
	Title        string     `firestore:"title"`
	Subtitle     string     `firestore:"subtitle,omitempty"`
	Date         *time.Time `firestore:"date,omitempty"`
	ThumbnailURL string     `firestore:"thumbnailUrl,omitempty"`
	Preview      string     `firestore:"preview,omitempty"`
	Emoji        string     `firestore:"emoji,omitempty"`
	CreatedAt    time.Time  `firestore:"createdAt"`
}

func remindersFromDocuments(documents []reminderDocument) []calendar.Reminder {
	reminders := make([]calendar.Reminder, 0, len(documents))
	for _, document := range documents {
		reminders = append(reminders, calendar.Reminder{
			ID:            document.ID,
			EventID:       document.EventID,
			RemindAt:      document.RemindAt,
			OffsetMinutes: document.OffsetMinutes,
			Enabled:       document.Enabled,
			CreatedAt:     document.CreatedAt,
			UpdatedAt:     document.UpdatedAt,
		})
	}
	return reminders
}

func remindersToDocuments(reminders []calendar.Reminder) []reminderDocument {
	documents := make([]reminderDocument, 0, len(reminders))
	for _, reminder := range reminders {
		documents = append(documents, reminderDocument{
			ID:            reminder.ID,
			EventID:       reminder.EventID,
			RemindAt:      reminder.RemindAt.UTC(),
			OffsetMinutes: reminder.OffsetMinutes,
			Enabled:       reminder.Enabled,
			CreatedAt:     reminder.CreatedAt.UTC(),
			UpdatedAt:     reminder.UpdatedAt.UTC(),
		})
	}
	return documents
}

func linkedItemsFromDocuments(documents []linkedItemDocument) []calendar.LinkedItem {
	items := make([]calendar.LinkedItem, 0, len(documents))
	for _, document := range documents {
		items = append(items, calendar.LinkedItem{
			Type:         document.Type,
			TargetID:     document.TargetID,
			TargetPath:   document.TargetPath,
			Title:        document.Title,
			Subtitle:     document.Subtitle,
			Date:         document.Date,
			ThumbnailURL: document.ThumbnailURL,
			Preview:      document.Preview,
			Emoji:        document.Emoji,
			CreatedAt:    document.CreatedAt,
		})
	}
	return items
}

func linkedItemsToDocuments(items []calendar.LinkedItem) []linkedItemDocument {
	documents := make([]linkedItemDocument, 0, len(items))
	for _, item := range items {
		documents = append(documents, linkedItemDocument{
			Type:         item.Type,
			TargetID:     item.TargetID,
			TargetPath:   item.TargetPath,
			Title:        item.Title,
			Subtitle:     item.Subtitle,
			Date:         item.Date,
			ThumbnailURL: item.ThumbnailURL,
			Preview:      item.Preview,
			Emoji:        item.Emoji,
			CreatedAt:    item.CreatedAt.UTC(),
		})
	}
	return documents
}
