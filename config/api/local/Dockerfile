FROM golang:1.25-bookworm

WORKDIR /workspace/apps/api

COPY apps/api/go.mod apps/api/go.sum* ./
RUN go mod download

COPY apps/api ./

EXPOSE 8088

CMD ["go", "run", "./cmd/server"]
