ARG DOCKER_ID
ARG ARCH
ARG IMAGE_TAG=$DOCKER_ID/alpine-base-$ARCH
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION}

ENV PULSE_SERVER=/tmp/pulse-socket

ARG PULSE_UUID
ENV PULSE_UUID $PULSE_UUID
ARG PULSE_GUID
ENV PULSE_GUID $PULSE_GUID

EXPOSE 6600 8080

RUN set -xe \
    && addgroup -g $PULSE_GUID -S mpd \
    && adduser -u $PULSE_UUID -G mpd -h /home/mpd -D mpd \
    && apk add --no-cache \
      alsa-lib \
      alsa-plugins-pulse \
      alsa-utils \
      libpulse \
      mpc \
      mpd \
      netcat-openbsd \
      tini \
    && rm -rf /var/cache/apk/*

COPY root/ /

User mpd

ENTRYPOINT [ "/sbin/tini", "--", "/usr/local/bin/mpd-watchdog.sh" ]

