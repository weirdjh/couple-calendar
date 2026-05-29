package links

import (
	"context"
	"time"

	apptodos "couple-calendar-api/internal/application/todos"
	domainlinks "couple-calendar-api/internal/domain/links"
)

func (s Service) CompleteTodoItemForEvent(ctx context.Context, coupleID, userID, itemID, eventID string) (TodoCompletionResult, error) {
	if coupleID == "" || userID == "" || itemID == "" || eventID == "" {
		return TodoCompletionResult{}, apptodos.ErrInvalidTodo
	}
	if err := s.requireMember(ctx, coupleID, userID); err != nil {
		return TodoCompletionResult{}, err
	}
	event, err := s.events.Get(ctx, coupleID, eventID)
	if err != nil {
		return TodoCompletionResult{}, err
	}
	snapshot, err := s.todos.Fetch(ctx, coupleID)
	if err != nil {
		return TodoCompletionResult{}, err
	}
	item, ok := findTodoItem(snapshot.Items, itemID)
	if !ok {
		return TodoCompletionResult{}, apptodos.ErrTodoNotFound
	}
	category, _ := findTodoCategory(snapshot.Categories, item.CategoryID)
	now := s.clock.Now()
	completion := apptodos.Completion{
		ID:              s.ids.NewID("todo-done"),
		CoupleID:        coupleID,
		ItemID:          item.ID,
		CompletedAt:     dateOnly(event.StartAt),
		CompletedBy:     userID,
		CalendarEventID: event.ID,
		CreatedAt:       now,
	}
	completion, err = s.todos.CreateCompletion(ctx, completion)
	if err != nil {
		return TodoCompletionResult{}, err
	}
	linkedItem := linkedItemForTodoCompletion(item, completion, category)
	recordResult, err := s.EnsureDateRecordForEvent(ctx, coupleID, userID, eventID)
	if err != nil {
		return TodoCompletionResult{}, err
	}
	record := recordResult.Record
	record.LinkedItems = withLinkedItem(record.LinkedItems, linkedItem)
	record.UpdatedAt = now
	if _, err := s.records.Update(ctx, record); err != nil {
		return TodoCompletionResult{}, err
	}
	return TodoCompletionResult{Completion: completion, LinkedItem: linkedItem, DateRecordID: record.ID}, nil
}

func (s Service) RemoveCalendarEventLinkedItem(ctx context.Context, coupleID, userID, eventID string, item domainlinks.LinkedItem) error {
	if coupleID == "" || userID == "" || eventID == "" || item.Type == "" || item.TargetID == "" {
		return apptodos.ErrInvalidTodo
	}
	if err := s.requireMember(ctx, coupleID, userID); err != nil {
		return err
	}
	event, err := s.events.Get(ctx, coupleID, eventID)
	if err != nil {
		return err
	}
	if err := s.replaceEventLinks(ctx, coupleID, userID, event, removeLink(event.LinkedItems, item.Type, item.TargetID), event.Kind); err != nil {
		return err
	}
	switch item.Type {
	case "todo":
		return s.RemoveTodoCompletionEverywhere(ctx, coupleID, userID, item.TargetID)
	case "dateRecord":
		recordID := dateRecordIDForLinkedItem(item)
		if recordID == "" {
			return nil
		}
		_, err := s.UnlinkRecordFromEvent(ctx, coupleID, userID, recordID, eventID)
		return err
	default:
		return nil
	}
}

func (s Service) RemoveTodoCompletionEverywhere(ctx context.Context, coupleID, userID, completionID string) error {
	if coupleID == "" || userID == "" || completionID == "" {
		return apptodos.ErrInvalidTodo
	}
	if err := s.requireMember(ctx, coupleID, userID); err != nil {
		return err
	}
	records, err := s.records.List(ctx, coupleID)
	if err != nil {
		return err
	}
	for _, record := range records {
		next := removeLink(record.LinkedItems, "todo", completionID)
		if len(next) == len(record.LinkedItems) {
			continue
		}
		record.LinkedItems = next
		record.UpdatedAt = s.clock.Now()
		if _, err := s.records.Update(ctx, record); err != nil {
			return err
		}
	}
	events, err := s.events.List(ctx, coupleID, time.Date(1900, 1, 1, 0, 0, 0, 0, time.UTC), time.Date(2200, 1, 1, 0, 0, 0, 0, time.UTC))
	if err != nil {
		return err
	}
	for _, event := range events {
		next := removeLink(event.LinkedItems, "todo", completionID)
		if len(next) == len(event.LinkedItems) {
			continue
		}
		if err := s.replaceEventLinks(ctx, coupleID, userID, event, next, event.Kind); err != nil {
			return err
		}
	}
	return s.todos.DeleteCompletion(ctx, coupleID, completionID, s.clock.Now())
}
