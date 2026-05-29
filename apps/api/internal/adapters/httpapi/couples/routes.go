package couples

import "github.com/go-chi/chi/v5"

func MountRoutes(r chi.Router, h Handlers) {
	r.Route("/v1/couples", func(r chi.Router) {
		r.Get("/current", h.Current)
		r.Post("/", h.Create)
		r.Post("/join", h.Join)
		r.Delete("/current", h.Reset)
	})
}
