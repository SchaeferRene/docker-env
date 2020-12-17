ARG DOCKER_ID=reneschaefer
ARG ARCH=armv7
ARG IMAGE_TAG=$DOCKER_ID/alpine-base-$ARCH
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION} AS builder

# build switches [<empty>|install|compile|disabled]
ARG BUILDING_AOM
ARG BUILDING_ASS
ARG BUILDING_CAIRO
ARG BUILDING_DAV1D
ARG BUILDING_DAVS2
ARG BUILDING_FDKAAC
ARG BUILDING_FONTCONFIG
ARG BUILDING_FREETYPE
ARG BUILDING_FRIBIDI
ARG BUILDING_GLIB2
ARG BUILDING_GRAPHITE2
ARG BUILDING_HARFBUZZ
ARG BUILDING_KVAZAAR
ARG BUILDING_LIBPNG
ARG BUILDING_MP3LAME
ARG BUILDING_OPENJPEG
ARG BUILDING_OPENSSL
ARG BUILDING_OPUS
ARG BUILDING_SOXR
ARG BUILDING_SPEEX
ARG BUILDING_THEORA
ARG BUILDING_VORBIS
ARG BUILDING_VPX
ARG BUILDING_WEBP
ARG BUILDING_X264
ARG BUILDING_X265
ARG BUILDING_XAVS2
ARG BUILDING_XML2
ARG BUILDING_XVID
ARG BUILDING_ZIMG

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
