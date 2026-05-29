package reviews

import (
	"context"
	"sort"
	"strings"

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

type Draft struct {
	Type         string            `json:"type"`
	Title        string            `json:"title"`
	Rating       float64           `json:"rating"`
	Memo         string            `json:"memo"`
	Photos       []PhotoAttachment `json:"photos"`
	DateRecordID *string           `json:"dateRecordId"`
}

func (s Service) List(ctx context.Context, coupleID, userID string) ([]Review, error) {
	if coupleID == "" || userID == "" {
		return nil, ErrInvalidReview
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return nil, err
	}
	reviews, err := s.repository.List(ctx, coupleID)
	if err != nil {
		return nil, err
	}
	sort.SliceStable(reviews, func(i, j int) bool { return reviews[i].CreatedAt.After(reviews[j].CreatedAt) })
	return reviews, nil
}
func (s Service) Create(ctx context.Context, coupleID, userID string, draft Draft) (Review, error) {
	title := strings.TrimSpace(draft.Title)
	if coupleID == "" || userID == "" || title == "" {
		return Review{}, ErrInvalidReview
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return Review{}, err
	}
	now := s.clock.Now()
	if draft.Photos == nil {
		draft.Photos = []PhotoAttachment{}
	}
	return s.repository.Create(ctx, Review{ID: s.ids.NewID("review"), CoupleID: coupleID, Type: draft.Type, Title: title, Rating: draft.Rating, Memo: strings.TrimSpace(draft.Memo), Photos: draft.Photos, DateRecordID: draft.DateRecordID, CreatedBy: userID, CreatedAt: now, UpdatedAt: now})
}
func (s Service) Update(ctx context.Context, coupleID, userID string, review Review) (Review, error) {
	if coupleID == "" || userID == "" || review.ID == "" || strings.TrimSpace(review.Title) == "" {
		return Review{}, ErrInvalidReview
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return Review{}, err
	}
	review.CoupleID = coupleID
	review.Title = strings.TrimSpace(review.Title)
	review.Memo = strings.TrimSpace(review.Memo)
	review.UpdatedAt = s.clock.Now()
	if review.Photos == nil {
		review.Photos = []PhotoAttachment{}
	}
	return s.repository.Update(ctx, review)
}
func (s Service) Delete(ctx context.Context, coupleID, reviewID, userID string) error {
	if coupleID == "" || userID == "" || reviewID == "" {
		return ErrInvalidReview
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return err
	}
	return s.repository.Delete(ctx, coupleID, reviewID, s.clock.Now())
}
