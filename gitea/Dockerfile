ARG DOCKER_ID
ARG ARCH
ARG IMAGE_TAG=$DOCKER_ID/alpine-base-$ARCH
ARG IMAGE_VERSION=latest

FROM golang:alpine AS build-env

ARG GOPROXY
ENV GOPROXY ${GOPROXY:-direct}

ARG TAGS="sqlite sqlite_unlock_notify"
ENV TAGS "bindata $TAGS"
ARG CGO_EXTRA_CFLAGS

# Build
RUN \
	apk --no-cache add build-base git nodejs npm tzdata \
	&& mkdir -p /go/src/code.gitea.io \
	&& cd /go/src/code.gitea.io/ \
	&& git clone --depth 1 https://github.com/go-gitea/gitea.git \
	&& cd gitea \
	&& export NODE_OPTIONS="--max-old-space-size=2048" \
	&& make clean-all build \
	&& go build contrib/environment-to-ini/environment-to-ini.go \
	&& mkdir -p docker/root/app/gitea \
	&& mv gitea docker/root/app/gitea \
	&& mv environment-to-ini docker/root/app/gitea

# build final image
RUN echo "IMAGE="$IMAGE_TAG:$IMAGE_VERSION

FROM ${IMAGE_TAG}:${IMAGE_VERSION}

COPY --from=build-env  /go/src/code.gitea.io/gitea/docker/root /

RUN \
	apk --no-cache add \
		bash \
		ca-certificates \
		curl \
		gettext \
		git \
		linux-pam \
		openssh \
		s6 \
		sqlite \
		su-exec \
		gnupg \
	&& addgroup -S -g 1000 git \
	&& adduser -S -H -D -h /data/git -s /bin/bash -u 1000 -G git git \
	&& echo "git:$(dd if=/dev/urandom bs=24 count=1 status=none | base64)" | chpasswd \
	&& ln -s /app/gitea/gitea /usr/local/bin/gitea

ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/bin/s6-svscan", "/etc/s6"]

