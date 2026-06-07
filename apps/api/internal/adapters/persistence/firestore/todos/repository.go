package todos

import (
	"context"
	"errors"
	"time"

	"cloud.google.com/go/firestore"
	firestoretransaction "couple-calendar-api/internal/adapters/persistence/firestore/transaction"
	"couple-calendar-api/internal/application/todos"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type Repository struct{ client *firestore.Client }

func NewRepository(client *firestore.Client) Repository { return Repository{client: client} }

func (r Repository) Fetch(ctx context.Context, coupleID string) (todos.Snapshot, error) {
	categories, err := list[todos.Category](ctx, r.categories(coupleID))
	if err != nil {
		return todos.Snapshot{}, err
	}
	items, err := list[todos.Item](ctx, r.items(coupleID))
	if err != nil {
		return todos.Snapshot{}, err
	}
	completions, err := list[todos.Completion](ctx, r.completions(coupleID))
	if err != nil {
		return todos.Snapshot{}, err
	}
	return todos.Snapshot{Categories: categories, Items: items, Completions: completions}, nil
}

func (r Repository) CreateCategory(ctx context.Context, category todos.Category) (todos.Category, error) {
	err := firestoretransaction.Set(ctx, r.categories(category.CoupleID).Doc(category.ID), category)
	return category, err
}

func (r Repository) UpdateCategory(ctx context.Context, category todos.Category) (todos.Category, error) {
	err := firestoretransaction.Set(ctx, r.categories(category.CoupleID).Doc(category.ID), category)
	return category, err
}

func (r Repository) CreateItem(ctx context.Context, item todos.Item) (todos.Item, error) {
	err := firestoretransaction.Set(ctx, r.items(item.CoupleID).Doc(item.ID), item)
	return item, err
}

func (r Repository) UpdateItem(ctx context.Context, item todos.Item) (todos.Item, error) {
	err := firestoretransaction.Set(ctx, r.items(item.CoupleID).Doc(item.ID), item)
	return item, err
}

func (r Repository) CreateCompletion(ctx context.Context, completion todos.Completion) (todos.Completion, error) {
	err := firestoretransaction.Set(ctx, r.completions(completion.CoupleID).Doc(completion.ID), completion)
	return completion, err
}

func (r Repository) DeleteCompletion(ctx context.Context, coupleID string, completionID string, deletedAt time.Time) error {
	err := firestoretransaction.Update(ctx, r.completions(coupleID).Doc(completionID), []firestore.Update{{Path: "DeletedAt", Value: deletedAt.UTC()}})
	if status.Code(err) == codes.NotFound {
		return todos.ErrTodoNotFound
	}
	return err
}

func (r Repository) categories(coupleID string) *firestore.CollectionRef {
	return r.client.Collection("couples").Doc(coupleID).Collection("todoCategories")
}
func (r Repository) items(coupleID string) *firestore.CollectionRef {
	return r.client.Collection("couples").Doc(coupleID).Collection("todoItems")
}
func (r Repository) completions(coupleID string) *firestore.CollectionRef {
	return r.client.Collection("couples").Doc(coupleID).Collection("todoCompletions")
}

type withID interface{ setID(string) }

func list[T any](ctx context.Context, collection *firestore.CollectionRef) ([]T, error) {
	iter := collection.Documents(ctx)
	defer iter.Stop()
	result := []T{}
	for {
		doc, err := iter.Next()
		if errors.Is(err, iterator.Done) {
			break
		}
		if err != nil {
			return nil, err
		}
		var value T
		if err := doc.DataTo(&value); err != nil {
			return nil, err
		}
		switch item := any(&value).(type) {
		case *todos.Category:
			if item.DeletedAt != nil {
				continue
			}
			item.ID = doc.Ref.ID
		case *todos.Item:
			if item.DeletedAt != nil {
				continue
			}
			item.ID = doc.Ref.ID
		case *todos.Completion:
			if item.DeletedAt != nil {
				continue
			}
			item.ID = doc.Ref.ID
		}
		result = append(result, value)
	}
	return result, nil
}
