package couples

import (
	"context"
	domain "couple-calendar-api/internal/domain/couples"
)

type Couple = domain.Couple

var ErrInvalidCouple = domain.ErrInvalidCouple

type Repository interface {
	Current(ctx context.Context, userID string) (*Couple, error)
	Create(ctx context.Context, couple Couple, userID string) (Couple, error)
	Join(ctx context.Context, userID, inviteCode string) (Couple, error)
	Reset(ctx context.Context, userID string) error
}
