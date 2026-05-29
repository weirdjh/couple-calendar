package daterecords

import "github.com/go-chi/chi/v5"

func MountRoutes(r chi.Router, handlers Handlers) {
	r.Route("/v1/couples/{coupleID}/date-records", func(r chi.Router) {
		r.Get("/", handlers.List)
		r.Post("/", handlers.Create)
		r.Put("/{recordID}", handlers.Update)
		r.Delete("/{recordID}", handlers.Delete)
		r.Put("/{recordID}/calendar-event", handlers.LinkCalendarEvent)
		r.Delete("/{recordID}/calendar-event/{eventID}", handlers.UnlinkCalendarEvent)
		r.Post("/{recordID}/linked-items", handlers.AddLinkedItem)
		r.Post("/{recordID}/linked-items/remove", handlers.RemoveLinkedItem)
	})
}
