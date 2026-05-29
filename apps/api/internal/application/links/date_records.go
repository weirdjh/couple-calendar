package links

import (
	"context"
	"strings"

	appcalendar "couple-calendar-api/internal/application/calendar"
	appdaterecords "couple-calendar-api/internal/application/daterecords"
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
	if record.LinkedEventID != nil {
		event, err := s.events.Get(ctx, coupleID, *record.LinkedEventID)
		if err == nil {
			links := removeLink(event.LinkedItems, "dateRecord", record.ID)
			if err := s.replaceEventLinks(ctx, coupleID, userID, event, links, appcalendar.EventKindSchedule); err != nil {
				return err
			}
		}
	}
	for _, item := range record.LinkedItems {
		switch item.Type {
		case "review":
			review, err := s.reviews.Get(ctx, coupleID, item.TargetID)
			if err != nil {
				return err
			}
			if review.DateRecordID != nil && *review.DateRecordID == recordID {
				review.DateRecordID = nil
				review.UpdatedAt = s.clock.Now()
				if _, err := s.reviews.Update(ctx, review); err != nil {
					return err
				}
			}
		case "todo":
			if err := s.RemoveTodoCompletionEverywhere(ctx, coupleID, userID, item.TargetID); err != nil {
				return err
			}
		}
	}
	reviews, err := s.reviews.List(ctx, coupleID)
	if err != nil {
		return err
	}
	for _, review := range reviews {
		if review.DateRecordID == nil || *review.DateRecordID != recordID {
			continue
		}
		review.DateRecordID = nil
		review.UpdatedAt = s.clock.Now()
		if _, err := s.reviews.Update(ctx, review); err != nil {
			return err
		}
	}
	return s.records.Delete(ctx, coupleID, recordID, s.clock.Now())
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
