package todos

import (
	"encoding/json"
	"net/http"

	"couple-calendar-api/internal/adapters/httpapi/httputil"
	"couple-calendar-api/internal/adapters/httpapi/requestctx"
	apptodos "couple-calendar-api/internal/application/todos"
	"github.com/go-chi/chi/v5"
)

type Handlers struct{ service apptodos.Service }

func NewHandlers(service apptodos.Service) Handlers { return Handlers{service: service} }

func (h Handlers) Fetch(w http.ResponseWriter, r *http.Request) {
	s, err := h.service.Fetch(r.Context(), chi.URLParam(r, "coupleID"), requestctx.UserID(r.Context()))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, s)
}

func (h Handlers) CreateCategory(w http.ResponseWriter, r *http.Request) {
	var body struct {
		UserID string                 `json:"userId"`
		Draft  apptodos.CategoryDraft `json:"draft"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	v, err := h.service.CreateCategory(r.Context(), chi.URLParam(r, "coupleID"), requestctx.UserID(r.Context()), body.Draft)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusCreated, v)
}

func (h Handlers) UpdateCategory(w http.ResponseWriter, r *http.Request) {
	var body struct {
		UserID   string            `json:"userId"`
		Category apptodos.Category `json:"category"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	body.Category.ID = chi.URLParam(r, "categoryID")
	v, err := h.service.UpdateCategory(r.Context(), chi.URLParam(r, "coupleID"), requestctx.UserID(r.Context()), body.Category)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, v)
}

func (h Handlers) CreateItem(w http.ResponseWriter, r *http.Request) {
	var body struct {
		UserID string             `json:"userId"`
		Draft  apptodos.ItemDraft `json:"draft"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	v, err := h.service.CreateItem(r.Context(), chi.URLParam(r, "coupleID"), requestctx.UserID(r.Context()), body.Draft)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusCreated, v)
}

func (h Handlers) UpdateItem(w http.ResponseWriter, r *http.Request) {
	var body struct {
		UserID string        `json:"userId"`
		Item   apptodos.Item `json:"item"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	body.Item.ID = chi.URLParam(r, "itemID")
	v, err := h.service.UpdateItem(r.Context(), chi.URLParam(r, "coupleID"), requestctx.UserID(r.Context()), body.Item)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, v)
}

func (h Handlers) CreateCompletion(w http.ResponseWriter, r *http.Request) {
	var body struct {
		UserID string                   `json:"userId"`
		Draft  apptodos.CompletionDraft `json:"draft"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	v, err := h.service.CreateCompletion(r.Context(), chi.URLParam(r, "coupleID"), requestctx.UserID(r.Context()), body.Draft)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusCreated, v)
}

func (h Handlers) DeleteCompletion(w http.ResponseWriter, r *http.Request) {
	err := h.service.DeleteCompletion(r.Context(), chi.URLParam(r, "coupleID"), chi.URLParam(r, "completionID"), requestctx.UserID(r.Context()))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
