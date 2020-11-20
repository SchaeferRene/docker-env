ARG DOCKER_ID=reneschaefer
ARG ARCH=armv7
ARG IMAGE_TAG=$DOCKER_ID/alpine-base-$ARCH
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION} AS builder

# build switches
ARG BUILDING_DAVS2
ARG BUILDING_HARFBUZZ
ARG BUILDING_XAVS2

WORKDIR /opt/ffmpeg

COPY compileFfmpeg-alpine.sh .

# build ffmpeg
RUN ./compileFfmpeg-alpine.sh \
# make sure binaries have no additional dependencies
	&& set -xe \
	&& test $(ldd /opt/ffmpeg/bin/ffmpeg | wc -l) -eq 1 \
	&& test $(ldd /opt/ffmpeg/bin/ffprobe | wc -l) -eq 1

# copy build artifacts
FROM ${IMAGE_TAG}:${IMAGE_VERSION}
COPY --from=builder /opt/ffmpeg/bin/ffmpeg /opt/ffmpeg/bin/ffprobe /usr/local/bin/
COPY --from=builder /etc/ssl/cert.pem /etc/ssl/cert.pem

# sanity checks 
RUN set -xe \
	&& ffmpeg -version \
	&& ffprobe -version 

ENTRYPOINT [ "ffmpeg" ]
CMD [ "-version" ]
