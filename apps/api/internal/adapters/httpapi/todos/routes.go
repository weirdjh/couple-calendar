package todos

import "github.com/go-chi/chi/v5"

func MountRoutes(r chi.Router, h Handlers) {
	r.Route("/v1/couples/{coupleID}/todos", func(r chi.Router) {
		r.Get("/", h.Fetch)
		r.Post("/categories", h.CreateCategory)
		r.Put("/categories/{categoryID}", h.UpdateCategory)
		r.Post("/items", h.CreateItem)
		r.Put("/items/{itemID}", h.UpdateItem)
		r.Post("/completions", h.CreateCompletion)
		r.Delete("/completions/{completionID}", h.DeleteCompletion)
	})
}
