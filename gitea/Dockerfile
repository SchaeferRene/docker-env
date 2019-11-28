ARG IMAGE_TAG=reneschaefer/alpine-base
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION}

RUN set -x \
    && apk add --no-cache gitea; \
    addgroup -S -g 1000 git && \
	adduser -S -H -D -h /data/git -s /bin/sh -u 1000 -G git git && \
  	echo "git:$(dd if=/dev/urandom bs=24 count=1 status=none | base64)" | chpasswd

#ENV USER git
#ENV GITEA_CUSTOM /data/gitea 

EXPOSE 22 3000

ENTRYPOINT [ "/bin/sh" ]
