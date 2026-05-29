package reviews

import "errors"

var ErrInvalidReview = errors.New("invalid review")
var ErrReviewNotFound = errors.New("review not found")
