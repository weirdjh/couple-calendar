package daterecords

import (
	"encoding/json"
	"net/http"

	"couple-calendar-api/internal/adapters/httpapi/httputil"
	"couple-calendar-api/internal/adapters/httpapi/requestctx"
	appdaterecords "couple-calendar-api/internal/application/daterecords"
	"github.com/go-chi/chi/v5"
)

type Handlers struct {
	service appdaterecords.Service
}

func NewHandlers(service appdaterecords.Service) Handlers {
	return Handlers{service: service}
}

func (h Handlers) List(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	userID := requestctx.UserID(r.Context())
	records, err := h.service.List(r.Context(), coupleID, userID)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, records)
}

func (h Handlers) Create(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	var body dateRecordMutationRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	record, err := h.service.Create(r.Context(), toCreateInput(coupleID, requestctx.UserID(r.Context()), body))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusCreated, record)
}

func (h Handlers) Update(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	recordID := chi.URLParam(r, "recordID")
	var body dateRecordMutationRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	record, err := h.service.Update(r.Context(), toUpdateInput(coupleID, recordID, requestctx.UserID(r.Context()), body))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, record)
}

func (h Handlers) Delete(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	recordID := chi.URLParam(r, "recordID")
	userID := requestctx.UserID(r.Context())
	if err := h.service.Delete(r.Context(), coupleID, recordID, userID); err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h Handlers) LinkCalendarEvent(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	recordID := chi.URLParam(r, "recordID")
	var body calendarEventLinkRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	record, err := h.service.LinkCalendarEvent(r.Context(), coupleID, recordID, body.EventID, requestctx.UserID(r.Context()))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, record)
}

func (h Handlers) UnlinkCalendarEvent(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	recordID := chi.URLParam(r, "recordID")
	eventID := chi.URLParam(r, "eventID")
	userID := requestctx.UserID(r.Context())
	record, err := h.service.UnlinkCalendarEvent(r.Context(), coupleID, recordID, eventID, userID)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, record)
}

func (h Handlers) AddLinkedItem(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	recordID := chi.URLParam(r, "recordID")
	var body linkedItemMutationRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	record, err := h.service.AddLinkedItem(r.Context(), coupleID, recordID, requestctx.UserID(r.Context()), body.LinkedItem)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, record)
}

func (h Handlers) RemoveLinkedItem(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	recordID := chi.URLParam(r, "recordID")
	var body linkedItemMutationRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	record, err := h.service.RemoveLinkedItem(r.Context(), coupleID, recordID, requestctx.UserID(r.Context()), body.LinkedItem)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, record)
}
