package daterecords

import (
	"context"
	"sync"
	"time"

	"couple-calendar-api/internal/application/daterecords"
)

type DateRecordRepository struct {
	mu      sync.RWMutex
	records map[string]daterecords.DateRecord
}

func NewDateRecordRepository() *DateRecordRepository {
	return &DateRecordRepository{records: map[string]daterecords.DateRecord{}}
}

func (r *DateRecordRepository) List(ctx context.Context, coupleID string) ([]daterecords.DateRecord, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	records := []daterecords.DateRecord{}
	for _, record := range r.records {
		if record.CoupleID == coupleID && record.DeletedAt == nil {
			records = append(records, record)
		}
	}
	return records, nil
}

func (r *DateRecordRepository) Create(ctx context.Context, record daterecords.DateRecord) (daterecords.DateRecord, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.records[key(record.CoupleID, record.ID)] = record
	return record, nil
}

func (r *DateRecordRepository) Get(ctx context.Context, coupleID string, recordID string) (daterecords.DateRecord, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.records[key(coupleID, recordID)]
	if !ok || record.DeletedAt != nil {
		return daterecords.DateRecord{}, daterecords.ErrDateRecordNotFound
	}
	return record, nil
}

func (r *DateRecordRepository) Update(ctx context.Context, record daterecords.DateRecord) (daterecords.DateRecord, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	recordKey := key(record.CoupleID, record.ID)
	if _, ok := r.records[recordKey]; !ok {
		return daterecords.DateRecord{}, daterecords.ErrDateRecordNotFound
	}
	r.records[recordKey] = record
	return record, nil
}

func (r *DateRecordRepository) Delete(ctx context.Context, coupleID string, recordID string, deletedAt time.Time) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	recordKey := key(coupleID, recordID)
	record, ok := r.records[recordKey]
	if !ok || record.DeletedAt != nil {
		return daterecords.ErrDateRecordNotFound
	}
	deletedAt = deletedAt.UTC()
	record.DeletedAt = &deletedAt
	record.UpdatedAt = deletedAt
	r.records[recordKey] = record
	return nil
}

func key(coupleID string, recordID string) string {
	return coupleID + "/" + recordID
}
