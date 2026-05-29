package anniversaries

import "github.com/go-chi/chi/v5"

func MountRoutes(r chi.Router, h Handlers) {
	r.Route("/v1/couples/{coupleID}/anniversaries", func(r chi.Router) {
		r.Get("/", h.List)
		r.Post("/", h.Create)
		r.Put("/{anniversaryID}", h.Update)
		r.Delete("/{anniversaryID}", h.Delete)
	})
}
