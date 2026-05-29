package todos

import "errors"

var (
	ErrInvalidTodo  = errors.New("invalid todo")
	ErrTodoNotFound = errors.New("todo not found")
)
