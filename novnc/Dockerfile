ARG DOCKER_ID
ARG ARCH
ARG IMAGE_TAG=$DOCKER_ID/alpine-base-$ARCH
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY_WIDTH=1280
ENV DISPLAY_HEIGHT=720

RUN set -x \
# install dependencies
	&& apk add --no-cache \
		bash \
		git \
		openbox \
		python3 \
		py3-numpy \
		supervisor \
		ttf-dejavu \
		x11vnc \
		xvfb \
# check out code
	&& git clone --depth 1 https://github.com/novnc/noVNC.git /root/noVNC \
	&& git clone --depth 1 https://github.com/novnc/websockify /root/noVNC/utils/websockify \
	&& rm -rf /root/noVNC/.git \
	&& rm -rf /root/noVNC/utils/websockify/.git \
# fixes
	&& ln -s /usr/bin/python3 /usr/bin/python \
	&& sed -i -- "s/ps -p/ps -o pid | grep/g" /root/noVNC/utils/launch.sh \
	&& ln -s /root/noVNC/vnc.html /root/noVNC/index.html \
	&& 2to3 -w -n /usr/libexec/openbox-xdg-autostart \
# cleanup
	&& apk del git \
	&& rm -f /var/cache/apk/* \
	&& rm -rf /var/cache/fontconfig/* \
# setup
	&& { \
		echo '[supervisord]'; \
		echo 'nodaemon=true'; \
		echo 'user=root'; \
		echo; \
		echo '[program:xvfb]'; \
		echo 'command=Xvfb :1 -screen 0 "%(ENV_DISPLAY_WIDTH)s"x"%(ENV_DISPLAY_HEIGHT)s"x24'; \
		echo 'autorestart=true'; \
		echo; \
		echo '[program:x11vnc]'; \
		echo 'command=/usr/bin/x11vnc -display :1 -xkb -forever'; \
		echo 'autorestart=true'; \
		echo; \
		echo '[program:openbox]'; \
		echo 'environment=DISPLAY=":1"'; \
		#echo 'command=/usr/bin/openbox-session'; \
		echo 'command=/usr/bin/openbox'; \
		echo 'autorestart=true'; \
		echo; \
		echo '[program:novnc]'; \
		echo 'command=/root/noVNC/utils/launch.sh --vnc localhost:5900 --listen 5800'; \
		echo 'autorestart=true'; \
	} > /etc/supervisord.conf

EXPOSE 5900 5800

ENTRYPOINT [ "/usr/bin/supervisord" ]
