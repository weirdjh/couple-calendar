package calendar

import "github.com/go-chi/chi/v5"

func MountRoutes(r chi.Router, handlers Handlers) {
	r.Route("/v1/couples/{coupleID}/events", func(r chi.Router) {
		r.Get("/", handlers.List)
		r.Post("/", handlers.Create)
		r.Put("/{eventID}", handlers.Update)
		r.Delete("/{eventID}", handlers.Delete)
	})
}
