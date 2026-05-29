package calendar

import (
	"time"

	appcalendar "couple-calendar-api/internal/application/calendar"
)

type eventMutationRequest struct {
	UserID                string                     `json:"userId"`
	Title                 string                     `json:"title"`
	StartAt               time.Time                  `json:"startAt"`
	EndAt                 time.Time                  `json:"endAt"`
	IsAllDay              bool                       `json:"isAllDay"`
	Memo                  string                     `json:"memo"`
	Kind                  appcalendar.EventKind      `json:"kind"`
	ColorValue            int                        `json:"colorValue"`
	Ownership             appcalendar.EventOwnership `json:"ownership"`
	WatcherUserIDs        []string                   `json:"watcherUserIds"`
	LinkedItems           []appcalendar.LinkedItem   `json:"linkedItems"`
	ReminderOffsetMinutes *int                       `json:"reminderOffsetMinutes"`
}

type createEventRequest = eventMutationRequest
