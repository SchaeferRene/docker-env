FROM reneschaefer/ffmpeg_base:latest as builder


FROM reneschaefer/alpine-base-armv7:latest

COPY --from=builder /opt/ffmpeg /opt/ffmpeg

ENTRYPOINT [ "/bin/sh" ]

