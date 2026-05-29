package links

import (
	"context"

	"couple-calendar-api/internal/application/authz"
	appcalendar "couple-calendar-api/internal/application/calendar"
	appdaterecords "couple-calendar-api/internal/application/daterecords"
	appreviews "couple-calendar-api/internal/application/reviews"
	apptodos "couple-calendar-api/internal/application/todos"
	domainlinks "couple-calendar-api/internal/domain/links"
	"couple-calendar-api/internal/platform/clock"
	"couple-calendar-api/internal/platform/idgen"
)

type Service struct {
	events      appcalendar.EventRepository
	records     appdaterecords.Repository
	reviews     appreviews.Repository
	todos       apptodos.Repository
	clock       clock.Clock
	ids         idgen.Generator
	eventEditor eventUpdater
	authorizer  authz.CoupleAuthorizer
}

type eventUpdater interface {
	Update(ctx context.Context, input appcalendar.UpdateEventInput) (appcalendar.Event, error)
}

func NewService(
	events appcalendar.EventRepository,
	records appdaterecords.Repository,
	reviews appreviews.Repository,
	todos apptodos.Repository,
	eventEditor eventUpdater,
	authorizer authz.CoupleAuthorizer,
	clock clock.Clock,
) Service {
	return Service{
		events:      events,
		records:     records,
		reviews:     reviews,
		todos:       todos,
		eventEditor: eventEditor,
		authorizer:  authorizer,
		clock:       clock,
		ids:         idgen.Crypto{},
	}
}

func (s Service) requireMember(ctx context.Context, coupleID, userID string) error {
	return s.authorizer.RequireMember(ctx, coupleID, userID)
}

type DateRecordResult struct {
	Record   appdaterecords.DateRecord `json:"record"`
	RecordID string                    `json:"recordId"`
}

type TodoCompletionResult struct {
	Completion   apptodos.Completion    `json:"completion"`
	LinkedItem   domainlinks.LinkedItem `json:"linkedItem"`
	DateRecordID string                 `json:"dateRecordId"`
}

type ReviewLinkResult struct {
	Review appreviews.Review         `json:"review"`
	Record appdaterecords.DateRecord `json:"record"`
	Item   domainlinks.LinkedItem    `json:"linkedItem"`
}
