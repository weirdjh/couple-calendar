package reviews

import (
	"context"
	"time"

	domain "couple-calendar-api/internal/domain/reviews"
)

type Review = domain.Review
type PhotoAttachment = domain.PhotoAttachment

var (
	ErrInvalidReview  = domain.ErrInvalidReview
	ErrReviewNotFound = domain.ErrReviewNotFound
)

type Repository interface {
	List(ctx context.Context, coupleID string) ([]Review, error)
	Create(ctx context.Context, review Review) (Review, error)
	Get(ctx context.Context, coupleID string, reviewID string) (Review, error)
	Update(ctx context.Context, review Review) (Review, error)
	Delete(ctx context.Context, coupleID string, reviewID string, deletedAt time.Time) error
}
