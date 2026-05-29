package links

import (
	"encoding/json"
	"net/http"

	"couple-calendar-api/internal/adapters/httpapi/httputil"
	"couple-calendar-api/internal/adapters/httpapi/requestctx"
	applinks "couple-calendar-api/internal/application/links"
	domainlinks "couple-calendar-api/internal/domain/links"
	"github.com/go-chi/chi/v5"
)

type Handlers struct {
	service applinks.Service
}

func NewHandlers(service applinks.Service) Handlers {
	return Handlers{service: service}
}

func (h Handlers) EnsureDateRecordForEvent(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	var body eventLinkRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.service.EnsureDateRecordForEvent(r.Context(), coupleID, requestctx.UserID(r.Context()), body.EventID)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, result)
}

func (h Handlers) CreateDateRecordFromEvent(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	var body eventLinkRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.service.CreateDateRecordFromEvent(r.Context(), coupleID, requestctx.UserID(r.Context()), body.EventID)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusCreated, result)
}

func (h Handlers) LinkRecordToEvent(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	recordID := chi.URLParam(r, "recordID")
	var body eventLinkRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.service.LinkRecordToEvent(r.Context(), coupleID, requestctx.UserID(r.Context()), recordID, body.EventID)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, result)
}

func (h Handlers) UnlinkRecordFromEvent(w http.ResponseWriter, r *http.Request) {
	result, err := h.service.UnlinkRecordFromEvent(
		r.Context(),
		chi.URLParam(r, "coupleID"),
		requestctx.UserID(r.Context()),
		chi.URLParam(r, "recordID"),
		chi.URLParam(r, "eventID"),
	)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, result)
}

func (h Handlers) DeleteDateRecordEverywhere(w http.ResponseWriter, r *http.Request) {
	err := h.service.DeleteDateRecordEverywhere(
		r.Context(),
		chi.URLParam(r, "coupleID"),
		requestctx.UserID(r.Context()),
		chi.URLParam(r, "recordID"),
	)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h Handlers) CompleteTodoItemForEvent(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	var body todoCompletionRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.service.CompleteTodoItemForEvent(r.Context(), coupleID, requestctx.UserID(r.Context()), body.ItemID, body.EventID)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusCreated, result)
}

func (h Handlers) RemoveTodoCompletionEverywhere(w http.ResponseWriter, r *http.Request) {
	err := h.service.RemoveTodoCompletionEverywhere(
		r.Context(),
		chi.URLParam(r, "coupleID"),
		requestctx.UserID(r.Context()),
		chi.URLParam(r, "completionID"),
	)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h Handlers) LinkReviewToDateRecord(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	reviewID := chi.URLParam(r, "reviewID")
	var body reviewLinkRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.service.LinkReviewToDateRecord(r.Context(), coupleID, requestctx.UserID(r.Context()), reviewID, body.RecordID)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, result)
}

func (h Handlers) UnlinkReviewFromDateRecord(w http.ResponseWriter, r *http.Request) {
	result, err := h.service.UnlinkReviewFromDateRecord(
		r.Context(),
		chi.URLParam(r, "coupleID"),
		requestctx.UserID(r.Context()),
		chi.URLParam(r, "reviewID"),
		chi.URLParam(r, "recordID"),
	)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, result)
}

func (h Handlers) DeleteReviewEverywhere(w http.ResponseWriter, r *http.Request) {
	err := h.service.DeleteReviewEverywhere(
		r.Context(),
		chi.URLParam(r, "coupleID"),
		requestctx.UserID(r.Context()),
		chi.URLParam(r, "reviewID"),
	)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h Handlers) RemoveCalendarEventLinkedItem(w http.ResponseWriter, r *http.Request) {
	coupleID := chi.URLParam(r, "coupleID")
	eventID := chi.URLParam(r, "eventID")
	var body linkedItemRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	err := h.service.RemoveCalendarEventLinkedItem(r.Context(), coupleID, requestctx.UserID(r.Context()), eventID, body.LinkedItem)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type eventLinkRequest struct {
	UserID  string `json:"userId"`
	EventID string `json:"eventId"`
}

type todoCompletionRequest struct {
	UserID  string `json:"userId"`
	ItemID  string `json:"itemId"`
	EventID string `json:"eventId"`
}

type linkedItemRequest struct {
	UserID     string                 `json:"userId"`
	LinkedItem domainlinks.LinkedItem `json:"linkedItem"`
}

type reviewLinkRequest struct {
	UserID   string `json:"userId"`
	RecordID string `json:"recordId"`
}
