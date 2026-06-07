package transaction

import "context"

type Runner interface {
	Run(ctx context.Context, operation func(context.Context) error) error
}

type Immediate struct{}

func (Immediate) Run(ctx context.Context, operation func(context.Context) error) error {
	return operation(ctx)
}
