package reviews

import "time"

type PhotoAttachment struct {
	ID          string     `json:"id"`
	Label       string     `json:"label"`
	StoragePath string     `json:"storagePath,omitempty"`
	DownloadURL string     `json:"downloadUrl,omitempty"`
	CreatedAt   *time.Time `json:"createdAt,omitempty"`
}

type Review struct {
	ID           string            `json:"id"`
	CoupleID     string            `json:"coupleId"`
	Type         string            `json:"type"`
	Title        string            `json:"title"`
	Rating       float64           `json:"rating"`
	Memo         string            `json:"memo"`
	Photos       []PhotoAttachment `json:"photos"`
	DateRecordID *string           `json:"dateRecordId,omitempty"`
	CreatedBy    string            `json:"createdBy"`
	CreatedAt    time.Time         `json:"createdAt"`
	UpdatedAt    time.Time         `json:"updatedAt"`
	DeletedAt    *time.Time        `json:"deletedAt,omitempty"`
}
