package couples

import (
	"context"
	"couple-calendar-api/internal/platform/clock"
	"couple-calendar-api/internal/platform/idgen"
	"strings"
	"time"
)

type Service struct {
	repository Repository
	clock      clock.Clock
	ids        idgen.Generator
}

func NewService(r Repository, c clock.Clock) Service {
	return Service{repository: r, clock: c, ids: idgen.Crypto{}}
}
func (s Service) Current(ctx context.Context, userID string) (*Couple, error) {
	if userID == "" {
		return nil, ErrInvalidCouple
	}
	return s.repository.Current(ctx, userID)
}
func (s Service) Create(ctx context.Context, userID, partnerName string) (Couple, error) {
	if userID == "" {
		return Couple{}, ErrInvalidCouple
	}
	now := s.clock.Now()
	id := s.ids.NewID("couple")
	code := "LOVE-" + strings.ToUpper(strings.TrimPrefix(id, "couple-"))[:6]
	name := strings.TrimSpace(partnerName)
	if name == "" {
		name = "상대방"
	}
	return s.repository.Create(ctx, Couple{ID: id, MemberIDs: []string{userID}, InviteCode: code, PartnerDisplayName: name, CreatedAt: now}, userID)
}
func (s Service) Join(ctx context.Context, userID, inviteCode string) (Couple, error) {
	if userID == "" || strings.TrimSpace(inviteCode) == "" {
		return Couple{}, ErrInvalidCouple
	}
	return s.repository.Join(ctx, userID, strings.ToUpper(strings.TrimSpace(inviteCode)))
}
func (s Service) Reset(ctx context.Context, userID string) error {
	if userID == "" {
		return ErrInvalidCouple
	}
	return s.repository.Reset(ctx, userID)
}

var _ = time.Time{}
