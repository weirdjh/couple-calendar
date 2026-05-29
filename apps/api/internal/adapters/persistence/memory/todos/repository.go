package todos

import (
	"context"
	"time"

	"couple-calendar-api/internal/application/todos"
)

type Repository struct {
	categories  map[string]todos.Category
	items       map[string]todos.Item
	completions map[string]todos.Completion
}

func NewRepository() *Repository {
	return &Repository{categories: map[string]todos.Category{}, items: map[string]todos.Item{}, completions: map[string]todos.Completion{}}
}

func (r *Repository) Fetch(ctx context.Context, coupleID string) (todos.Snapshot, error) {
	s := todos.Snapshot{}
	for _, v := range r.categories {
		if v.CoupleID == coupleID && v.DeletedAt == nil {
			s.Categories = append(s.Categories, v)
		}
	}
	for _, v := range r.items {
		if v.CoupleID == coupleID && v.DeletedAt == nil {
			s.Items = append(s.Items, v)
		}
	}
	for _, v := range r.completions {
		if v.CoupleID == coupleID && v.DeletedAt == nil {
			s.Completions = append(s.Completions, v)
		}
	}
	return s, nil
}
func (r *Repository) CreateCategory(ctx context.Context, v todos.Category) (todos.Category, error) {
	r.categories[key(v.CoupleID, v.ID)] = v
	return v, nil
}
func (r *Repository) UpdateCategory(ctx context.Context, v todos.Category) (todos.Category, error) {
	r.categories[key(v.CoupleID, v.ID)] = v
	return v, nil
}
func (r *Repository) CreateItem(ctx context.Context, v todos.Item) (todos.Item, error) {
	r.items[key(v.CoupleID, v.ID)] = v
	return v, nil
}
func (r *Repository) UpdateItem(ctx context.Context, v todos.Item) (todos.Item, error) {
	r.items[key(v.CoupleID, v.ID)] = v
	return v, nil
}
func (r *Repository) CreateCompletion(ctx context.Context, v todos.Completion) (todos.Completion, error) {
	r.completions[key(v.CoupleID, v.ID)] = v
	return v, nil
}
func (r *Repository) DeleteCompletion(ctx context.Context, coupleID string, completionID string, deletedAt time.Time) error {
	v, ok := r.completions[key(coupleID, completionID)]
	if !ok {
		return todos.ErrTodoNotFound
	}
	deletedAt = deletedAt.UTC()
	v.DeletedAt = &deletedAt
	r.completions[key(coupleID, completionID)] = v
	return nil
}
func key(coupleID, id string) string { return coupleID + "/" + id }
