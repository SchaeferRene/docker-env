ARG DEBIAN_BASE=debian:bullseye-slim

FROM ${DEBIAN_BASE} AS builder

WORKDIR /opt/ffmpeg

COPY compileFfmpeg.sh .

# build ffmpeg
RUN ./compileFfmpeg.sh \
# make sure binaries have no additional dependencies
	&& set -xe \
	&& test $(ldd /opt/ffmpeg/bin/ffmpeg | wc -l) -eq 1 \
	&& test $(ldd /opt/ffmpeg/bin/ffprobe | wc -l) -eq 1

# copy build artifacts
FROM ${DEBIAN_BASE}
COPY --from=builder /opt/ffmpeg/bin/ffmpeg /opt/ffmpeg/bin/ffprobe /usr/local/bin/
COPY --from=builder /etc/ssl/cert.pem /etc/ssl/cert.pem

# sanity checks 
RUN set -xe \
	&& ffmpeg -version \
	&& ffprobe -version 

ENTRYPOINT [ "ffmpeg" ]
CMD [ "-version" ]
