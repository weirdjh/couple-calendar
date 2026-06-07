package links

import (
	"context"
	"strings"
	"time"

	appcalendar "couple-calendar-api/internal/application/calendar"
	appdaterecords "couple-calendar-api/internal/application/daterecords"
	appreviews "couple-calendar-api/internal/application/reviews"
)

func (s Service) EnsureDateRecordForEvent(ctx context.Context, coupleID, userID, eventID string) (DateRecordResult, error) {
	if coupleID == "" || userID == "" || eventID == "" {
		return DateRecordResult{}, appdaterecords.ErrInvalidDateRecord
	}
	if err := s.requireMember(ctx, coupleID, userID); err != nil {
		return DateRecordResult{}, err
	}
	event, err := s.events.Get(ctx, coupleID, eventID)
	if err != nil {
		return DateRecordResult{}, err
	}
	if recordID := firstDateRecordID(event.LinkedItems); recordID != "" {
		record, err := s.records.Get(ctx, coupleID, recordID)
		if err == nil {
			return DateRecordResult{Record: record, RecordID: record.ID}, nil
		}
	}
	record, err := s.createRecordFromEvent(ctx, coupleID, userID, event, nestedDateRecordLinks(event))
	if err != nil {
		return DateRecordResult{}, err
	}
	links := withLinkedItem(event.LinkedItems, linkedItemForDateRecord(record, firstEmoji(record.LinkedItems)))
	if err := s.replaceEventLinks(ctx, coupleID, userID, event, links, appcalendar.EventKindDate); err != nil {
		return DateRecordResult{}, err
	}
	return DateRecordResult{Record: record, RecordID: record.ID}, nil
}

func (s Service) CreateDateRecordFromEvent(ctx context.Context, coupleID, userID, eventID string) (DateRecordResult, error) {
	if coupleID == "" || userID == "" || eventID == "" {
		return DateRecordResult{}, appdaterecords.ErrInvalidDateRecord
	}
	if err := s.requireMember(ctx, coupleID, userID); err != nil {
		return DateRecordResult{}, err
	}
	event, err := s.events.Get(ctx, coupleID, eventID)
	if err != nil {
		return DateRecordResult{}, err
	}
	nestedLinks := nestedDateRecordLinks(event)
	record, err := s.createRecordFromEvent(ctx, coupleID, userID, event, nestedLinks)
	if err != nil {
		return DateRecordResult{}, err
	}
	links := withoutNestedLinks(event.LinkedItems, nestedLinks)
	links = withLinkedItem(links, linkedItemForDateRecord(record, firstEmoji(nestedLinks)))
	if err := s.replaceEventLinks(ctx, coupleID, userID, event, links, appcalendar.EventKindDate); err != nil {
		return DateRecordResult{}, err
	}
	return DateRecordResult{Record: record, RecordID: record.ID}, nil
}

func (s Service) LinkRecordToEvent(ctx context.Context, coupleID, userID, recordID, eventID string) (DateRecordResult, error) {
	if coupleID == "" || userID == "" || recordID == "" || eventID == "" {
		return DateRecordResult{}, appdaterecords.ErrInvalidDateRecord
	}
	if err := s.requireMember(ctx, coupleID, userID); err != nil {
		return DateRecordResult{}, err
	}
	record, err := s.records.Get(ctx, coupleID, recordID)
	if err != nil {
		return DateRecordResult{}, err
	}
	if record.LinkedEventID != nil && *record.LinkedEventID != eventID {
		if _, err := s.UnlinkRecordFromEvent(ctx, coupleID, userID, recordID, *record.LinkedEventID); err != nil {
			return DateRecordResult{}, err
		}
		record, err = s.records.Get(ctx, coupleID, recordID)
		if err != nil {
			return DateRecordResult{}, err
		}
	}
	event, err := s.events.Get(ctx, coupleID, eventID)
	if err != nil {
		return DateRecordResult{}, err
	}
	record.LinkedEventID = &eventID
	record.UpdatedAt = s.clock.Now()
	record, err = s.records.Update(ctx, record)
	if err != nil {
		return DateRecordResult{}, err
	}
	event.Title = record.Title
	event.StartAt = record.Date
	event.EndAt = record.Date.AddDate(0, 0, 1)
	event.IsAllDay = true
	event.Memo = record.Memo
	links := withLinkedItem(
		removeLink(event.LinkedItems, "dateRecord", record.ID),
		linkedItemForDateRecord(record, firstEmoji(record.LinkedItems)),
	)
	if err := s.replaceEventLinks(ctx, coupleID, userID, event, links, appcalendar.EventKindDate); err != nil {
		return DateRecordResult{}, err
	}
	return DateRecordResult{Record: record, RecordID: record.ID}, nil
}

