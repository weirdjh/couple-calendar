package couples

import (
	"couple-calendar-api/internal/adapters/httpapi/httputil"
	"couple-calendar-api/internal/adapters/httpapi/requestctx"
	app "couple-calendar-api/internal/application/couples"
	"encoding/json"
	"net/http"
)

type Handlers struct{ service app.Service }

func NewHandlers(service app.Service) Handlers { return Handlers{service: service} }
func (h Handlers) Current(w http.ResponseWriter, r *http.Request) {
	c, err := h.service.Current(r.Context(), requestctx.UserID(r.Context()))
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	if c == nil {
		w.WriteHeader(204)
		return
	}
	httputil.WriteJSON(w, 200, c)
}
func (h Handlers) Create(w http.ResponseWriter, r *http.Request) {
	var b struct {
		UserID      string `json:"userId"`
		PartnerName string `json:"partnerName"`
	}
	if err := json.NewDecoder(r.Body).Decode(&b); err != nil {
		httputil.WriteError(w, 400, "invalid request body")
		return
	}
	c, err := h.service.Create(r.Context(), requestctx.UserID(r.Context()), b.PartnerName)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, 201, c)
}
func (h Handlers) Join(w http.ResponseWriter, r *http.Request) {
	var b struct {
		UserID     string `json:"userId"`
		InviteCode string `json:"inviteCode"`
	}
	if err := json.NewDecoder(r.Body).Decode(&b); err != nil {
		httputil.WriteError(w, 400, "invalid request body")
		return
	}
	c, err := h.service.Join(r.Context(), requestctx.UserID(r.Context()), b.InviteCode)
	if err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	httputil.WriteJSON(w, 200, c)
}
func (h Handlers) Reset(w http.ResponseWriter, r *http.Request) {
	if err := h.service.Reset(r.Context(), requestctx.UserID(r.Context())); err != nil {
		httputil.WriteDomainError(w, err)
		return
	}
	w.WriteHeader(204)
}
