package anniversaries

import (
	"cloud.google.com/go/firestore"
	"context"
	"couple-calendar-api/internal/application/anniversaries"
	"errors"
	"google.golang.org/api/iterator"
	"time"
)

type Repository struct{ client *firestore.Client }

func NewRepository(client *firestore.Client) Repository { return Repository{client: client} }
func (r Repository) List(ctx context.Context, coupleID string) ([]anniversaries.Anniversary, error) {
	iter := r.collection(coupleID).Documents(ctx)
	defer iter.Stop()
	out := []anniversaries.Anniversary{}
	for {
		doc, err := iter.Next()
		if errors.Is(err, iterator.Done) {
			break
		}
		if err != nil {
			return nil, err
		}
		var v anniversaries.Anniversary
		if err := doc.DataTo(&v); err != nil {
			return nil, err
		}
		if v.DeletedAt != nil {
			continue
		}
		v.ID = doc.Ref.ID
		out = append(out, v)
	}
	return out, nil
}
func (r Repository) Create(ctx context.Context, v anniversaries.Anniversary) (anniversaries.Anniversary, error) {
	_, err := r.collection(v.CoupleID).Doc(v.ID).Set(ctx, v)
	return v, err
}
func (r Repository) Update(ctx context.Context, v anniversaries.Anniversary) (anniversaries.Anniversary, error) {
	_, err := r.collection(v.CoupleID).Doc(v.ID).Set(ctx, v)
	return v, err
}
func (r Repository) Delete(ctx context.Context, coupleID, id string, deletedAt time.Time) error {
	_, err := r.collection(coupleID).Doc(id).Update(ctx, []firestore.Update{{Path: "DeletedAt", Value: deletedAt.UTC()}, {Path: "UpdatedAt", Value: deletedAt.UTC()}})
	return err
}
func (r Repository) collection(coupleID string) *firestore.CollectionRef {
	return r.client.Collection("couples").Doc(coupleID).Collection("anniversaries")
}
