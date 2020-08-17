ARG DOCKER_ID
ARG ARCH
ARG IMAGE_TAG=$DOCKER_ID/alpine-base-$ARCH
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION}

RUN \
	apk add --no-cache -U wget ca-certificates p7zip privoxy su-exec \
	&& mkdir /tmp/adblock2privoxy \
	&& cd /tmp/adblock2privoxy/ \
	&& wget https://s3.amazonaws.com/ab2p/ab2p.easylist_advblock.7z \
	&& 7z e ab2p.easylist_advblock.7z -y -o/tmp/adblock2privoxy/ *.filter *.action -r \
	&& rm ab2p.easylist_advblock.7z \
	&& mv /tmp/adblock2privoxy/* /etc/privoxy/ \
	&& sed -i 's/#max-client-connections/max-client-connections/' /etc/privoxy/config \
	&& sed -i '/^#/d' /etc/privoxy/config \
	&& sed -i 's/127\.0\.0\.1:8118/0\.0\.0\.0:8118/' /etc/privoxy/config \
	&& sed -i 's/enable-edit-actions 0/enable-edit-actions 1/' /etc/privoxy/config \
	&& sed -i 's/accept-intercepted-requests 0/accept-intercepted-requests 1/' /etc/privoxy/config \
	&& sed -i 's/http/https/g' /etc/privoxy/ab2p.system.filter \
	# && echo "debug 13313" >> /etc/privoxy/config \
	&& echo "actionsfile ab2p.system.action" >> /etc/privoxy/config \
	&& echo "actionsfile ab2p.action" >> /etc/privoxy/config \
	&& echo "filterfile ab2p.system.filter" >> /etc/privoxy/config \
  	&& echo "filterfile ab2p.filter" >> /etc/privoxy/config \
  	&& chown privoxy:privoxy /etc/privoxy/* \
  	&& apk del wget p7zip

EXPOSE 8118

ENTRYPOINT [ "/sbin/su-exec" ]
CMD [ "privoxy:privoxy","/usr/sbin/privoxy","--no-daemon","/etc/privoxy/config" ]
