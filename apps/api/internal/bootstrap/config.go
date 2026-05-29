package bootstrap

import "os"

type Config struct {
	Port               string
	RepositoryKind     string
	FirestoreProjectID string
}

func LoadConfig() Config {
	return Config{
		Port:               getenv("PORT", "8088"),
		RepositoryKind:     getenv("EVENT_REPOSITORY", "memory"),
		FirestoreProjectID: getenv("FIRESTORE_PROJECT_ID", "demo-calendar"),
	}
}

func getenv(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}
