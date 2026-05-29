package couples

import "time"

type Couple struct {
	ID                    string     `json:"id"`
	MemberIDs             []string   `json:"memberIds"`
	InviteCode            string     `json:"inviteCode"`
	PartnerDisplayName    string     `json:"partnerDisplayName,omitempty"`
	RelationshipStartDate *time.Time `json:"relationshipStartDate,omitempty"`
	CreatedAt             time.Time  `json:"createdAt"`
	DeletedAt             *time.Time `json:"deletedAt,omitempty"`
}
