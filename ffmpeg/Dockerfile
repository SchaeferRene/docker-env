ARG DOCKER_ID=reneschaefer
ARG ARCH=armv7
ARG IMAGE_TAG=$DOCKER_ID/alpine-base-$ARCH
ARG IMAGE_VERSION=latest

FROM ${IMAGE_TAG}:${IMAGE_VERSION} AS builder

RUN	set -xe \
	&& apk add --no-cache --update \
		build-base \
		coreutils \
		diffutils \
		autoconf \
		automake \
		cmake \
		git \
		wget \
		libbz2 \
		bzip2-dev \
		bzip2-static \
		tar \
		nasm \
		yasm \
		openssl \
		openssl-dev \
		openssl-libs-static \
		libtool \
		expat-dev \
		expat-static \
		zlib-dev \
		zlib-static \
		freetype-dev \
		freetype-static \
		fontconfig-dev \
		fontconfig-static \
		libpng-static \
		harfbuzz-dev \
		harfbuzz-static \
		brotli-dev \
		brotli-static \
		meson \
		ninja \
		xz \
		texinfo \
		libxml2-dev \
		graphite2-static \
		glib-static \
		fribidi-dev \
		fribidi-static \
		soxr-dev \
		soxr-static \
	&& export PREFIX=/opt/ffmpeg \
	&& export PKG_CONFIG_PATH="$PREFIX/share/pkgconfig:$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig:/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:/lib64/pkgconfig:/lib/pkgconfig" \
	&& export LD_LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib:/usr/lib64:/usr/lib:/lib64:/lib" \
	&& export MAKEFLAGS="-j2" \
	&& export CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE" \
	&& export CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE" \
	&& export PATH="$PREFIX/bin:$PATH" \
	&& mkdir "$PREFIX" \
# compile freetype2
	&& DIR="/tmp/freetype2" && mkdir -p "$DIR" && cd "$DIR" \
	&& git clone https://git.savannah.nongnu.org/git/freetype/freetype2.git \
	&& cd freetype2/ \
	&& ./autogen.sh \
	&& ./configure \
		--prefix="$PREFIX" \
		--enable-shared=no \
		--enable-static=yes \
		--enable-freetype-config \
		--with-zlib=yes \
		--with-bzip2=yes \
		--with-png=yes \
		--with-harfbuzz=yes \
		--with-brotli=yes \
	&& make \
	&& make install \
# compile ffmpeg
	&& DIR="/tmp/ffmpeg" && mkdir -p "$DIR" && cd "$DIR" \
	&& wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 \
	&& tar xjf ffmpeg-snapshot.tar.bz2 \
	&& cd ffmpeg/ \
	&& ./configure \
		--pkg-config-flags=--static \
		--prefix="$PREFIX" \
		--extra-cflags="-I${PREFIX}/include -fopenmp" \
		--extra-ldflags="-static -fopenmp" \
		--toolchain=hardened \
		--disable-debug \
		--disable-shared \
		--enable-static \
		--enable-gpl \
		--enable-nonfree \
		--enable-version3 \
		--disable-doc \
		--enable-openssl \
		--enable-fontconfig --enable-libfreetype \
	&& make install \
# make sure binaries have no additional dependencies
	&& test $(ldd /opt/ffmpeg/bin/ffmpeg | wc -l) -eq 1 \
	&& test $(ldd /opt/ffmpeg/bin/ffprobe | wc -l) -eq 1

# copy build artifacts
FROM ${IMAGE_TAG}:${IMAGE_VERSION}
COPY --from=builder /opt/ffmpeg/bin/ffmpeg /opt/ffmpeg/bin/ffprobe /usr/local/bin/
COPY --from=builder /etc/ssl/cert.pem /etc/ssl/cert.pem

# sanity checks 
RUN set -xe \
	&& ffmpeg -version \
	&& ffprobe -version 

ENTRYPOINT [ "ffmpeg" ]
CMD [ "-version" ]

