ARG DOCKER_ID
ARG ARCH
ARG IMAGE_TAG=$DOCKER_ID/alpine-base-$ARCH
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION}

RUN set -xe \
    && apk add --no-cache youtube-dl ffmpeg \
    && rm -rf /var/cache/apk/*

WORKDIR /downloads
VOLUME [ "/downloads" ]

ENTRYPOINT [ "youtube-dl" ]
CMD [ "--version" ]
