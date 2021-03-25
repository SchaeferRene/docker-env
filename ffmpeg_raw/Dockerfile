ARG DOCKER_ID=reneschaefer
ARG ARCH=armv7
ARG IMAGE_TAG=$DOCKER_ID/alpine-base-$ARCH
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION} AS builder

# build switches [<empty>|install|compile|disabled]
## auxiliary
ARG BUILDING_XML2
ARG BUILDING_FREETYPE
ARG BUILDING_FONTCONFIG
ARG BUILDING_FRIBIDI

ARG BUILDING_ARIBB24
ARG BUILDING_LIBASS
ARG BUILDING_LIBBLURAY
ARG BUILDING_LIBXCB
ARG BUILDING_OPENSSL
ARG BUILDING_SRT
ARG BUILDING_VIDSTAB
ARG BUILDING_ZEROMQ
ARG BUILDING_ZIMG
## imaging
ARG BUILDING_OPENJPEG
ARG BUILDING_WEBP
## audio
ARG BUILDING_FDKAAC
ARG BUILDING_MP3LAME
ARG BUILDING_OPENCOREAMR
ARG BUILDING_OPUS
ARG BUILDING_SOXR
ARG BUILDING_SPEEX
ARG BUILDING_THEORA
ARG BUILDING_VORBIS
## video
ARG BUILDING_AOM
ARG BUILDING_DAV1D
ARG BUILDING_DAVS2
ARG BUILDING_KVAZAAR
ARG BUILDING_VPX
ARG BUILDING_X264
ARG BUILDING_X265
ARG BUILDING_XAVS2
ARG BUILDING_XVID

WORKDIR /opt/ffmpeg

COPY compileFfmpeg-alpine.sh .

ENV PKG_CONFIG_PATH="/opt/ffmpeg/share/pkgconfig:/opt/ffmpeg/lib64/pkgconfig:/opt/ffmpeg/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:/lib64/pkgconfig:/lib/pkgconfig"
ENV LD_LIBRARY_PATH="/opt/ffmpeg/lib64:/opt/ffmpeg/lib:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/lib64:/lib"
ENV PATH="/opt/ffmpeg/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# build ffmpeg
RUN ./compileFfmpeg-alpine.sh \
# make sure binaries have no additional dependencies
	&& set -xe \
	&& /opt/ffmpeg/bin/ffmpeg -version

ENTRYPOINT [ "ffmpeg" ]
CMD [ "-version" ]
