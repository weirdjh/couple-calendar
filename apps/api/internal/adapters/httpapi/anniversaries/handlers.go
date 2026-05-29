package anniversaries

import (
	"couple-calendar-api/internal/adapters/httpapi/httputil"
	"couple-calendar-api/internal/adapters/httpapi/requestctx"
	app "couple-calendar-api/internal/application/anniversaries"
	"encoding/json"
	"github.com/go-chi/chi/v5"
	"net/http"
)

type Handlers struct{ service app.Service }

func NewHandlers(service app.Service) Handlers { return Handlers{service: service} }
func (h Handlers) List(w http.ResponseWriter, r *http.Request) {
	v, err := h.service.List(r.Context(), chi.URLParam(r, "coupleID"), requestctx.UserID(r.Context()))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, 200, v)
}
func (h Handlers) Create(w http.ResponseWriter, r *http.Request) {
	var b struct {
		UserID string    `json:"userId"`
		Draft  app.Draft `json:"draft"`
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
		UserID      string          `json:"userId"`
		Anniversary app.Anniversary `json:"anniversary"`
	}
	if err := json.NewDecoder(r.Body).Decode(&b); err != nil {
		httputil.WriteError(w, 400, "invalid request body")
		return
	}
	b.Anniversary.ID = chi.URLParam(r, "anniversaryID")
	v, err := h.service.Update(r.Context(), chi.URLParam(r, "coupleID"), requestctx.UserID(r.Context()), b.Anniversary)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, 200, v)
}
func (h Handlers) Delete(w http.ResponseWriter, r *http.Request) {
	err := h.service.Delete(r.Context(), chi.URLParam(r, "coupleID"), chi.URLParam(r, "anniversaryID"), requestctx.UserID(r.Context()))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	w.WriteHeader(204)
}
