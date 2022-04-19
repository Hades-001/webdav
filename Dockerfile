FROM --platform=${TARGETPLATFORM} golang:1.18-alpine as builder
ARG CGO_ENABLED=0
ARG TAG

WORKDIR /root
RUN set -ex && \
	apk add --update git && \
	git clone https://github.com/hacdias/webdav.git webdav && \
	cd ./webdav && \
	git fetch --all --tags && \
	git checkout tags/${TAG} && \
	go build -ldflags "-s -w -X main.version=${TAG}" -trimpath -o webdav

FROM --platform=${TARGETPLATFORM} alpine:latest
COPY --from=builder /root/webdav/webdav /usr/bin/

RUN apk add --no-cache ca-certificates su-exec tzdata libcap

RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/webdav

RUN mkdir /etc/webdav

VOLUME ["/etc/webdav"]

WORKDIR /etc/webdav

ENV TZ=Asia/Shanghai
RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
	echo "${TZ}" > /etc/timezone

ENV PUID=1000 PGID=1000 HOME=/etc/webdav

COPY docker-entrypoint.sh /bin/entrypoint.sh
RUN chmod a+x /bin/entrypoint.sh
ENTRYPOINT ["/bin/entrypoint.sh"]

CMD /usr/bin/webdav -c /etc/webdav/config.yaml