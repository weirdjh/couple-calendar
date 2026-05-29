package main

import (
	"context"
	"log"
	"net/http"
	"time"

	"couple-calendar-api/internal/bootstrap"
)

func main() {
	container := bootstrap.NewContainer(context.Background(), bootstrap.LoadConfig())
	defer container.Cleanup()

	server := &http.Server{
		Addr:              ":" + container.Config.Port,
		Handler:           container.Router,
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Printf("api server listening on :%s", container.Config.Port)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}
