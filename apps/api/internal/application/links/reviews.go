package links

import (
	"context"

	appreviews "couple-calendar-api/internal/application/reviews"
)

func (s Service) LinkReviewToDateRecord(ctx context.Context, coupleID, userID, reviewID, recordID string) (ReviewLinkResult, error) {
	if coupleID == "" || userID == "" || reviewID == "" || recordID == "" {
		return ReviewLinkResult{}, appreviews.ErrInvalidReview
	}
	if err := s.requireMember(ctx, coupleID, userID); err != nil {
		return ReviewLinkResult{}, err
	}
	review, err := s.reviews.Get(ctx, coupleID, reviewID)
	if err != nil {
		return ReviewLinkResult{}, err
	}
	if review.DateRecordID != nil && *review.DateRecordID != recordID {
		if _, err := s.UnlinkReviewFromDateRecord(ctx, coupleID, userID, reviewID, *review.DateRecordID); err != nil {
			return ReviewLinkResult{}, err
		}
		review, err = s.reviews.Get(ctx, coupleID, reviewID)
		if err != nil {
			return ReviewLinkResult{}, err
		}
	}
	record, err := s.records.Get(ctx, coupleID, recordID)
	if err != nil {
		return ReviewLinkResult{}, err
	}
	review.DateRecordID = &recordID
	review.UpdatedAt = s.clock.Now()
	review, err = s.reviews.Update(ctx, review)
	if err != nil {
		return ReviewLinkResult{}, err
	}
	item := linkedItemForReview(review)
	record.LinkedItems = withLinkedItem(record.LinkedItems, item)
	record.UpdatedAt = s.clock.Now()
	record, err = s.records.Update(ctx, record)
	if err != nil {
		return ReviewLinkResult{}, err
	}
	return ReviewLinkResult{Review: review, Record: record, Item: item}, nil
}

func (s Service) UnlinkReviewFromDateRecord(ctx context.Context, coupleID, userID, reviewID, recordID string) (ReviewLinkResult, error) {
	if coupleID == "" || userID == "" || reviewID == "" || recordID == "" {
		return ReviewLinkResult{}, appreviews.ErrInvalidReview
	}
	if err := s.requireMember(ctx, coupleID, userID); err != nil {
		return ReviewLinkResult{}, err
	}
	review, err := s.reviews.Get(ctx, coupleID, reviewID)
	if err != nil {
		return ReviewLinkResult{}, err
	}
	record, err := s.records.Get(ctx, coupleID, recordID)
	if err != nil {
		return ReviewLinkResult{}, err
	}
	if review.DateRecordID != nil && *review.DateRecordID == recordID {
		review.DateRecordID = nil
		review.UpdatedAt = s.clock.Now()
		review, err = s.reviews.Update(ctx, review)
		if err != nil {
			return ReviewLinkResult{}, err
		}
	}
	item := linkedItemForReview(review)
	record.LinkedItems = removeLink(record.LinkedItems, item.Type, item.TargetID)
	record.UpdatedAt = s.clock.Now()
	record, err = s.records.Update(ctx, record)
	if err != nil {
		return ReviewLinkResult{}, err
	}
	return ReviewLinkResult{Review: review, Record: record, Item: item}, nil
}

func (s Service) DeleteReviewEverywhere(ctx context.Context, coupleID, userID, reviewID string) error {
	if coupleID == "" || userID == "" || reviewID == "" {
		return appreviews.ErrInvalidReview
	}
	if err := s.requireMember(ctx, coupleID, userID); err != nil {
		return err
	}
	review, err := s.reviews.Get(ctx, coupleID, reviewID)
	if err != nil {
		return err
	}
	if review.DateRecordID != nil {
		record, err := s.records.Get(ctx, coupleID, *review.DateRecordID)
		if err != nil {
			return err
		}
		item := linkedItemForReview(review)
		record.LinkedItems = removeLink(record.LinkedItems, item.Type, item.TargetID)
		record.UpdatedAt = s.clock.Now()
		if _, err := s.records.Update(ctx, record); err != nil {
			return err
		}
	}
	return s.reviews.Delete(ctx, coupleID, reviewID, s.clock.Now())
}
