package authz

import (
	"context"
	"errors"

	"couple-calendar-api/internal/application/couples"
)

var (
	ErrForbidden       = errors.New("forbidden")
	ErrInvalidIdentity = errors.New("invalid identity")
)

type CoupleAuthorizer interface {
	RequireMember(ctx context.Context, coupleID string, userID string) error
}

type RepositoryAuthorizer struct {
	couples couples.Repository
}

func NewRepositoryAuthorizer(couples couples.Repository) RepositoryAuthorizer {
	return RepositoryAuthorizer{couples: couples}
}

func (a RepositoryAuthorizer) RequireMember(ctx context.Context, coupleID string, userID string) error {
	if coupleID == "" || userID == "" {
		return ErrInvalidIdentity
	}
	if a.couples == nil {
		return ErrForbidden
	}
	couple, err := a.couples.Current(ctx, userID)
	if err != nil {
		return err
	}
	if couple == nil || couple.ID != coupleID {
		return ErrForbidden
	}
	return nil
}

type AllowAllAuthorizer struct{}

func (AllowAllAuthorizer) RequireMember(ctx context.Context, coupleID string, userID string) error {
	if coupleID == "" || userID == "" {
		return ErrInvalidIdentity
	}
	return nil
}
