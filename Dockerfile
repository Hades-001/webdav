FROM --platform=${TARGETPLATFORM} golang:1.18-bullseye as builder

ARG CGO_ENABLED=0
ARG TAG
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /root
RUN set -ex && \
	apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates git libcap2-bin && \
	git clone https://github.com/hacdias/webdav.git webdav && \
	cd ./webdav && \
	git fetch --all --tags && \
	git checkout tags/${TAG} && \
	go build -ldflags "-s -w -X main.version=${TAG}" -trimpath -o webdav && \
	setcap CAP_NET_BIND_SERVICE=+eip webdav

FROM --platform=${TARGETPLATFORM} gcr.io/distroless/static-debian11
COPY --from=builder /root/webdav/webdav /usr/bin/

ENV TZ=Asia/Shanghai
ENV PUID=1000 PGID=1000

USER "${PUID}":"${PGID}"

CMD [ "/usr/bin/webdav" ]
