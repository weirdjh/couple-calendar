package todos

import (
	"context"
	"time"

	domain "couple-calendar-api/internal/domain/todos"
)

type Category = domain.Category
type Item = domain.Item
type Completion = domain.Completion
type Snapshot = domain.Snapshot

var (
	ErrInvalidTodo  = domain.ErrInvalidTodo
	ErrTodoNotFound = domain.ErrTodoNotFound
)

type Repository interface {
	Fetch(ctx context.Context, coupleID string) (Snapshot, error)
	CreateCategory(ctx context.Context, category Category) (Category, error)
	UpdateCategory(ctx context.Context, category Category) (Category, error)
	CreateItem(ctx context.Context, item Item) (Item, error)
	UpdateItem(ctx context.Context, item Item) (Item, error)
	CreateCompletion(ctx context.Context, completion Completion) (Completion, error)
	DeleteCompletion(ctx context.Context, coupleID string, completionID string, deletedAt time.Time) error
}
