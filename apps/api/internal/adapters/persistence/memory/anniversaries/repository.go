package anniversaries

import (
	"context"
	"couple-calendar-api/internal/application/anniversaries"
	"time"
)

type Repository struct {
	values map[string]anniversaries.Anniversary
}

func NewRepository() *Repository { return &Repository{values: map[string]anniversaries.Anniversary{}} }
func (r *Repository) List(ctx context.Context, coupleID string) ([]anniversaries.Anniversary, error) {
	out := []anniversaries.Anniversary{}
	for _, v := range r.values {
		if v.CoupleID == coupleID && v.DeletedAt == nil {
			out = append(out, v)
		}
	}
	return out, nil
}
func (r *Repository) Create(ctx context.Context, v anniversaries.Anniversary) (anniversaries.Anniversary, error) {
	r.values[key(v.CoupleID, v.ID)] = v
	return v, nil
}
func (r *Repository) Update(ctx context.Context, v anniversaries.Anniversary) (anniversaries.Anniversary, error) {
	r.values[key(v.CoupleID, v.ID)] = v
	return v, nil
}
func (r *Repository) Delete(ctx context.Context, coupleID, id string, deletedAt time.Time) error {
	v := r.values[key(coupleID, id)]
	deletedAt = deletedAt.UTC()
	v.DeletedAt = &deletedAt
	r.values[key(coupleID, id)] = v
	return nil
}
func key(a, b string) string { return a + "/" + b }
