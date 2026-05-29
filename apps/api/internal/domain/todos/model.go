package todos

import "time"

type Category struct {
	ID        string     `json:"id"`
	CoupleID  string     `json:"coupleId"`
	Title     string     `json:"title"`
	Emoji     string     `json:"emoji"`
	CreatedBy string     `json:"createdBy"`
	CreatedAt time.Time  `json:"createdAt"`
	UpdatedAt time.Time  `json:"updatedAt"`
	DeletedAt *time.Time `json:"deletedAt,omitempty"`
}

type Item struct {
	ID         string     `json:"id"`
	CoupleID   string     `json:"coupleId"`
	CategoryID string     `json:"categoryId"`
	Title      string     `json:"title"`
	Note       string     `json:"note"`
	CreatedBy  string     `json:"createdBy"`
	CreatedAt  time.Time  `json:"createdAt"`
	UpdatedAt  time.Time  `json:"updatedAt"`
	DeletedAt  *time.Time `json:"deletedAt,omitempty"`
}

type Completion struct {
	ID              string     `json:"id"`
	CoupleID        string     `json:"coupleId"`
	ItemID          string     `json:"itemId"`
	CompletedAt     time.Time  `json:"completedAt"`
	CompletedBy     string     `json:"completedBy"`
	CalendarEventID string     `json:"calendarEventId"`
	Memo            string     `json:"memo"`
	CreatedAt       time.Time  `json:"createdAt"`
	DeletedAt       *time.Time `json:"deletedAt,omitempty"`
}

type Snapshot struct {
	Categories  []Category   `json:"categories"`
	Items       []Item       `json:"items"`
	Completions []Completion `json:"completions"`
}
