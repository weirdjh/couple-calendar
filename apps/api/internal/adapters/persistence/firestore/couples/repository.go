package couples

import (
	"cloud.google.com/go/firestore"
	"context"
	"couple-calendar-api/internal/application/couples"
)

type Repository struct{ client *firestore.Client }

func NewRepository(client *firestore.Client) Repository { return Repository{client: client} }
func (r Repository) Current(ctx context.Context, userID string) (*couples.Couple, error) {
	q, err := r.client.CollectionGroup("members").Where("userId", "==", userID).Limit(1).Documents(ctx).GetAll()
	if err != nil || len(q) == 0 {
		return nil, err
	}
	ref := q[0].Ref.Parent.Parent
	if ref == nil {
		return nil, nil
	}
	doc, err := ref.Get(ctx)
	if err != nil {
		return nil, err
	}
	var c couples.Couple
	if err := doc.DataTo(&c); err != nil {
		return nil, err
	}
	c.ID = doc.Ref.ID
	return &c, nil
}
func (r Repository) Create(ctx context.Context, c couples.Couple, userID string) (couples.Couple, error) {
	batch := r.client.Batch()
	ref := r.client.Collection("couples").Doc(c.ID)
	batch.Set(ref, c)
	batch.Set(ref.Collection("members").Doc(userID), map[string]any{"userId": userID, "role": "owner", "createdAt": c.CreatedAt, "updatedAt": c.CreatedAt})
	batch.Set(r.client.Collection("coupleInvites").Doc(c.InviteCode), map[string]any{"coupleId": c.ID, "createdBy": userID, "createdAt": c.CreatedAt})
	_, err := batch.Commit(ctx)
	return c, err
}
func (r Repository) Join(ctx context.Context, userID, inviteCode string) (couples.Couple, error) {
	inv, err := r.client.Collection("coupleInvites").Doc(inviteCode).Get(ctx)
	if err != nil {
		return couples.Couple{}, err
	}
	coupleID, _ := inv.Data()["coupleId"].(string)
	ref := r.client.Collection("couples").Doc(coupleID)
	doc, err := ref.Get(ctx)
	if err != nil {
		return couples.Couple{}, err
	}
	var c couples.Couple
	if err := doc.DataTo(&c); err != nil {
		return couples.Couple{}, err
	}
	c.ID = doc.Ref.ID
	ids := map[string]bool{}
	for _, id := range c.MemberIDs {
		ids[id] = true
	}
	ids[userID] = true
	c.MemberIDs = []string{}
	for id := range ids {
		c.MemberIDs = append(c.MemberIDs, id)
	}
	_, err = ref.Set(ctx, c)
	if err != nil {
		return couples.Couple{}, err
	}
	_, err = ref.Collection("members").Doc(userID).Set(ctx, map[string]any{"userId": userID, "role": "member"})
	return c, err
}
func (r Repository) Reset(ctx context.Context, userID string) error {
	q, err := r.client.CollectionGroup("members").Where("userId", "==", userID).Limit(1).Documents(ctx).GetAll()
	if err != nil || len(q) == 0 {
		return err
	}
	_, err = q[0].Ref.Delete(ctx)
	return err
}
