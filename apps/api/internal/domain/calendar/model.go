package calendar

import (
	"time"

	"couple-calendar-api/internal/domain/links"
)

type EventOwnership string

const (
	EventOwnershipPersonal EventOwnership = "personal"
	EventOwnershipShared   EventOwnership = "shared"
)

type EventKind string

const (
	EventKindSchedule EventKind = "schedule"
	EventKindDate     EventKind = "date"
)

type Reminder struct {
	ID            string    `json:"id"`
	EventID       string    `json:"eventId"`
	RemindAt      time.Time `json:"remindAt"`
	OffsetMinutes int       `json:"offsetMinutes"`
	Enabled       bool      `json:"enabled"`
	CreatedAt     time.Time `json:"createdAt"`
	UpdatedAt     time.Time `json:"updatedAt"`
}

type Event struct {
	ID             string             `json:"id"`
	CoupleID       string             `json:"coupleId"`
	Title          string             `json:"title"`
	StartAt        time.Time          `json:"startAt"`
	EndAt          time.Time          `json:"endAt"`
	IsAllDay       bool               `json:"isAllDay"`
	Memo           string             `json:"memo"`
	Kind           EventKind          `json:"kind"`
	ColorValue     int                `json:"colorValue"`
	Ownership      EventOwnership     `json:"ownership"`
	OwnerUserID    string             `json:"ownerUserId"`
	WatcherUserIDs []string           `json:"watcherUserIds"`
	Reminders      []Reminder         `json:"reminders"`
	LinkedItems    []links.LinkedItem `json:"linkedItems"`
	CreatedBy      string             `json:"createdBy"`
	CreatedAt      time.Time          `json:"createdAt"`
	UpdatedAt      time.Time          `json:"updatedAt"`
	DeletedAt      *time.Time         `json:"deletedAt,omitempty"`
}

func (e Event) CanEdit(userID string) bool {
	return e.Ownership == EventOwnershipShared ||
		(e.Ownership == EventOwnershipPersonal && e.OwnerUserID == userID)
}

func (e Event) IsWatchedBy(userID string) bool {
	for _, watcherID := range e.WatcherUserIDs {
		if watcherID == userID {
			return true
		}
	}
	return false
}
