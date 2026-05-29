package anniversaries

import (
	"context"
	domain "couple-calendar-api/internal/domain/anniversaries"
	"time"
)

type Anniversary = domain.Anniversary

var ErrInvalidAnniversary = domain.ErrInvalidAnniversary

type Repository interface {
	List(ctx context.Context, coupleID string) ([]Anniversary, error)
	Create(ctx context.Context, anniversary Anniversary) (Anniversary, error)
	Update(ctx context.Context, anniversary Anniversary) (Anniversary, error)
	Delete(ctx context.Context, coupleID, anniversaryID string, deletedAt time.Time) error
}
