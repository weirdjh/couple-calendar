package links

import "time"

type LinkedItem struct {
	Type         string     `json:"type"`
	TargetID     string     `json:"targetId"`
	TargetPath   string     `json:"targetPath,omitempty"`
	Title        string     `json:"title"`
	Subtitle     string     `json:"subtitle,omitempty"`
	Date         *time.Time `json:"date,omitempty"`
	ThumbnailURL string     `json:"thumbnailUrl,omitempty"`
	Preview      string     `json:"preview,omitempty"`
	Emoji        string     `json:"emoji,omitempty"`
	CreatedAt    time.Time  `json:"createdAt"`
}
