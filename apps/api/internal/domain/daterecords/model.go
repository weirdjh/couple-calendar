package daterecords

import (
	"time"

	"couple-calendar-api/internal/domain/links"
)

type PlaceProvider string

const (
	PlaceProviderManual     PlaceProvider = "manual"
	PlaceProviderGoogleMaps PlaceProvider = "googleMaps"
	PlaceProviderNaverMaps  PlaceProvider = "naverMaps"
)

type PlaceSnapshot struct {
	Provider        PlaceProvider `json:"provider"`
	Name            string        `json:"name"`
	ProviderPlaceID string        `json:"providerPlaceId,omitempty"`
	Address         string        `json:"address,omitempty"`
	Latitude        *float64      `json:"latitude,omitempty"`
	Longitude       *float64      `json:"longitude,omitempty"`
	URL             string        `json:"url,omitempty"`
}

type PhotoAttachment struct {
	ID          string     `json:"id"`
	Label       string     `json:"label"`
	StoragePath string     `json:"storagePath,omitempty"`
	DownloadURL string     `json:"downloadUrl,omitempty"`
	CreatedAt   *time.Time `json:"createdAt,omitempty"`
}

type DateRecord struct {
	ID            string             `json:"id"`
	CoupleID      string             `json:"coupleId"`
	Title         string             `json:"title"`
	Date          time.Time          `json:"date"`
	Memo          string             `json:"memo"`
	Place         *PlaceSnapshot     `json:"place,omitempty"`
	Photos        []PhotoAttachment  `json:"photos"`
	LinkedItems   []links.LinkedItem `json:"linkedItems"`
	LinkedEventID *string            `json:"linkedEventId,omitempty"`
	CreatedBy     string             `json:"createdBy"`
	CreatedAt     time.Time          `json:"createdAt"`
	UpdatedAt     time.Time          `json:"updatedAt"`
	DeletedAt     *time.Time         `json:"deletedAt,omitempty"`
}
