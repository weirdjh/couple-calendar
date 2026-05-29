package calendar

import appcalendar "couple-calendar-api/internal/application/calendar"

func toCreateInput(coupleID string, userID string, body createEventRequest) appcalendar.CreateEventInput {
	return appcalendar.CreateEventInput{
		CoupleID:              coupleID,
		UserID:                userID,
		Title:                 body.Title,
		StartAt:               body.StartAt,
		EndAt:                 body.EndAt,
		IsAllDay:              body.IsAllDay,
		Memo:                  body.Memo,
		Kind:                  body.Kind,
		ColorValue:            body.ColorValue,
		Ownership:             body.Ownership,
		LinkedItems:           body.LinkedItems,
		ReminderOffsetMinutes: body.ReminderOffsetMinutes,
	}
}

func toUpdateInput(coupleID string, eventID string, userID string, body eventMutationRequest) appcalendar.UpdateEventInput {
	return appcalendar.UpdateEventInput{
		CoupleID:              coupleID,
		EventID:               eventID,
		UserID:                userID,
		Title:                 body.Title,
		StartAt:               body.StartAt,
		EndAt:                 body.EndAt,
		IsAllDay:              body.IsAllDay,
		Memo:                  body.Memo,
		Kind:                  body.Kind,
		ColorValue:            body.ColorValue,
		Ownership:             body.Ownership,
		WatcherUserIDs:        body.WatcherUserIDs,
		LinkedItems:           body.LinkedItems,
		ReminderOffsetMinutes: body.ReminderOffsetMinutes,
	}
}
