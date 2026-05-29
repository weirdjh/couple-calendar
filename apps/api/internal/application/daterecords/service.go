package daterecords

import (
	"context"
	"sort"
	"strings"
	"time"

	"couple-calendar-api/internal/application/authz"
	"couple-calendar-api/internal/domain/links"
	"couple-calendar-api/internal/platform/clock"
	"couple-calendar-api/internal/platform/idgen"
)

type Service struct {
	repository Repository
	authorizer authz.CoupleAuthorizer
	clock      clock.Clock
	ids        idgen.Generator
}

func NewService(repository Repository, authorizer authz.CoupleAuthorizer, clock clock.Clock) Service {
	return Service{
		repository: repository,
		authorizer: authorizer,
		clock:      clock,
		ids:        idgen.Crypto{},
	}
}

type CreateInput struct {
	CoupleID      string
	UserID        string
	Title         string
	Date          time.Time
	Memo          string
	Place         *PlaceSnapshot
	Photos        []PhotoAttachment
	LinkedItems   []links.LinkedItem
	LinkedEventID *string
}

type UpdateInput struct {
	CoupleID      string
	RecordID      string
	UserID        string
	Title         string
	Date          time.Time
	Memo          string
	Place         *PlaceSnapshot
	Photos        []PhotoAttachment
	LinkedItems   []links.LinkedItem
	LinkedEventID *string
}

func (s Service) List(ctx context.Context, coupleID string, userID string) ([]DateRecord, error) {
	if coupleID == "" || userID == "" {
		return nil, ErrInvalidDateRecord
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return nil, err
	}
	records, err := s.repository.List(ctx, coupleID)
	if err != nil {
		return nil, err
	}
	sort.SliceStable(records, func(i, j int) bool {
		return records[i].Date.After(records[j].Date)
	})
	return records, nil
}

func (s Service) Create(ctx context.Context, input CreateInput) (DateRecord, error) {
	title := strings.TrimSpace(input.Title)
	if input.CoupleID == "" || input.UserID == "" || title == "" || input.Date.IsZero() {
		return DateRecord{}, ErrInvalidDateRecord
	}
	if err := s.authorizer.RequireMember(ctx, input.CoupleID, input.UserID); err != nil {
		return DateRecord{}, err
	}
	now := s.clock.Now()
	record := DateRecord{
		ID:            s.ids.NewID("date"),
		CoupleID:      input.CoupleID,
		Title:         title,
		Date:          input.Date.UTC(),
		Memo:          strings.TrimSpace(input.Memo),
		Place:         normalizePlace(input.Place),
		Photos:        normalizePhotos(input.Photos),
		LinkedItems:   append([]links.LinkedItem{}, input.LinkedItems...),
		LinkedEventID: input.LinkedEventID,
		CreatedBy:     input.UserID,
		CreatedAt:     now,
		UpdatedAt:     now,
	}
	return s.repository.Create(ctx, record)
}

func (s Service) Update(ctx context.Context, input UpdateInput) (DateRecord, error) {
	title := strings.TrimSpace(input.Title)
	if input.CoupleID == "" || input.RecordID == "" || input.UserID == "" || title == "" || input.Date.IsZero() {
		return DateRecord{}, ErrInvalidDateRecord
	}
	if err := s.authorizer.RequireMember(ctx, input.CoupleID, input.UserID); err != nil {
		return DateRecord{}, err
	}
	record, err := s.repository.Get(ctx, input.CoupleID, input.RecordID)
	if err != nil {
		return DateRecord{}, err
	}
	record.Title = title
	record.Date = input.Date.UTC()
	record.Memo = strings.TrimSpace(input.Memo)
	record.Place = normalizePlace(input.Place)
	record.Photos = normalizePhotos(input.Photos)
	record.LinkedItems = append([]links.LinkedItem{}, input.LinkedItems...)
	record.LinkedEventID = input.LinkedEventID
	record.UpdatedAt = s.clock.Now()
	return s.repository.Update(ctx, record)
}

func (s Service) Delete(ctx context.Context, coupleID string, recordID string, userID string) error {
	if coupleID == "" || recordID == "" || userID == "" {
		return ErrInvalidDateRecord
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return err
	}
	return s.repository.Delete(ctx, coupleID, recordID, s.clock.Now())
}

