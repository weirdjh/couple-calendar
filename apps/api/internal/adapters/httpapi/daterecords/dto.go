package daterecords

import (
	"time"

	appcalendar "couple-calendar-api/internal/application/calendar"
	appdaterecords "couple-calendar-api/internal/application/daterecords"
)

type dateRecordMutationRequest struct {
	UserID        string                           `json:"userId"`
	Title         string                           `json:"title"`
	Date          time.Time                        `json:"date"`
	Memo          string                           `json:"memo"`
	Place         *appdaterecords.PlaceSnapshot    `json:"place"`
	Photos        []appdaterecords.PhotoAttachment `json:"photos"`
	LinkedItems   []appcalendar.LinkedItem         `json:"linkedItems"`
	LinkedEventID *string                          `json:"linkedEventId"`
}

type calendarEventLinkRequest struct {
	UserID  string `json:"userId"`
	EventID string `json:"eventId"`
}

type linkedItemMutationRequest struct {
	UserID     string                 `json:"userId"`
	LinkedItem appcalendar.LinkedItem `json:"linkedItem"`
}
