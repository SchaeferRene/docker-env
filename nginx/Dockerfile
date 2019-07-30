ARG IMAGE_TAG=armv7lxu4/alpine-base-armv7
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION}

ARG NGINX_MODULES
ENV NGINX_MODULES $NGINX_MODULES

RUN set -x \
    #&& apk update \
    && apk add --no-cache $NGINX_MODULES \
    && mkdir -p /usr/share/www/ /run/nginx/

EXPOSE 80 443

STOPSIGNAL SIGTERM

ENTRYPOINT [ "/usr/sbin/nginx", "-g", "daemon off;" ]
