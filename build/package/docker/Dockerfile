FROM        golang:1.20 AS builder

WORKDIR     /workspace

COPY        . .

RUN         CGO_ENABLED=0 GOOS=linux \
            go build \
                -installsuffix cgo \
                -o kube-httpcache \
                -a cmd/kube-httpcache/main.go


FROM        debian:bullseye-slim AS final

ENV         EXPORTER_VERSION=1.6.1

LABEL       MAINTAINER="Martin Helmich <m.helmich@mittwald.de>"

WORKDIR     /

RUN         set -x \
            && \
            apt-get -qq update && apt-get -qq upgrade \
            && \
            apt-get -qq install \
                debian-archive-keyring \
                curl \
                gnupg \
                apt-transport-https \
            && \
            curl -fsSL https://packagecloud.io/varnishcache/varnish60lts/gpgkey | apt-key add - \
            && \
            printf "%s\n%s" \
                "deb https://packagecloud.io/varnishcache/varnish60lts/debian/ bullseye main" \
                "deb-src https://packagecloud.io/varnishcache/varnish60lts/debian/ bullseye main" \
            > "/etc/apt/sources.list.d/varnishcache_varnish60lts.list" \
            && \
            apt-get -qq update && apt-get -qq install varnish=6.0.11-1~bullseye \
            && \
            apt-get -qq purge curl gnupg && \
            apt-get -qq autoremove && apt-get -qq autoclean && \
            rm -rf /var/cache/*

RUN         mkdir /exporter && \
            chown varnish /exporter

ADD         --chown=varnish https://github.com/jonnenauha/prometheus_varnish_exporter/releases/download/${EXPORTER_VERSION}/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz /tmp

RUN         cd /exporter && \
            tar -xzf /tmp/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz && \
            ln -sf /exporter/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-amd64/prometheus_varnish_exporter prometheus_varnish_exporter

COPY        --from=builder /workspace/kube-httpcache .

ENTRYPOINT  [ "/kube-httpcache" ]
