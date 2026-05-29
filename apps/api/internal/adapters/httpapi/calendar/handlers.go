package calendar

import (
	"encoding/json"
	"net/http"
	"time"

	"couple-calendar-api/internal/adapters/httpapi/httputil"
	"couple-calendar-api/internal/adapters/httpapi/requestctx"
	appcalendar "couple-calendar-api/internal/application/calendar"
	"github.com/go-chi/chi/v5"
)

type Handlers struct {
	service appcalendar.EventService
}

func NewHandlers(service appcalendar.EventService) Handlers {
	return Handlers{service: service}
}

func (h Handlers) List(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	userID := requestctx.UserID(r.Context())
	startAt, err := time.Parse(time.RFC3339, r.URL.Query().Get("startAt"))
	if err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid startAt")
		return
	}
	endAt, err := time.Parse(time.RFC3339, r.URL.Query().Get("endAt"))
	if err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid endAt")
		return
	}
	events, err := h.service.ListForUser(r.Context(), coupleID, userID, startAt, endAt)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, events)
}

func (h Handlers) Create(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	var body createEventRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	event, err := h.service.Create(r.Context(), toCreateInput(coupleID, requestctx.UserID(r.Context()), body))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusCreated, event)
}

func (h Handlers) Update(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	eventID := chi.URLParam(r, "eventID")
	var body eventMutationRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	event, err := h.service.Update(r.Context(), toUpdateInput(coupleID, eventID, requestctx.UserID(r.Context()), body))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, event)
}

func (h Handlers) Delete(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	eventID := chi.URLParam(r, "eventID")
	userID := requestctx.UserID(r.Context())
	if err := h.service.Delete(r.Context(), coupleID, eventID, userID); err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
