package httputil

import (
	"errors"
	"net/http"

	appanniversaries "couple-calendar-api/internal/application/anniversaries"
	appauthz "couple-calendar-api/internal/application/authz"
	appcalendar "couple-calendar-api/internal/application/calendar"
	appcouples "couple-calendar-api/internal/application/couples"
	appdaterecords "couple-calendar-api/internal/application/daterecords"
	appreviews "couple-calendar-api/internal/application/reviews"
	apptodos "couple-calendar-api/internal/application/todos"
)

func WriteDomainError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, appauthz.ErrInvalidIdentity):
		WriteError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, appauthz.ErrForbidden):
		WriteError(w, http.StatusForbidden, err.Error())
	case errors.Is(err, appcalendar.ErrInvalidEvent), errors.Is(err, appcalendar.ErrInvalidDateRange):
		WriteError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, appcalendar.ErrEventNotFound):
		WriteError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, appcalendar.ErrForbidden):
		WriteError(w, http.StatusForbidden, err.Error())
	case errors.Is(err, appdaterecords.ErrInvalidDateRecord):
		WriteError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, appdaterecords.ErrDateRecordNotFound):
		WriteError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, apptodos.ErrInvalidTodo):
		WriteError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, apptodos.ErrTodoNotFound):
		WriteError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, appreviews.ErrInvalidReview):
		WriteError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, appreviews.ErrReviewNotFound):
		WriteError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, appanniversaries.ErrInvalidAnniversary):
		WriteError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, appcouples.ErrInvalidCouple):
		WriteError(w, http.StatusBadRequest, err.Error())
	default:
		WriteError(w, http.StatusInternalServerError, "internal server error")
	}
}
