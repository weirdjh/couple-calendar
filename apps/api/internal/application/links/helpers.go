package links

import (
	"context"
	"strings"
	"time"

	appcalendar "couple-calendar-api/internal/application/calendar"
	appdaterecords "couple-calendar-api/internal/application/daterecords"
	appreviews "couple-calendar-api/internal/application/reviews"
	apptodos "couple-calendar-api/internal/application/todos"
	domainlinks "couple-calendar-api/internal/domain/links"
)

func (s Service) replaceEventLinks(ctx context.Context, coupleID, userID string, event appcalendar.Event, links []domainlinks.LinkedItem, kind appcalendar.EventKind) error {
	if kind == "" {
		kind = event.Kind
	}
	_, err := s.eventEditor.Update(ctx, appcalendar.UpdateEventInput{
		CoupleID:              coupleID,
		EventID:               event.ID,
		UserID:                userID,
		Title:                 event.Title,
		StartAt:               event.StartAt,
		EndAt:                 event.EndAt,
		IsAllDay:              event.IsAllDay,
		Memo:                  event.Memo,
		Kind:                  kind,
		ColorValue:            event.ColorValue,
		Ownership:             event.Ownership,
		WatcherUserIDs:        event.WatcherUserIDs,
		LinkedItems:           links,
		ReminderOffsetMinutes: reminderOffset(event),
	})
	return err
}

func reminderOffset(event appcalendar.Event) *int {
	if len(event.Reminders) == 0 {
		return nil
	}
	offset := event.Reminders[0].OffsetMinutes
	return &offset
}

func firstDateRecordID(items []domainlinks.LinkedItem) string {
	for _, item := range items {
		if item.Type == "dateRecord" {
			return dateRecordIDForLinkedItem(item)
		}
	}
	return ""
}

func dateRecordIDForLinkedItem(item domainlinks.LinkedItem) string {
	if item.TargetID != "" {
		return item.TargetID
	}
	return strings.TrimPrefix(item.TargetPath, "/date-records/")
}

func nestedDateRecordLinks(event appcalendar.Event) []domainlinks.LinkedItem {
	result := []domainlinks.LinkedItem{}
	for _, item := range event.LinkedItems {
		if item.Type == "todo" || item.Type == "review" {
			result = append(result, item)
		}
	}
	return result
}

func withoutNestedLinks(items []domainlinks.LinkedItem, nested []domainlinks.LinkedItem) []domainlinks.LinkedItem {
	result := []domainlinks.LinkedItem{}
	for _, item := range items {
		if containsLink(nested, item.Type, item.TargetID) {
			continue
		}
		result = append(result, item)
	}
	return result
}

func withLinkedItem(items []domainlinks.LinkedItem, item domainlinks.LinkedItem) []domainlinks.LinkedItem {
	return append(removeLink(items, item.Type, item.TargetID), item)
}

func removeLink(items []domainlinks.LinkedItem, linkType, targetID string) []domainlinks.LinkedItem {
	result := make([]domainlinks.LinkedItem, 0, len(items))
	for _, item := range items {
		if item.Type == linkType && item.TargetID == targetID {
			continue
		}
		result = append(result, item)
	}
	return result
}

func containsLink(items []domainlinks.LinkedItem, linkType, targetID string) bool {
	for _, item := range items {
		if item.Type == linkType && item.TargetID == targetID {
			return true
		}
	}
	return false
}

func linkedItemForDateRecord(record appdaterecords.DateRecord, emoji string) domainlinks.LinkedItem {
	return domainlinks.LinkedItem{
		Type:       "dateRecord",
		TargetID:   record.ID,
		TargetPath: "/date-records/" + record.ID,
		Title:      record.Title,
		Date:       &record.Date,
		Preview:    "데이트 기록",
		Emoji:      emoji,
		CreatedAt:  nonZeroTime(record.CreatedAt),
	}
}

func linkedItemForTodoCompletion(item apptodos.Item, completion apptodos.Completion, category apptodos.Category) domainlinks.LinkedItem {
	subtitle := item.Note
	emoji := ""
	if category.ID != "" {
		subtitle = category.Title
		emoji = category.Emoji
	}
	return domainlinks.LinkedItem{
		Type:       "todo",
		TargetID:   completion.ID,
		TargetPath: "/todos/" + item.ID + "/completions/" + completion.ID,
		Title:      item.Title,
		Subtitle:   subtitle,
		Date:       &completion.CompletedAt,
		Preview:    "버킷리스트 달성",
		Emoji:      emoji,
		CreatedAt:  completion.CreatedAt,
	}
}

func linkedItemForReview(review appreviews.Review) domainlinks.LinkedItem {
	return domainlinks.LinkedItem{
		Type:         "review",
		TargetID:     review.ID,
		TargetPath:   "/reviews/" + review.ID,
		Title:        review.Title,
		Subtitle:     review.Type,
		ThumbnailURL: firstReviewPhotoURL(review.Photos),
		Preview:      "리뷰",
		Emoji:        "⭐",
		CreatedAt:    review.CreatedAt,
	}
}

func firstReviewPhotoURL(photos []appreviews.PhotoAttachment) string {
	for _, photo := range photos {
		if photo.DownloadURL != "" {
			return photo.DownloadURL
		}
	}
	return ""
}

func firstEmoji(items []domainlinks.LinkedItem) string {
	for _, item := range items {
		if item.Emoji != "" {
			return item.Emoji
		}
	}
	return ""
}

func findTodoItem(items []apptodos.Item, itemID string) (apptodos.Item, bool) {
	for _, item := range items {
		if item.ID == itemID {
			return item, true
		}
	}
	return apptodos.Item{}, false
}

func findTodoCategory(categories []apptodos.Category, categoryID string) (apptodos.Category, bool) {
	for _, category := range categories {
		if category.ID == categoryID {
			return category, true
		}
	}
	return apptodos.Category{}, false
}

func dateOnly(value time.Time) time.Time {
	local := value.UTC()
	return time.Date(local.Year(), local.Month(), local.Day(), 0, 0, 0, 0, time.UTC)
}

func nonZeroTime(value time.Time) time.Time {
	if value.IsZero() {
		return time.Now().UTC()
	}
	return value
}
