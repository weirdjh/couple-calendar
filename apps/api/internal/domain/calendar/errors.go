package calendar

import "errors"

var (
	ErrInvalidEvent     = errors.New("invalid calendar event")
	ErrEventNotFound    = errors.New("calendar event not found")
	ErrForbidden        = errors.New("forbidden")
	ErrInvalidDateRange = errors.New("invalid date range")
)
