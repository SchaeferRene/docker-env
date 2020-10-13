ARG DEBIAN_BASE=debian:bullseye-slim

FROM ${DEBIAN_BASE} AS builder

# build switches
ARG BUILDING_DAVS2
ARG BUILDING_HARFBUZZ
ARG BUILDING_XAVS2

WORKDIR /opt/ffmpeg

COPY compileFfmpeg-debian.sh .

# build ffmpeg
RUN ./compileFfmpeg-debian.sh \
# make sure binaries have no additional dependencies
#	&& set -xe \
	&& test $(ldd /opt/ffmpeg/bin/ffmpeg | wc -l) -eq 0 \
	&& test $(ldd /opt/ffmpeg/bin/ffprobe | wc -l) -eq 0

# copy build artifacts
FROM ${DEBIAN_BASE}
COPY --from=builder /opt/ffmpeg/bin/ffmpeg /opt/ffmpeg/bin/ffprobe /usr/local/bin/
COPY --from=builder /etc/ssl/certs/certSIGN_ROOT_CA.pem /etc/ssl/certs/certSIGN_ROOT_CA.pem

# sanity checks 
RUN set -xe \
	&& ffmpeg -version \
	&& ffprobe -version 

ENTRYPOINT [ "ffmpeg" ]
CMD [ "-version" ]
