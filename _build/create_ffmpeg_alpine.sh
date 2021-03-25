#! /bin/bash


echo "... ... ... building ffmpeg_alpine"

# build raw image
EXISTING_DOCKER_IMAGE=$(docker images -q "$DOCKER_ID/${FFMPEG_ALPINE_RAW_IMAGE}:${ALPINE_VERSION}" 2> /dev/null)

if [[ -n "$EXISTING_DOCKER_IMAGE" ]] && [[ $IS_FORCE_BUILD -ne 0 ]]; then
	echo "... ... ... ... skipping already built $DOCKER_ID/${FFMPEG_ALPINE_RAW_IMAGE}:${ALPINE_VERSION}"
else
	echo "... ... ... ... building raw image"
	docker build \
		--network host \
		--build-arg ARCH=$ARCH \
		--build-arg DOCKER_ID=$DOCKER_ID \
		\
		--build-arg  BUILDING_XML2=$BUILDING_XML2 \
		--build-arg  BUILDING_FREETYPE=$BUILDING_FREETYPE \
		--build-arg  BUILDING_FONTCONFIG=$BUILDING_FONTCONFIG \
		--build-arg  BUILDING_FRIBIDI=$BUILDING_FRIBIDI \
		\
		--build-arg  BUILDING_ARIBB24=$BUILDING_ARIBB24 \
		--build-arg  BUILDING_LIBASS=$BUILDING_LIBASS \
		--build-arg  BUILDING_LIBBLURAY=$BUILDING_LIBBLURAY \
		--build-arg  BUILDING_LIBXCB=$BUILDING_XCB \
		--build-arg  BUILDING_OPENSSL=$BUILDING_OPENSSL \
		--build-arg  BUILDING_SRT=$BUILDING_SRT \
		--build-arg  BUILDING_VIDSTAB=$BUILDING_VIDSTAB \
		--build-arg  BUILDING_ZEROMQ=$BUILDING_ZEROMQ \
		--build-arg  BUILDING_ZIMG=$BUILDING_ZIMG \
		\
		--build-arg  BUILDING_OPENJPEG=$BUILDING_OPENJPEG \
		--build-arg  BUILDING_WEBP=$BUILDING_WEBP \
		\
		--build-arg  BUILDING_FDKAAC=$BUILDING_FDKAAC \
		--build-arg  BUILDING_MP3LAME=$BUILDING_MP3LAME \
		--build-arg  BUILDING_OPENCOREAMR=$BUILDING_OPENCOREAMR \
		--build-arg  BUILDING_OPUS=$BUILDING_OPUS \
		--build-arg  BUILDING_SOXR=$BUILDING_SOXR \
		--build-arg  BUILDING_SPEEX=$BUILDING_SPEEX \
		--build-arg  BUILDING_THEORA=$BUILDING_THEORA \
		--build-arg  BUILDING_VORBIS=$BUILDING_VORBIS \
		\
		--build-arg  BUILDING_AOM=$BUILDING_AOM \
		--build-arg  BUILDING_DAV1D=$BUILDING_DAV1D \
		--build-arg  BUILDING_DAVS2=$BUILDING_DAVS2 \
		--build-arg  BUILDING_KVAZAAR=$BUILDING_KVAZAAR \
		--build-arg  BUILDING_VPX=$BUILDING_VPX \
		--build-arg  BUILDING_X264=$BUILDING_X264 \
		--build-arg  BUILDING_X265=$BUILDING_X265 \
		--build-arg  BUILDING_XAVS2=$BUILDING_XAVS2 \
		--build-arg  BUILDING_XVID=$BUILDING_XVID \
		\
		-t $DOCKER_ID/${FFMPEG_ALPINE_RAW_IMAGE}:${ALPINE_VERSION} \
		-t $DOCKER_ID/${FFMPEG_ALPINE_RAW_IMAGE}:latest \
		ffmpeg_raw
	echo
fi

