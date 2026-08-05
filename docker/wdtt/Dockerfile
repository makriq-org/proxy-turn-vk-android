FROM golang:1.25-bookworm AS builder

WORKDIR /src

COPY go.mod ./
COPY server.go ./

RUN go mod tidy

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /out/wdtt-server ./server.go

FROM debian:bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/makriq-org/proxy-turn-vk-android" \
      org.opencontainers.image.description="qWDTT server"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates iproute2 iptables nftables \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/wdtt-server /usr/local/bin/wdtt-server
COPY docker/wdtt/entrypoint.sh /entrypoint.sh

RUN chmod 0755 /usr/local/bin/wdtt-server /entrypoint.sh \
    && mkdir -p /etc/wdtt

VOLUME ["/etc/wdtt"]

ENTRYPOINT ["/entrypoint.sh"]