func (s Service) UnlinkRecordFromEvent(ctx context.Context, coupleID, userID, recordID, eventID string) (DateRecordResult, error) {
	if coupleID == "" || userID == "" || recordID == "" || eventID == "" {
		return DateRecordResult{}, appdaterecords.ErrInvalidDateRecord
	}
	if err := s.requireMember(ctx, coupleID, userID); err != nil {
		return DateRecordResult{}, err
	}
	record, err := s.records.Get(ctx, coupleID, recordID)
	if err != nil {
		return DateRecordResult{}, err
	}
	event, err := s.events.Get(ctx, coupleID, eventID)
	if err == nil {
		if err := s.replaceEventLinks(ctx, coupleID, userID, event, removeLink(event.LinkedItems, "dateRecord", recordID), event.Kind); err != nil {
			return DateRecordResult{}, err
		}
	}
	if record.LinkedEventID != nil && *record.LinkedEventID == eventID {
		record.LinkedEventID = nil
		record.UpdatedAt = s.clock.Now()
		record, err = s.records.Update(ctx, record)
		if err != nil {
			return DateRecordResult{}, err
		}
	}
	return DateRecordResult{Record: record, RecordID: record.ID}, nil
}

func (s Service) DeleteDateRecordEverywhere(ctx context.Context, coupleID, userID, recordID string) error {
	if coupleID == "" || userID == "" || recordID == "" {
		return appdaterecords.ErrInvalidDateRecord
	}
	if err := s.requireMember(ctx, coupleID, userID); err != nil {
		return err
	}
	record, err := s.records.Get(ctx, coupleID, recordID)
	if err != nil {
		return err
	}

	now := s.clock.Now()
	completionIDs := map[string]struct{}{}
	reviewIDs := map[string]struct{}{}
	for _, item := range record.LinkedItems {
		switch item.Type {
		case "review":
			reviewIDs[item.TargetID] = struct{}{}
		case "todo":
			completionIDs[item.TargetID] = struct{}{}
		}
	}

	reviewUpdates := map[string]appreviews.Review{}
	reviews, err := s.reviews.List(ctx, coupleID)
	if err != nil {
		return err
	}
	for _, review := range reviews {
		_, linkedByItem := reviewIDs[review.ID]
		linkedByRecord := review.DateRecordID != nil && *review.DateRecordID == recordID
		if !linkedByItem && !linkedByRecord {
			continue
		}
		review.DateRecordID = nil
		review.UpdatedAt = now
		reviewUpdates[review.ID] = review
	}

	recordUpdates := map[string]appdaterecords.DateRecord{}
	eventUpdates := map[string]appcalendar.Event{}
	if len(completionIDs) > 0 {
		records, err := s.records.List(ctx, coupleID)
		if err != nil {
			return err
		}
		for _, otherRecord := range records {
			if otherRecord.ID == recordID {
				continue
			}
			next := removeTargets(otherRecord.LinkedItems, "todo", completionIDs)
			if len(next) == len(otherRecord.LinkedItems) {
				continue
			}
			otherRecord.LinkedItems = next
			otherRecord.UpdatedAt = now
			recordUpdates[otherRecord.ID] = otherRecord
		}

		events, err := s.events.List(
			ctx,
			coupleID,
			time.Date(1900, 1, 1, 0, 0, 0, 0, time.UTC),
			time.Date(2200, 1, 1, 0, 0, 0, 0, time.UTC),
		)
		if err != nil {
			return err
		}
		for _, event := range events {
			next := removeTargets(event.LinkedItems, "todo", completionIDs)
			if len(next) == len(event.LinkedItems) {
				continue
			}
			event.LinkedItems = next
			eventUpdates[event.ID] = event
		}
	}

	if record.LinkedEventID != nil {
		event, err := s.events.Get(ctx, coupleID, *record.LinkedEventID)
		if err == nil {
			if pending, ok := eventUpdates[event.ID]; ok {
				event = pending
			}
			event.LinkedItems = removeLink(event.LinkedItems, "dateRecord", record.ID)
			event.Kind = appcalendar.EventKindSchedule
			eventUpdates[event.ID] = event
		}
	}

	return s.transactions.Run(ctx, func(txCtx context.Context) error {
		for _, review := range reviewUpdates {
			if _, err := s.reviews.Update(txCtx, review); err != nil {
				return err
			}
		}
		for _, otherRecord := range recordUpdates {
			if _, err := s.records.Update(txCtx, otherRecord); err != nil {
				return err
			}
		}
		for _, event := range eventUpdates {
			if err := s.replaceEventLinks(txCtx, coupleID, userID, event, event.LinkedItems, event.Kind); err != nil {
				return err
			}
		}
		for completionID := range completionIDs {
			if err := s.todos.DeleteCompletion(txCtx, coupleID, completionID, now); err != nil {
				return err
			}
		}
		return s.records.Delete(txCtx, coupleID, recordID, now)
	})
}

func (s Service) createRecordFromEvent(ctx context.Context, coupleID, userID string, event appcalendar.Event, linkedItems []appcalendar.LinkedItem) (appdaterecords.DateRecord, error) {
	now := s.clock.Now()
	eventID := event.ID
	return s.records.Create(ctx, appdaterecords.DateRecord{
		ID:            s.ids.NewID("date"),
		CoupleID:      coupleID,
		Title:         strings.TrimSpace(event.Title),
		Date:          dateOnly(event.StartAt),
		Memo:          strings.TrimSpace(event.Memo),
		Photos:        []appdaterecords.PhotoAttachment{},
		LinkedItems:   append([]appcalendar.LinkedItem{}, linkedItems...),
		LinkedEventID: &eventID,
		CreatedBy:     userID,
		CreatedAt:     now,
		UpdatedAt:     now,
	})
}
