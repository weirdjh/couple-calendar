package daterecords

import (
	"context"
	"time"

	domain "couple-calendar-api/internal/domain/daterecords"
)

type DateRecord = domain.DateRecord
type PhotoAttachment = domain.PhotoAttachment
type PlaceProvider = domain.PlaceProvider
type PlaceSnapshot = domain.PlaceSnapshot

const (
	PlaceProviderManual     = domain.PlaceProviderManual
	PlaceProviderGoogleMaps = domain.PlaceProviderGoogleMaps
	PlaceProviderNaverMaps  = domain.PlaceProviderNaverMaps
)

var (
	ErrInvalidDateRecord  = domain.ErrInvalidDateRecord
	ErrDateRecordNotFound = domain.ErrDateRecordNotFound
)

type Repository interface {
	List(ctx context.Context, coupleID string) ([]DateRecord, error)
	Create(ctx context.Context, record DateRecord) (DateRecord, error)
	Get(ctx context.Context, coupleID string, recordID string) (DateRecord, error)
	Update(ctx context.Context, record DateRecord) (DateRecord, error)
	Delete(ctx context.Context, coupleID string, recordID string, deletedAt time.Time) error
}
