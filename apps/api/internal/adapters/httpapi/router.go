package httpapi

import (
	"net/http"

	anniversarieshttp "couple-calendar-api/internal/adapters/httpapi/anniversaries"
	calendarhttp "couple-calendar-api/internal/adapters/httpapi/calendar"
	coupleshttp "couple-calendar-api/internal/adapters/httpapi/couples"
	daterecordshttp "couple-calendar-api/internal/adapters/httpapi/daterecords"
	"couple-calendar-api/internal/adapters/httpapi/httputil"
	linkshttp "couple-calendar-api/internal/adapters/httpapi/links"
	reviewshttp "couple-calendar-api/internal/adapters/httpapi/reviews"
	todoshttp "couple-calendar-api/internal/adapters/httpapi/todos"
	appanniversaries "couple-calendar-api/internal/application/anniversaries"
	appcalendar "couple-calendar-api/internal/application/calendar"
	appcouples "couple-calendar-api/internal/application/couples"
	appdaterecords "couple-calendar-api/internal/application/daterecords"
	applinks "couple-calendar-api/internal/application/links"
	appreviews "couple-calendar-api/internal/application/reviews"
	apptodos "couple-calendar-api/internal/application/todos"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

type Dependencies struct {
	CalendarEvents appcalendar.EventService
	DateRecords    appdaterecords.Service
	Todos          apptodos.Service
	Reviews        appreviews.Service
	Anniversaries  appanniversaries.Service
	Couples        appcouples.Service
	Links          applinks.Service
}

func NewRouter(deps Dependencies) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Recoverer)
	r.Use(cors)
	r.Use(requireUser)

	r.Get("/healthz", func(w http.ResponseWriter, r *http.Request) {
		httputil.WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})

	calendarhttp.MountRoutes(r, calendarhttp.NewHandlers(deps.CalendarEvents))
	daterecordshttp.MountRoutes(r, daterecordshttp.NewHandlers(deps.DateRecords))
	todoshttp.MountRoutes(r, todoshttp.NewHandlers(deps.Todos))
	reviewshttp.MountRoutes(r, reviewshttp.NewHandlers(deps.Reviews))
	anniversarieshttp.MountRoutes(r, anniversarieshttp.NewHandlers(deps.Anniversaries))
	coupleshttp.MountRoutes(r, coupleshttp.NewHandlers(deps.Couples))
	linkshttp.MountRoutes(r, linkshttp.NewHandlers(deps.Links))

	return r
}
