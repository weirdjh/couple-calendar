package anniversaries

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

type Draft struct {
	Title        string    `json:"title"`
	BaseDate     time.Time `json:"baseDate"`
	RepeatRule   string    `json:"repeatRule"`
	CalendarType string    `json:"calendarType"`
	IsLeapMonth  bool      `json:"isLeapMonth"`
}

func (s Service) List(ctx context.Context, coupleID string, userID string) ([]Anniversary, error) {
	if coupleID == "" || userID == "" {
		return nil, ErrInvalidAnniversary
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return nil, err
	}
	v, err := s.repository.List(ctx, coupleID)
	if err != nil {
		return nil, err
	}
	sort.SliceStable(v, func(i, j int) bool { return v[i].BaseDate.Before(v[j].BaseDate) })
	return v, nil
}
func (s Service) Create(ctx context.Context, coupleID, userID string, d Draft) (Anniversary, error) {
	title := strings.TrimSpace(d.Title)
	if coupleID == "" || userID == "" || title == "" || d.BaseDate.IsZero() {
		return Anniversary{}, ErrInvalidAnniversary
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return Anniversary{}, err
	}
	if d.CalendarType == "" {
		d.CalendarType = "solar"
	}
	if d.RepeatRule == "" {
		d.RepeatRule = "yearly"
	}
	now := s.clock.Now()
	return s.repository.Create(ctx, Anniversary{ID: s.ids.NewID("anniv"), CoupleID: coupleID, Title: title, BaseDate: d.BaseDate.UTC(), RepeatRule: d.RepeatRule, CalendarType: d.CalendarType, IsLeapMonth: d.IsLeapMonth, CreatedBy: userID, CreatedAt: now, UpdatedAt: now})
}
func (s Service) Update(ctx context.Context, coupleID, userID string, a Anniversary) (Anniversary, error) {
	if coupleID == "" || userID == "" || a.ID == "" || strings.TrimSpace(a.Title) == "" {
		return Anniversary{}, ErrInvalidAnniversary
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return Anniversary{}, err
	}
	a.CoupleID = coupleID
	a.Title = strings.TrimSpace(a.Title)
	a.BaseDate = a.BaseDate.UTC()
	a.UpdatedAt = s.clock.Now()
	return s.repository.Update(ctx, a)
}
func (s Service) Delete(ctx context.Context, coupleID, anniversaryID, userID string) error {
	if coupleID == "" || anniversaryID == "" || userID == "" {
		return ErrInvalidAnniversary
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return err
	}
	return s.repository.Delete(ctx, coupleID, anniversaryID, s.clock.Now())
}
