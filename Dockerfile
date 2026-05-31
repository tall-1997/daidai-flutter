FROM --platform=$BUILDPLATFORM node:20.19.0-bookworm-slim AS frontend-builder

WORKDIR /build
COPY web/package.json web/package-lock.json ./
RUN npm ci --registry https://registry.npmmirror.com
COPY web/ ./
RUN npm run build


FROM --platform=$BUILDPLATFORM golang:1.25-alpine AS backend-builder

RUN apk add --no-cache git

WORKDIR /build
COPY server/go.mod server/go.sum ./
ENV GOPROXY=https://goproxy.cn,direct
RUN go mod download
COPY server/ ./
ARG VERSION=2.2.11
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
RUN GOARM=$(case "${TARGETVARIANT}" in v7) echo 7;; v6) echo 6;; v5) echo 5;; *) echo '';; esac) && \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} GOARM=${GOARM} \
    go build -ldflags="-s -w -X daidai-panel/handler.Version=${VERSION}" -o daidai-server . && \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} GOARM=${GOARM} \
    go build -ldflags="-s -w -X daidai-panel/handler.Version=${VERSION}" -o ddp ./cmd/ddp


FROM alpine:3.19

RUN apk add --no-cache \
    ca-certificates tzdata bash curl wget \
    gcompat libc6-compat libstdc++ \
    nginx \
    python3 py3-pip \
    nodejs npm \
    go \
    git openssh-client \
    docker-cli \
    su-exec shadow

RUN mkdir -p /app/Dumb-Panel/scripts /app/Dumb-Panel/logs /app/Dumb-Panel/backups /run/nginx /tmp && chmod 1777 /tmp

WORKDIR /app

COPY --from=backend-builder /build/daidai-server .
COPY --from=backend-builder /build/ddp /usr/local/bin/ddp
COPY --from=backend-builder /build/config.yaml .
COPY --from=frontend-builder /build/dist /app/web
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh /usr/local/bin/ddp && sed -i 's/\r$//' /app/entrypoint.sh

ENV TZ=Asia/Shanghai
ENV PANEL_PORT=5700

EXPOSE ${PANEL_PORT}

VOLUME ["/app/Dumb-Panel"]

# 容器健康检查：飞牛 OS / 群晖等 NAS 容器面板依赖此标记容器状态。
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget --quiet --tries=1 --spider "http://127.0.0.1:${PANEL_PORT}/api/v1/health" || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
