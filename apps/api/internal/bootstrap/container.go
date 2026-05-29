package bootstrap

import (
	"context"
	"log"
	"net/http"

	"cloud.google.com/go/firestore"
	"couple-calendar-api/internal/adapters/httpapi"
	firestoreanniversaries "couple-calendar-api/internal/adapters/persistence/firestore/anniversaries"
	firestorecalendar "couple-calendar-api/internal/adapters/persistence/firestore/calendar"
	firestorecouples "couple-calendar-api/internal/adapters/persistence/firestore/couples"
	firestoredaterecords "couple-calendar-api/internal/adapters/persistence/firestore/daterecords"
	firestorereviews "couple-calendar-api/internal/adapters/persistence/firestore/reviews"
	firestoretodos "couple-calendar-api/internal/adapters/persistence/firestore/todos"
	memoryanniversaries "couple-calendar-api/internal/adapters/persistence/memory/anniversaries"
	memorycalendar "couple-calendar-api/internal/adapters/persistence/memory/calendar"
	memorycouples "couple-calendar-api/internal/adapters/persistence/memory/couples"
	memorydaterecords "couple-calendar-api/internal/adapters/persistence/memory/daterecords"
	memoryreviews "couple-calendar-api/internal/adapters/persistence/memory/reviews"
	memorytodos "couple-calendar-api/internal/adapters/persistence/memory/todos"
	"couple-calendar-api/internal/application/anniversaries"
	"couple-calendar-api/internal/application/authz"
	"couple-calendar-api/internal/application/calendar"
	"couple-calendar-api/internal/application/couples"
	"couple-calendar-api/internal/application/daterecords"
	"couple-calendar-api/internal/application/links"
	"couple-calendar-api/internal/application/reviews"
	"couple-calendar-api/internal/application/todos"
	"couple-calendar-api/internal/platform/clock"
)

type Container struct {
	Config  Config
	Router  http.Handler
	cleanup func()
}

func NewContainer(ctx context.Context, config Config) Container {
	repositories, cleanup := newRepositories(ctx, config)
	authorizer := authz.NewRepositoryAuthorizer(repositories.couples)
	eventService := calendar.NewEventService(repositories.events, authorizer, clock.System{})
	dateRecordService := daterecords.NewService(repositories.dateRecords, authorizer, clock.System{})
	todoService := todos.NewService(repositories.todos, authorizer, clock.System{})
	linkService := links.NewService(
		repositories.events,
		repositories.dateRecords,
		repositories.reviews,
		repositories.todos,
		eventService,
		authorizer,
		clock.System{},
	)

	return Container{
		Config: config,
		Router: httpapi.NewRouter(httpapi.Dependencies{
			CalendarEvents: eventService,
			DateRecords:    dateRecordService,
			Todos:          todoService,
			Reviews:        reviews.NewService(repositories.reviews, authorizer, clock.System{}),
			Anniversaries:  anniversaries.NewService(repositories.anniversaries, authorizer, clock.System{}),
			Couples:        couples.NewService(repositories.couples, clock.System{}),
			Links:          linkService,
		}),
		cleanup: cleanup,
	}
}

func (c Container) Cleanup() {
	c.cleanup()
}

type repositories struct {
	events        calendar.EventRepository
	dateRecords   daterecords.Repository
	todos         todos.Repository
	reviews       reviews.Repository
	anniversaries anniversaries.Repository
	couples       couples.Repository
}

func newRepositories(ctx context.Context, config Config) (repositories, func()) {
	if config.RepositoryKind != "firestore" {
		log.Printf("using in-memory repositories")
		return repositories{
			events:        memorycalendar.NewCalendarEventRepository(),
			dateRecords:   memorydaterecords.NewDateRecordRepository(),
			todos:         memorytodos.NewRepository(),
			reviews:       memoryreviews.NewRepository(),
			anniversaries: memoryanniversaries.NewRepository(),
			couples:       memorycouples.NewRepository(),
		}, func() {}
	}

	client, err := firestore.NewClient(ctx, config.FirestoreProjectID)
	if err != nil {
		log.Fatalf("create firestore client: %v", err)
	}
	log.Printf("using firestore repositories for project %s", config.FirestoreProjectID)
	return repositories{
			events:        firestorecalendar.NewCalendarEventRepository(client),
			dateRecords:   firestoredaterecords.NewDateRecordRepository(client),
			todos:         firestoretodos.NewRepository(client),
			reviews:       firestorereviews.NewRepository(client),
			anniversaries: firestoreanniversaries.NewRepository(client),
			couples:       firestorecouples.NewRepository(client),
		}, func() {
			if err := client.Close(); err != nil {
				log.Printf("close firestore client: %v", err)
			}
		}
}
