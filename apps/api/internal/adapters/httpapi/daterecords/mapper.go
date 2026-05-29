package daterecords

import appdaterecords "couple-calendar-api/internal/application/daterecords"

func toCreateInput(coupleID string, userID string, body dateRecordMutationRequest) appdaterecords.CreateInput {
	return appdaterecords.CreateInput{
		CoupleID:      coupleID,
		UserID:        userID,
		Title:         body.Title,
		Date:          body.Date,
		Memo:          body.Memo,
		Place:         body.Place,
		Photos:        body.Photos,
		LinkedItems:   body.LinkedItems,
		LinkedEventID: body.LinkedEventID,
	}
}

func toUpdateInput(coupleID string, recordID string, userID string, body dateRecordMutationRequest) appdaterecords.UpdateInput {
	return appdaterecords.UpdateInput{
		CoupleID:      coupleID,
		RecordID:      recordID,
		UserID:        userID,
		Title:         body.Title,
		Date:          body.Date,
		Memo:          body.Memo,
		Place:         body.Place,
		Photos:        body.Photos,
		LinkedItems:   body.LinkedItems,
		LinkedEventID: body.LinkedEventID,
	}
}
