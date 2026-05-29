package links

import "github.com/go-chi/chi/v5"

func MountRoutes(r chi.Router, handlers Handlers) {
	r.Route("/v1/couples/{coupleID}/links", func(r chi.Router) {
		r.Post("/date-records/ensure-for-event", handlers.EnsureDateRecordForEvent)
		r.Post("/date-records/from-event", handlers.CreateDateRecordFromEvent)
		r.Delete("/date-records/{recordID}", handlers.DeleteDateRecordEverywhere)
		r.Post("/date-records/{recordID}/calendar-event", handlers.LinkRecordToEvent)
		r.Delete("/date-records/{recordID}/calendar-event/{eventID}", handlers.UnlinkRecordFromEvent)
		r.Post("/todo-completions", handlers.CompleteTodoItemForEvent)
		r.Delete("/todo-completions/{completionID}", handlers.RemoveTodoCompletionEverywhere)
		r.Post("/reviews/{reviewID}/date-record", handlers.LinkReviewToDateRecord)
		r.Delete("/reviews/{reviewID}/date-record/{recordID}", handlers.UnlinkReviewFromDateRecord)
		r.Delete("/reviews/{reviewID}", handlers.DeleteReviewEverywhere)
		r.Post("/calendar-events/{eventID}/linked-items/remove", handlers.RemoveCalendarEventLinkedItem)
	})
}
