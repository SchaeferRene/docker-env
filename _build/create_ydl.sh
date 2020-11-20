#! /bin/bash

echo "... ... ... building youtube-dl"

docker build \
	--build-arg ARCH=$ARCH \
	--build-arg DOCKER_ID=$DOCKER_ID \
	-t $DOCKER_ID/$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${!IMG}"") - < "$FEATURE/Dockerfile"

echo -e "\n\e[36musage:\e[0m"
echo -e "    \e[36mcreate an alias e.g. in ~/.bashrc or /etc/profile.d/aliases.sh:\e[0m"
echo -e "      \e[96malias youtube-dl='P=\$(pwd) docker run --rm -u \$UID:\$(id -g) -v \"\$P\":/downloads $DOCKER_ID/youtube-dl-alpine-$ARCH'\e[0m"
echo -e "    \e[36mdownload video:\e[0m"
echo -e "      \e[96myoutube-dl <URL>\e[0m"
echo -e "    \e[36mlist available formats:\e[0m"
echo -e "      \e[96myoutube-dl -F <URL>\e[0m"
echo -e "    \e[36mdownload video with particular format:\e[0m"
echo -e "      \e[96myoutube-dl -f <FORMAT CODE> <URL>\e[0m"
echo
