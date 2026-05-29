package todos

import (
	"context"
	"sort"
	"strings"
	"time"

	"couple-calendar-api/internal/application/authz"
	"couple-calendar-api/internal/platform/clock"
	"couple-calendar-api/internal/platform/idgen"
)

type Service struct {
	repository Repository
	authorizer authz.CoupleAuthorizer
	clock      clock.Clock
	ids        idgen.Generator
}

func NewService(repository Repository, authorizer authz.CoupleAuthorizer, clock clock.Clock) Service {
	return Service{repository: repository, authorizer: authorizer, clock: clock, ids: idgen.Crypto{}}
}

type CategoryDraft struct {
	Title string `json:"title"`
	Emoji string `json:"emoji"`
}

type ItemDraft struct {
	CategoryID string `json:"categoryId"`
	Title      string `json:"title"`
	Note       string `json:"note"`
}

type CompletionDraft struct {
	ItemID          string    `json:"itemId"`
	CompletedAt     time.Time `json:"completedAt"`
	CalendarEventID string    `json:"calendarEventId"`
	Memo            string    `json:"memo"`
}

func (s Service) Fetch(ctx context.Context, coupleID string, userID string) (Snapshot, error) {
	if coupleID == "" || userID == "" {
		return Snapshot{}, ErrInvalidTodo
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return Snapshot{}, err
	}
	snapshot, err := s.repository.Fetch(ctx, coupleID)
	if err != nil {
		return Snapshot{}, err
	}
	sort.SliceStable(snapshot.Categories, func(i, j int) bool {
		return snapshot.Categories[i].CreatedAt.Before(snapshot.Categories[j].CreatedAt)
	})
	sort.SliceStable(snapshot.Items, func(i, j int) bool {
		return snapshot.Items[i].CreatedAt.Before(snapshot.Items[j].CreatedAt)
	})
	sort.SliceStable(snapshot.Completions, func(i, j int) bool {
		return snapshot.Completions[i].CompletedAt.After(snapshot.Completions[j].CompletedAt)
	})
	return snapshot, nil
}

func (s Service) CreateCategory(ctx context.Context, coupleID string, userID string, draft CategoryDraft) (Category, error) {
	title := strings.TrimSpace(draft.Title)
	if coupleID == "" || userID == "" || title == "" {
		return Category{}, ErrInvalidTodo
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return Category{}, err
	}
	emoji := strings.TrimSpace(draft.Emoji)
	if emoji == "" {
		emoji = "🧭"
	}
	now := s.clock.Now()
	return s.repository.CreateCategory(ctx, Category{
		ID: s.ids.NewID("todo-cat"), CoupleID: coupleID, Title: title,
		Emoji: emoji, CreatedBy: userID, CreatedAt: now, UpdatedAt: now,
	})
}

func (s Service) UpdateCategory(ctx context.Context, coupleID string, userID string, category Category) (Category, error) {
	if coupleID == "" || userID == "" || category.ID == "" || strings.TrimSpace(category.Title) == "" {
		return Category{}, ErrInvalidTodo
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return Category{}, err
	}
	category.CoupleID = coupleID
	category.Title = strings.TrimSpace(category.Title)
	category.Emoji = strings.TrimSpace(category.Emoji)
	if category.Emoji == "" {
		category.Emoji = "🧭"
	}
	category.UpdatedAt = s.clock.Now()
	return s.repository.UpdateCategory(ctx, category)
}

func (s Service) CreateItem(ctx context.Context, coupleID string, userID string, draft ItemDraft) (Item, error) {
	title := strings.TrimSpace(draft.Title)
	if coupleID == "" || userID == "" || draft.CategoryID == "" || title == "" {
		return Item{}, ErrInvalidTodo
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return Item{}, err
	}
	now := s.clock.Now()
	return s.repository.CreateItem(ctx, Item{
		ID: s.ids.NewID("todo-item"), CoupleID: coupleID, CategoryID: draft.CategoryID,
		Title: title, Note: strings.TrimSpace(draft.Note), CreatedBy: userID,
		CreatedAt: now, UpdatedAt: now,
	})
}

func (s Service) UpdateItem(ctx context.Context, coupleID string, userID string, item Item) (Item, error) {
	if coupleID == "" || userID == "" || item.ID == "" || item.CategoryID == "" || strings.TrimSpace(item.Title) == "" {
		return Item{}, ErrInvalidTodo
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return Item{}, err
	}
	item.CoupleID = coupleID
	item.Title = strings.TrimSpace(item.Title)
	item.Note = strings.TrimSpace(item.Note)
	item.UpdatedAt = s.clock.Now()
	return s.repository.UpdateItem(ctx, item)
}

func (s Service) CreateCompletion(ctx context.Context, coupleID string, userID string, draft CompletionDraft) (Completion, error) {
	if coupleID == "" || userID == "" || draft.ItemID == "" || draft.CalendarEventID == "" || draft.CompletedAt.IsZero() {
		return Completion{}, ErrInvalidTodo
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return Completion{}, err
	}
	return s.repository.CreateCompletion(ctx, Completion{
		ID: s.ids.NewID("todo-done"), CoupleID: coupleID, ItemID: draft.ItemID,
		CompletedAt: draft.CompletedAt.UTC(), CompletedBy: userID,
		CalendarEventID: draft.CalendarEventID, Memo: strings.TrimSpace(draft.Memo),
		CreatedAt: s.clock.Now(),
	})
}

func (s Service) DeleteCompletion(ctx context.Context, coupleID string, completionID string, userID string) error {
	if coupleID == "" || completionID == "" || userID == "" {
		return ErrInvalidTodo
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return err
	}
	return s.repository.DeleteCompletion(ctx, coupleID, completionID, s.clock.Now())
}
