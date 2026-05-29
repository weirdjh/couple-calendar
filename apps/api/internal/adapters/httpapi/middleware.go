package httpapi

import (
	"net/http"
	"strings"

	"couple-calendar-api/internal/adapters/httpapi/httputil"
	"couple-calendar-api/internal/adapters/httpapi/requestctx"
)

const (
	bearerPrefix    = "Bearer "
	devUserIDHeader = "X-Dev-User-Id"
)

func cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Dev-User-Id")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func requireUser(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/healthz" || r.Method == http.MethodOptions {
			next.ServeHTTP(w, r)
			return
		}
		userID := strings.TrimSpace(r.Header.Get(devUserIDHeader))
		if userID == "" && bearerToken(r.Header.Get("Authorization")) != "" {
			httputil.WriteError(w, http.StatusUnauthorized, "authorization token auth is not implemented")
			return
		}
		if userID == "" {
			httputil.WriteError(w, http.StatusUnauthorized, "missing X-Dev-User-Id")
			return
		}
		next.ServeHTTP(w, r.WithContext(requestctx.WithUserID(r.Context(), userID)))
	})
}

func bearerToken(header string) string {
	header = strings.TrimSpace(header)
	if !strings.HasPrefix(header, bearerPrefix) {
		return ""
	}
	return strings.TrimSpace(strings.TrimPrefix(header, bearerPrefix))
}
