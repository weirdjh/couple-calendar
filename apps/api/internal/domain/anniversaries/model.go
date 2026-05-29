package anniversaries

import "time"

type Anniversary struct {
	ID           string     `json:"id"`
	CoupleID     string     `json:"coupleId"`
	Title        string     `json:"title"`
	BaseDate     time.Time  `json:"baseDate"`
	RepeatRule   string     `json:"repeatRule"`
	CalendarType string     `json:"calendarType"`
	IsLeapMonth  bool       `json:"isLeapMonth"`
	CreatedBy    string     `json:"createdBy"`
	CreatedAt    time.Time  `json:"createdAt"`
	UpdatedAt    time.Time  `json:"updatedAt"`
	DeletedAt    *time.Time `json:"deletedAt,omitempty"`
}
