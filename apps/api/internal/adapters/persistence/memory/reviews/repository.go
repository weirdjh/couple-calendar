package reviews

import (
	"context"
	"time"

	"couple-calendar-api/internal/application/reviews"
)

type Repository struct{ values map[string]reviews.Review }

func NewRepository() *Repository { return &Repository{values: map[string]reviews.Review{}} }
func (r *Repository) List(ctx context.Context, coupleID string) ([]reviews.Review, error) {
	out := []reviews.Review{}
	for _, v := range r.values {
		if v.CoupleID == coupleID && v.DeletedAt == nil {
			out = append(out, v)
		}
	}
	return out, nil
}
func (r *Repository) Create(ctx context.Context, v reviews.Review) (reviews.Review, error) {
	r.values[key(v.CoupleID, v.ID)] = v
	return v, nil
}
func (r *Repository) Get(ctx context.Context, coupleID, reviewID string) (reviews.Review, error) {
	v, ok := r.values[key(coupleID, reviewID)]
	if !ok || v.DeletedAt != nil {
		return reviews.Review{}, reviews.ErrReviewNotFound
	}
	return v, nil
}
func (r *Repository) Update(ctx context.Context, v reviews.Review) (reviews.Review, error) {
	r.values[key(v.CoupleID, v.ID)] = v
	return v, nil
}
func (r *Repository) Delete(ctx context.Context, coupleID, reviewID string, deletedAt time.Time) error {
	v := r.values[key(coupleID, reviewID)]
	deletedAt = deletedAt.UTC()
	v.DeletedAt = &deletedAt
	r.values[key(coupleID, reviewID)] = v
	return nil
}
func key(a, b string) string { return a + "/" + b }
