package daterecords

import (
	"context"
	"errors"
	"time"

	"cloud.google.com/go/firestore"
	"couple-calendar-api/internal/application/calendar"
	"couple-calendar-api/internal/application/daterecords"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type DateRecordRepository struct {
	client *firestore.Client
}

func NewDateRecordRepository(client *firestore.Client) DateRecordRepository {
	return DateRecordRepository{client: client}
}

func (r DateRecordRepository) List(ctx context.Context, coupleID string) ([]daterecords.DateRecord, error) {
	iter := r.records(coupleID).
		Where("deletedAt", "==", nil).
		Documents(ctx)
	defer iter.Stop()

	records := []daterecords.DateRecord{}
	for {
		doc, err := iter.Next()
		if errors.Is(err, iterator.Done) {
			break
		}
		if err != nil {
			return nil, err
		}
		record, err := dateRecordFromDocument(doc)
		if err != nil {
			return nil, err
		}
		records = append(records, record)
	}
	return records, nil
}

func (r DateRecordRepository) Create(ctx context.Context, record daterecords.DateRecord) (daterecords.DateRecord, error) {
	_, err := r.records(record.CoupleID).Doc(record.ID).Set(ctx, dateRecordToDocument(record))
	if err != nil {
		return daterecords.DateRecord{}, err
	}
	return record, nil
}

func (r DateRecordRepository) Get(ctx context.Context, coupleID string, recordID string) (daterecords.DateRecord, error) {
	doc, err := r.records(coupleID).Doc(recordID).Get(ctx)
	if status.Code(err) == codes.NotFound {
		return daterecords.DateRecord{}, daterecords.ErrDateRecordNotFound
	}
	if err != nil {
		return daterecords.DateRecord{}, err
	}
	record, err := dateRecordFromDocument(doc)
	if err != nil {
		return daterecords.DateRecord{}, err
	}
	if record.DeletedAt != nil {
		return daterecords.DateRecord{}, daterecords.ErrDateRecordNotFound
	}
	return record, nil
}

func (r DateRecordRepository) Update(ctx context.Context, record daterecords.DateRecord) (daterecords.DateRecord, error) {
	_, err := r.records(record.CoupleID).Doc(record.ID).Set(ctx, dateRecordToDocument(record))
	if err != nil {
		return daterecords.DateRecord{}, err
	}
	return record, nil
}

func (r DateRecordRepository) Delete(ctx context.Context, coupleID string, recordID string, deletedAt time.Time) error {
	_, err := r.records(coupleID).Doc(recordID).Update(ctx, []firestore.Update{
		{Path: "deletedAt", Value: deletedAt.UTC()},
		{Path: "updatedAt", Value: deletedAt.UTC()},
	})
	if status.Code(err) == codes.NotFound {
		return daterecords.ErrDateRecordNotFound
	}
	return err
}

func (r DateRecordRepository) records(coupleID string) *firestore.CollectionRef {
	return r.client.Collection("couples").Doc(coupleID).Collection("dateRecords")
}

func dateRecordFromDocument(doc *firestore.DocumentSnapshot) (daterecords.DateRecord, error) {
	var stored dateRecordDocument
	if err := doc.DataTo(&stored); err != nil {
		return daterecords.DateRecord{}, err
	}
	record := daterecords.DateRecord{
		ID:            doc.Ref.ID,
		CoupleID:      stored.CoupleID,
		Title:         stored.Title,
		Date:          stored.Date,
		Memo:          stored.Memo,
		Place:         placeFromDocument(stored.Place),
		Photos:        photosFromDocuments(stored.Photos),
		LinkedItems:   linkedItemsFromDocuments(stored.LinkedItems),
		LinkedEventID: stored.LinkedEventID,
		CreatedBy:     stored.CreatedBy,
		CreatedAt:     stored.CreatedAt,
		UpdatedAt:     stored.UpdatedAt,
		DeletedAt:     stored.DeletedAt,
	}
	if record.Photos == nil {
		record.Photos = []daterecords.PhotoAttachment{}
	}
	if record.LinkedItems == nil {
		record.LinkedItems = []calendar.LinkedItem{}
	}
	return record, nil
}

func dateRecordToDocument(record daterecords.DateRecord) dateRecordDocument {
	return dateRecordDocument{
		CoupleID:      record.CoupleID,
		Title:         record.Title,
		Date:          record.Date.UTC(),
		Memo:          record.Memo,
		Place:         placeToDocument(record.Place),
		Photos:        photosToDocuments(record.Photos),
		LinkedItems:   linkedItemsToDocuments(record.LinkedItems),
		LinkedEventID: record.LinkedEventID,
		CreatedBy:     record.CreatedBy,
		CreatedAt:     record.CreatedAt.UTC(),
		UpdatedAt:     record.UpdatedAt.UTC(),
		DeletedAt:     record.DeletedAt,
	}
}

type dateRecordDocument struct {
	CoupleID      string               `firestore:"coupleId"`
	Title         string               `firestore:"title"`
	Date          time.Time            `firestore:"date"`
	Memo          string               `firestore:"memo"`
	Place         *placeDocument       `firestore:"place"`
	Photos        []photoDocument      `firestore:"photos"`
	LinkedItems   []linkedItemDocument `firestore:"linkedItems"`
	LinkedEventID *string              `firestore:"linkedEventId"`
	CreatedBy     string               `firestore:"createdBy"`
	CreatedAt     time.Time            `firestore:"createdAt"`
	UpdatedAt     time.Time            `firestore:"updatedAt"`
	DeletedAt     *time.Time           `firestore:"deletedAt"`
}

type placeDocument struct {
	Provider        string   `firestore:"provider"`
	Name            string   `firestore:"name"`
	ProviderPlaceID string   `firestore:"providerPlaceId,omitempty"`
	Address         string   `firestore:"address,omitempty"`
	Latitude        *float64 `firestore:"latitude,omitempty"`
	Longitude       *float64 `firestore:"longitude,omitempty"`
	URL             string   `firestore:"url,omitempty"`
}

type photoDocument struct {
	ID          string     `firestore:"id"`
	Label       string     `firestore:"label"`
	StoragePath string     `firestore:"storagePath,omitempty"`
	DownloadURL string     `firestore:"downloadUrl,omitempty"`
	CreatedAt   *time.Time `firestore:"createdAt,omitempty"`
}

type linkedItemDocument struct {
	Type         string     `firestore:"type"`
	TargetID     string     `firestore:"targetId"`
	TargetPath   string     `firestore:"targetPath,omitempty"`
	Title        string     `firestore:"title"`
	Subtitle     string     `firestore:"subtitle,omitempty"`
	Date         *time.Time `firestore:"date,omitempty"`
	ThumbnailURL string     `firestore:"thumbnailUrl,omitempty"`
	Preview      string     `firestore:"preview,omitempty"`
	Emoji        string     `firestore:"emoji,omitempty"`
	CreatedAt    time.Time  `firestore:"createdAt"`
}

func placeFromDocument(document *placeDocument) *daterecords.PlaceSnapshot {
	if document == nil {
		return nil
	}
	return &daterecords.PlaceSnapshot{
		Provider:        daterecords.PlaceProvider(document.Provider),
		Name:            document.Name,
		ProviderPlaceID: document.ProviderPlaceID,
		Address:         document.Address,
		Latitude:        document.Latitude,
		Longitude:       document.Longitude,
		URL:             document.URL,
	}
}

func placeToDocument(place *daterecords.PlaceSnapshot) *placeDocument {
	if place == nil {
		return nil
	}
	return &placeDocument{
		Provider:        string(place.Provider),
		Name:            place.Name,
		ProviderPlaceID: place.ProviderPlaceID,
		Address:         place.Address,
		Latitude:        place.Latitude,
		Longitude:       place.Longitude,
		URL:             place.URL,
	}
}

func photosFromDocuments(documents []photoDocument) []daterecords.PhotoAttachment {
	photos := make([]daterecords.PhotoAttachment, 0, len(documents))
	for _, document := range documents {
		photos = append(photos, daterecords.PhotoAttachment{
			ID:          document.ID,
			Label:       document.Label,
			StoragePath: document.StoragePath,
			DownloadURL: document.DownloadURL,
			CreatedAt:   document.CreatedAt,
		})
	}
	return photos
}

func photosToDocuments(photos []daterecords.PhotoAttachment) []photoDocument {
	documents := make([]photoDocument, 0, len(photos))
	for _, photo := range photos {
		documents = append(documents, photoDocument{
			ID:          photo.ID,
			Label:       photo.Label,
			StoragePath: photo.StoragePath,
			DownloadURL: photo.DownloadURL,
			CreatedAt:   photo.CreatedAt,
		})
	}
	return documents
}

func linkedItemsFromDocuments(documents []linkedItemDocument) []calendar.LinkedItem {
	items := make([]calendar.LinkedItem, 0, len(documents))
	for _, document := range documents {
		items = append(items, calendar.LinkedItem{
			Type:         document.Type,
			TargetID:     document.TargetID,
			TargetPath:   document.TargetPath,
			Title:        document.Title,
			Subtitle:     document.Subtitle,
			Date:         document.Date,
			ThumbnailURL: document.ThumbnailURL,
			Preview:      document.Preview,
			Emoji:        document.Emoji,
			CreatedAt:    document.CreatedAt,
		})
	}
	return items
}

func linkedItemsToDocuments(items []calendar.LinkedItem) []linkedItemDocument {
	documents := make([]linkedItemDocument, 0, len(items))
	for _, item := range items {
		documents = append(documents, linkedItemDocument{
			Type:         item.Type,
			TargetID:     item.TargetID,
			TargetPath:   item.TargetPath,
			Title:        item.Title,
			Subtitle:     item.Subtitle,
			Date:         item.Date,
			ThumbnailURL: item.ThumbnailURL,
			Preview:      item.Preview,
			Emoji:        item.Emoji,
			CreatedAt:    item.CreatedAt.UTC(),
		})
	}
	return documents
}
