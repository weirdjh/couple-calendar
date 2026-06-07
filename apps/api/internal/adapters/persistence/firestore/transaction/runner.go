package transaction

import (
	"context"

	"cloud.google.com/go/firestore"
)

type batchContextKey struct{}

type Runner struct {
	client *firestore.Client
}

func NewRunner(client *firestore.Client) Runner {
	return Runner{client: client}
}

func (r Runner) Run(ctx context.Context, operation func(context.Context) error) error {
	if batchFromContext(ctx) != nil {
		return operation(ctx)
	}

	batch := r.client.Batch()
	if err := operation(context.WithValue(ctx, batchContextKey{}, batch)); err != nil {
		return err
	}
	_, err := batch.Commit(ctx)
	return err
}

func Set(ctx context.Context, ref *firestore.DocumentRef, value any) error {
	if batch := batchFromContext(ctx); batch != nil {
		batch.Set(ref, value)
		return nil
	}
	_, err := ref.Set(ctx, value)
	return err
}

func Update(ctx context.Context, ref *firestore.DocumentRef, updates []firestore.Update) error {
	if batch := batchFromContext(ctx); batch != nil {
		batch.Update(ref, updates)
		return nil
	}
	_, err := ref.Update(ctx, updates)
	return err
}

func batchFromContext(ctx context.Context) *firestore.WriteBatch {
	batch, _ := ctx.Value(batchContextKey{}).(*firestore.WriteBatch)
	return batch
}
