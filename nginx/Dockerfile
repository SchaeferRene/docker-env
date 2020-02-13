ARG DOCKER_ID
ARG ARCH
ARG IMAGE_TAG=$DOCKER_ID/alpine-base-$ARCH
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION}

FROM ${IMAGE_TAG}:${IMAGE_VERSION}

ARG NGINX_MODULES
ENV NGINX_MODULES $NGINX_MODULES

RUN set -x \
    && apk add --no-cache $NGINX_MODULES \
    && mkdir -p /nginx/www/ /run/nginx/

EXPOSE 80 443

ENTRYPOINT [ "/usr/sbin/nginx", "-g", "daemon off;" ]
