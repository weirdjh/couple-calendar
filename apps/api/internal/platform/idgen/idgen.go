package idgen

import (
	"crypto/rand"
	"encoding/hex"
	"time"
)

type Generator interface {
	NewID(prefix string) string
}

type Crypto struct{}

func (Crypto) NewID(prefix string) string {
	bytes := make([]byte, 12)
	if _, err := rand.Read(bytes); err != nil {
		return prefix + "-" + time.Now().UTC().Format("20060102150405")
	}
	return prefix + "-" + hex.EncodeToString(bytes)
}
