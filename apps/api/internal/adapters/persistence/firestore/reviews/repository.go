package reviews

import (
	"context"
	"errors"
	"time"

	"cloud.google.com/go/firestore"
	firestoretransaction "couple-calendar-api/internal/adapters/persistence/firestore/transaction"
	"couple-calendar-api/internal/application/reviews"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type Repository struct{ client *firestore.Client }

func NewRepository(client *firestore.Client) Repository { return Repository{client: client} }
func (r Repository) List(ctx context.Context, coupleID string) ([]reviews.Review, error) {
	iter := r.collection(coupleID).Documents(ctx)
	defer iter.Stop()
	result := []reviews.Review{}
	for {
		doc, err := iter.Next()
		if errors.Is(err, iterator.Done) {
			break
		}
		if err != nil {
			return nil, err
		}
		var v reviews.Review
		if err := doc.DataTo(&v); err != nil {
			return nil, err
		}
		if v.DeletedAt != nil {
			continue
		}
		v.ID = doc.Ref.ID
		if v.Photos == nil {
			v.Photos = []reviews.PhotoAttachment{}
		}
		result = append(result, v)
	}
	return result, nil
}
func (r Repository) Create(ctx context.Context, v reviews.Review) (reviews.Review, error) {
	err := firestoretransaction.Set(ctx, r.collection(v.CoupleID).Doc(v.ID), v)
	return v, err
}
func (r Repository) Get(ctx context.Context, coupleID, reviewID string) (reviews.Review, error) {
	doc, err := r.collection(coupleID).Doc(reviewID).Get(ctx)
	if status.Code(err) == codes.NotFound {
		return reviews.Review{}, reviews.ErrReviewNotFound
	}
	if err != nil {
		return reviews.Review{}, err
	}
	var v reviews.Review
	if err := doc.DataTo(&v); err != nil {
		return reviews.Review{}, err
	}
	if v.DeletedAt != nil {
		return reviews.Review{}, reviews.ErrReviewNotFound
	}
	v.ID = doc.Ref.ID
	if v.Photos == nil {
		v.Photos = []reviews.PhotoAttachment{}
	}
	return v, nil
}
func (r Repository) Update(ctx context.Context, v reviews.Review) (reviews.Review, error) {
	err := firestoretransaction.Set(ctx, r.collection(v.CoupleID).Doc(v.ID), v)
	return v, err
}
func (r Repository) Delete(ctx context.Context, coupleID, reviewID string, deletedAt time.Time) error {
	err := firestoretransaction.Update(ctx, r.collection(coupleID).Doc(reviewID), []firestore.Update{{Path: "DeletedAt", Value: deletedAt.UTC()}, {Path: "UpdatedAt", Value: deletedAt.UTC()}})
	return err
}
func (r Repository) collection(coupleID string) *firestore.CollectionRef {
	return r.client.Collection("couples").Doc(coupleID).Collection("reviews")
}
