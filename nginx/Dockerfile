ARG IMAGE_TAG=reneschaefer/alpine-base
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION}

ARG NGINX_MODULES
ENV NGINX_MODULES $NGINX_MODULES

RUN set -x \
    && apk add --no-cache $NGINX_MODULES \
    && mkdir -p /nginx/www/ /run/nginx/

EXPOSE 80 443

STOPSIGNAL SIGTERM

ENTRYPOINT [ "/usr/sbin/nginx", "-g", "daemon off;" ]
