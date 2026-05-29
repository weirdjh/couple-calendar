package reviews

import (
	"couple-calendar-api/internal/adapters/httpapi/httputil"
	"couple-calendar-api/internal/adapters/httpapi/requestctx"
	appreviews "couple-calendar-api/internal/application/reviews"
	"encoding/json"
	"github.com/go-chi/chi/v5"
	"net/http"
)

type Handlers struct{ service appreviews.Service }

func NewHandlers(service appreviews.Service) Handlers { return Handlers{service: service} }
func (h Handlers) List(w http.ResponseWriter, r *http.Request) {
	v, err := h.service.List(r.Context(), chi.URLParam(r, "coupleID"), requestctx.UserID(r.Context()))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, http.StatusOK, v)
}
func (h Handlers) Create(w http.ResponseWriter, r *http.Request) {
	var b struct {
		UserID string           `json:"userId"`
		Draft  appreviews.Draft `json:"draft"`
	}
	if err := json.NewDecoder(r.Body).Decode(&b); err != nil {
		httputil.WriteError(w, 400, "invalid request body")
		return
	}
	v, err := h.service.Create(r.Context(), chi.URLParam(r, "coupleID"), requestctx.UserID(r.Context()), b.Draft)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, 201, v)
}
func (h Handlers) Update(w http.ResponseWriter, r *http.Request) {
	var b struct {
		UserID string            `json:"userId"`
		Review appreviews.Review `json:"review"`
	}
	if err := json.NewDecoder(r.Body).Decode(&b); err != nil {
		httputil.WriteError(w, 400, "invalid request body")
		return
	}
	b.Review.ID = chi.URLParam(r, "reviewID")
	v, err := h.service.Update(r.Context(), chi.URLParam(r, "coupleID"), requestctx.UserID(r.Context()), b.Review)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, 200, v)
}
func (h Handlers) Delete(w http.ResponseWriter, r *http.Request) {
	err := h.service.Delete(r.Context(), chi.URLParam(r, "coupleID"), chi.URLParam(r, "reviewID"), requestctx.UserID(r.Context()))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	w.WriteHeader(204)
}
