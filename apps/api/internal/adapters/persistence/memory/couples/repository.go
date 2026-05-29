package couples

import (
	"context"
	"couple-calendar-api/internal/application/couples"
)

type Repository struct {
	couples     map[string]couples.Couple
	memberships map[string]string
}

func NewRepository() *Repository {
	return &Repository{couples: map[string]couples.Couple{}, memberships: map[string]string{}}
}
func (r *Repository) Current(ctx context.Context, userID string) (*couples.Couple, error) {
	id := r.memberships[userID]
	if id == "" {
		return nil, nil
	}
	c := r.couples[id]
	return &c, nil
}
func (r *Repository) Create(ctx context.Context, c couples.Couple, userID string) (couples.Couple, error) {
	r.couples[c.ID] = c
	r.memberships[userID] = c.ID
	return c, nil
}
func (r *Repository) Join(ctx context.Context, userID, inviteCode string) (couples.Couple, error) {
	for _, c := range r.couples {
		if c.InviteCode == inviteCode {
			c.MemberIDs = append(c.MemberIDs, userID)
			r.couples[c.ID] = c
			r.memberships[userID] = c.ID
			return c, nil
		}
	}
	return couples.Couple{}, couples.ErrInvalidCouple
}
func (r *Repository) Reset(ctx context.Context, userID string) error {
	delete(r.memberships, userID)
	return nil
}
