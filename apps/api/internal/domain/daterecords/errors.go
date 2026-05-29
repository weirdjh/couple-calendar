package daterecords

import "errors"

var (
	ErrInvalidDateRecord  = errors.New("invalid date record")
	ErrDateRecordNotFound = errors.New("date record not found")
)
