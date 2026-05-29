package reviews

import "github.com/go-chi/chi/v5"

func MountRoutes(r chi.Router, h Handlers) {
	r.Route("/v1/couples/{coupleID}/reviews", func(r chi.Router) {
		r.Get("/", h.List)
		r.Post("/", h.Create)
		r.Put("/{reviewID}", h.Update)
		r.Delete("/{reviewID}", h.Delete)
	})
}