func (s Service) LinkCalendarEvent(ctx context.Context, coupleID string, recordID string, eventID string, userID string) (DateRecord, error) {
	if coupleID == "" || recordID == "" || eventID == "" || userID == "" {
		return DateRecord{}, ErrInvalidDateRecord
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return DateRecord{}, err
	}
	record, err := s.repository.Get(ctx, coupleID, recordID)
	if err != nil {
		return DateRecord{}, err
	}
	record.LinkedEventID = &eventID
	record.UpdatedAt = s.clock.Now()
	return s.repository.Update(ctx, record)
}

func (s Service) UnlinkCalendarEvent(ctx context.Context, coupleID string, recordID string, eventID string, userID string) (DateRecord, error) {
	if coupleID == "" || recordID == "" || eventID == "" || userID == "" {
		return DateRecord{}, ErrInvalidDateRecord
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return DateRecord{}, err
	}
	record, err := s.repository.Get(ctx, coupleID, recordID)
	if err != nil {
		return DateRecord{}, err
	}
	if record.LinkedEventID != nil && *record.LinkedEventID == eventID {
		record.LinkedEventID = nil
		record.UpdatedAt = s.clock.Now()
		return s.repository.Update(ctx, record)
	}
	return record, nil
}

func (s Service) AddLinkedItem(ctx context.Context, coupleID string, recordID string, userID string, item links.LinkedItem) (DateRecord, error) {
	if coupleID == "" || recordID == "" || userID == "" || item.Type == "" || item.TargetID == "" {
		return DateRecord{}, ErrInvalidDateRecord
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return DateRecord{}, err
	}
	record, err := s.repository.Get(ctx, coupleID, recordID)
	if err != nil {
		return DateRecord{}, err
	}
	for _, existing := range record.LinkedItems {
		if existing.Type == item.Type && existing.TargetID == item.TargetID {
			return record, nil
		}
	}
	record.LinkedItems = append(record.LinkedItems, item)
	record.UpdatedAt = s.clock.Now()
	return s.repository.Update(ctx, record)
}

func (s Service) RemoveLinkedItem(ctx context.Context, coupleID string, recordID string, userID string, item links.LinkedItem) (DateRecord, error) {
	if coupleID == "" || recordID == "" || userID == "" || item.Type == "" || item.TargetID == "" {
		return DateRecord{}, ErrInvalidDateRecord
	}
	if err := s.authorizer.RequireMember(ctx, coupleID, userID); err != nil {
		return DateRecord{}, err
	}
	record, err := s.repository.Get(ctx, coupleID, recordID)
	if err != nil {
		return DateRecord{}, err
	}
	next := make([]links.LinkedItem, 0, len(record.LinkedItems))
	for _, existing := range record.LinkedItems {
		if existing.Type == item.Type && existing.TargetID == item.TargetID {
			continue
		}
		next = append(next, existing)
	}
	record.LinkedItems = next
	record.UpdatedAt = s.clock.Now()
	return s.repository.Update(ctx, record)
}

func normalizePlace(place *PlaceSnapshot) *PlaceSnapshot {
	if place == nil || strings.TrimSpace(place.Name) == "" {
		return nil
	}
	provider := place.Provider
	if provider == "" {
		provider = PlaceProviderManual
	}
	return &PlaceSnapshot{
		Provider:        provider,
		Name:            strings.TrimSpace(place.Name),
		ProviderPlaceID: strings.TrimSpace(place.ProviderPlaceID),
		Address:         strings.TrimSpace(place.Address),
		Latitude:        place.Latitude,
		Longitude:       place.Longitude,
		URL:             strings.TrimSpace(place.URL),
	}
}

func normalizePhotos(photos []PhotoAttachment) []PhotoAttachment {
	result := make([]PhotoAttachment, 0, len(photos))
	for _, photo := range photos {
		if strings.TrimSpace(photo.ID) == "" && strings.TrimSpace(photo.Label) == "" {
			continue
		}
		result = append(result, photo)
	}
	return result
}
