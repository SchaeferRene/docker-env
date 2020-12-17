#! /bin/sh

#####################
### Configuration ###
#####################
export PREFIX=/opt/ffmpeg
export OWN_PKG_CONFIG_PATH="$PREFIX/share/pkgconfig:$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig"
export PKG_CONFIG_PATH="$OWN_PKG_CONFIG_PATH:/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:/lib64/pkgconfig:/lib/pkgconfig"
export LD_LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/lib64:/lib"
export MAKEFLAGS=-j2
export CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
export CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
export PATH="$PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LDFLAGS="-Wl,-z,relro,-z,now,-lz"

FFMPEG_FEATURES=""
FFMPEG_EXTRA_LIBS=""

mkdir -p "$PREFIX"

#export BUILDING_BROTLI=compile
#export BUILDING_FONTCONFIG=disabled
#export BUILDING_FREETYPE=compile
#export BUILDING_GRAPHITE2=compile
#export BUILDING_HARFBUZZ=disabled
#export BUILDING_LIBPNG=compile

echo "--- Configuration:"
env | grep BUILDING_ | sort
echo

# some text color constants
Color_Off='\033[0m'       # Text Reset
On_IPurple='\033[0;105m'  # Purple

########################
### Common functions ###
########################
addFeature() {
	[ $(echo "$FFMPEG_FEATURES" | grep -q -- "$1"; echo $?) -eq 0 ] \
		|| FFMPEG_FEATURES="$FFMPEG_FEATURES $1"
}

addExtraLib() {
	[ $(echo "$FFMPEG_EXTRA_LIBS" | grep -q -- "$1"; echo $?) -eq 0 ] \
		|| FFMPEG_EXTRA_LIBS="$FFMPEG_EXTRA_LIBS $1"
}

installFfmpegToolingDependencies() {
	echo "--- Installing Tooling Dependencies"
	
	# below dependencies are required to build core ffmpeg according to generic compilation guide
	apk add --no-cache --update \
		build-base \
		autoconf \
		automake \
		cmake \
		git \
		wget \
		tar \
		pkgconfig \
		libtool \
		texinfo \
		yasm

	echo

	# TODO: clarify: below dependencies might be for ffplay only
	echo "--- Installing ffmpeg build Dependencies"
	apk add --no-cache \
		libva-dev libvdpau-dev \
		sdl2-dev sdl2-static sdl2_ttf-dev \
		libxcb-dev libxcb-static
	
	echo
}

sanityCheck() {
	echo

	if [[ $RESULT -eq 0 ]]; then
		echo "--- Compilation succeeded"
		for PRG in ffmpeg ffprobe ffplay
		do
			PRG="$PREFIX/bin/$PRG"
			if [[ -f "$PRG" ]]; then
				echo
				echo "${PRG} -version" && ${PRG} -version
				echo -n "${PRG} dependencies:" && echo $(ldd "$PRG" | wc -l)
				echo
			fi
		done
	else
		echo "... ... build failed with exit status"  $RESULT
		[ -f ffbuild/config.log ] && tail -10 ffbuild/config.log
	fi
}

hasBeenInstalled() {
	if [ -z "$2" ]; then
		PCP=$PKG_CONFIG_PATH
	else
		PCP=$OWN_PKG_CONFIG_PATH
	fi
	
	echo "--- Checking $1 in $PCP"

	RESULT=$(PKG_CONFIG_PATH="$PCP" pkg-config --exists --no-cache --env-only --static --print-errors $1; echo $?)
	
	[ $RESULT -eq 0 ] && echo "... found" || echo "... not found"
	echo
}

provide () {
	echo -e $On_IPurple
	BUILD_VAR=BUILDING_$(echo "$1" | tr [:lower:] [:upper:])
	eval val="\$$BUILD_VAR"
	METHOD=$(echo "$val" | grep -E "install|compile|disabled")
	
	if [ "$METHOD" == "disabled" ]; then
		echo "!!! Skipping disabled $1$Color_Off"
		return
	elif [ -n "$METHOD" ]; then
		[ "$METHOD" == "compile" ] && MSG="Compiling" || MSG="Installing"
		fn_exists "$METHOD$1"
		[ $? -ne 0 ] && echo "missing function $METHOD$1" && exit 255 \
			|| echo -e "--- ${MSG} $1$Color_Off" && eval "$METHOD$1"
	else
		fn_exists "install$1"
		if [ $? -eq 0 ]; then
			echo -e "--- Installing $1$Color_Off"
			eval "install$1"
		else
			fn_exists "compile$1"
			[ $? -ne 0 ] && echo "missing functions install$1 or compile$1" && exit 255 \
				|| echo -e "--- Compiling $1$Color_Off" && eval "compile$1"
		fi
	fi
	
	RESULT=$?
	
	echo -e "${On_IPurple}... done providing $1$Color_Off"
}

fn_exists () {
	type $1 >/dev/null 2>&1;
}

#############
### Hacks ###
#############
dirtyHackForBrotli() {
	echo
	echo "--- Applying hack for brotli"

	if [[ ! -e /usr/lib/libbrotlicommon.a -a -e /usr/lib/libbrotlicommon-static.a ]]; then
		ln -s /usr/lib/libbrotlicommon-static.a /usr/lib/libbrotlicommon.a
	fi
	if [[ ! -e /usr/lib/libbrotlidec.a -a -e /usr/lib/libbrotlidec-static.a ]]; then
		ln -s /usr/lib/libbrotlidec-static.a /usr/lib/libbrotlidec.a
	fi
}

####################
### Dependencies ###
####################
compileGlib2 () {
	hasBeenInstalled glib-2.0
	
	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built Glib2" \
	|| {
		apk add --no-cache \
			nasm \
			meson \
			ninja \
			libxslt \
			libxslt-dev \
			pcre \
			pcre-dev \
			musl-libintl
		
		DIR=/tmp/glib2
		mkdir -p "$DIR"
		cd "$DIR"

		git clone --depth 1 https://gitlab.gnome.org/GNOME/glib.git
		cd glib

		mkdir -p build
		cd build
		
		meson \
			--prefix "$PREFIX" \
			--buildtype release \
			--optimization 3 \
			--pkg-config-path "$PKG_CONFIG_PATH" \
			--build.pkg-config-path "$PKG_CONFIG_PATH" \
			--cmake-prefix-path "$PREFIX" \
			--build.cmake-prefix-path "$PREFIX" \
			-DBUILD_SHARED_LIBS=OFF \
			-Dman=false \
			-Dgtk_doc=false \
			..

		ninja && ninja install
	}
}

compileGraphite2() {
	hasBeenInstalled graphite2

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built Graphite2" \
	|| {
		DIR=/tmp/graphite2
		mkdir -p "$DIR"
		cd "$DIR"
		
		# see https://gist.github.com/rkitover/418600634d7cf19e2bf1c3708b50c042
		wget https://github.com/silnrsi/graphite/releases/download/1.3.10/graphite2-1.3.10.tgz
		 tar -xzf graphite2-1.3.10.tgz
		cd graphite2-1.3.10/
		
		patch -p1 --ignore-whitespace << 'EOF'
diff -ruN graphite2-1.3.10/CMakeLists.txt graphite2-1.3.10.new/CMakeLists.txt
--- graphite2-1.3.10/CMakeLists.txt	2017-05-05 08:35:18.000000000 -0700
+++ graphite2-1.3.10.new/CMakeLists.txt	2017-11-28 06:20:03.278842876 -0800
@@ -58,10 +58,10 @@
 message(STATUS "Using vm machine type: ${GRAPHITE2_VM_TYPE}")
 
 add_subdirectory(src)
-add_subdirectory(tests)
-add_subdirectory(doc)
+#add_subdirectory(tests)
+#add_subdirectory(doc)
 if (NOT (GRAPHITE2_NSEGCACHE OR GRAPHITE2_NFILEFACE))
-    add_subdirectory(gr2fonttest)
+#    add_subdirectory(gr2fonttest)
 endif (NOT (GRAPHITE2_NSEGCACHE OR GRAPHITE2_NFILEFACE))
 
 set(version 3.0.1)
diff -ruN graphite2-1.3.10/src/CMakeLists.txt graphite2-1.3.10.new/src/CMakeLists.txt
--- graphite2-1.3.10/src/CMakeLists.txt	2017-05-05 08:35:18.000000000 -0700
+++ graphite2-1.3.10.new/src/CMakeLists.txt	2017-11-28 06:21:34.313304857 -0800
@@ -65,7 +65,7 @@
 
 file(GLOB PRIVATE_HEADERS inc/*.h) 
 
-add_library(graphite2 SHARED
+add_library(graphite2 STATIC
     ${GRAPHITE2_VM_TYPE}_machine.cpp
     gr_char_info.cpp
     gr_features.cpp
@@ -130,10 +130,10 @@
             target_link_libraries(graphite2 c gcc)
         endif (GRAPHITE2_ASAN)
         include(Graphite)
-        nolib_test(stdc++ $<TARGET_SONAME_FILE:graphite2>)
+        #nolib_test(stdc++ $<TARGET_SONAME_FILE:graphite2>)
     endif (${CMAKE_CXX_COMPILER} MATCHES  ".*mingw.*")
     set(CMAKE_CXX_IMPLICIT_LINK_LIBRARIES "")
-    CREATE_LIBTOOL_FILE(graphite2 "/lib${LIB_SUFFIX}")
+    #CREATE_LIBTOOL_FILE(graphite2 "/lib${LIB_SUFFIX}")
 endif (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
 
 if  (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
@@ -143,9 +143,9 @@
         LINKER_LANGUAGE C)
     target_link_libraries(graphite2 c)
     include(Graphite)
-    nolib_test(stdc++ $<TARGET_SONAME_FILE:graphite2>)
+    #nolib_test(stdc++ $<TARGET_SONAME_FILE:graphite2>)
     set(CMAKE_CXX_IMPLICIT_LINK_LIBRARIES "")
-    CREATE_LIBTOOL_FILE(graphite2 "/lib${LIB_SUFFIX}")
+    #CREATE_LIBTOOL_FILE(graphite2 "/lib${LIB_SUFFIX}")
 endif (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
 
 if  (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
EOF
		
		mkdir -p build
		cd build
		
		cmake \
			-DCMAKE_INSTALL_PREFIX="$PREFIX" \
			-DBUILD_SHARED_LIBS=OFF \
			..
		
		make && make install
	}
}

installPixman() {
	apk add --no-cache \
		pixman-dev \
		pixman-static
}

compileCairo() {
	hasBeenInstalled cairo

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built Cairo" \
	|| {
		provide Pixman
		provide Glib2
		provide FontConfig	# compiles freetype+harfbuzz+graphite2 installs xml2 installs zlib
		provide LibPng

		apk add --no-cache \
			libx11-dev \
			libx11-static \
			libxcb-dev \
			libxcb-static

		# TODO: add QT5 support?
		# TODO: add OpenGL support?
		# TODO: add directFB support?

		DIR=/tmp/cairo
		mkdir -p "$DIR"
		cd "$DIR"
		
		git clone --depth 1 https://github.com/freedesktop/cairo.git
		cd cairo
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes
		
		make && make install
	}
}

compileHarfbuzz () {
	# temporarily disable harfbuzz for freetype not to retrigger function
	BUILDING_HARFBUZZ_BAK=$BUILDING_HARFBUZZ
	BUILDING_HARFBUZZ=disabled
	
	hasBeenInstalled harfbuzz
	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built Harfbuzz" \
	|| {
		provide Freetype
		provide Glib2
		provide Graphite2
		provide Cairo

		apk add --no-cache \
			meson \
			ragel \
			icu-dev \
			icu-static

		DIR=/tmp/harfbuzz
		mkdir -p "$DIR"
		cd "$DIR"

		git clone --depth 1 https://github.com/harfbuzz/harfbuzz.git
		cd harfbuzz

		# TODO: migrate to meson
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes \
			--with-graphite2

		make && make install
		
		# force recompilation of Graphite2
		[ -d /tmp/graphite2 ] && rm -rf /tmp/graphite2
		[ -f "$PREFIX/lib/pkgconfig/graphite2.pc" ] && rm -f "$PREFIX/lib/pkgconfig/graphite2.pc"
		provide Graphite2
		
		# force recompilation of freetype
		[ -d /tmp/freetype ] && rm -rf "/tmp/freetype"
		[ -f "$PREFIX/lib/pkgconfig/freetype2.pc" ] && rm "$PREFIX/lib/pkgconfig/freetype2.pc"
		provide Freetype
	}
	
	BUILDING_HARFBUZZ=$BUILDING_HARFBUZZ_BAK
}

installLibBzip2 () {
	apk add --no-cache \
		libbz2 \
		bzip2-dev \
		bzip2-static
}

installBrotli() {
	apk add --no-cache \
		brotli-dev \
		brotli-static

	dirtyHackForBrotli
}

compileBrotli() {
	hasBeenInstalled libbrotlidec

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built Brotli" \
	|| {
		DIR=/tmp/brotli
		mkdir -p "$DIR"
		cd "$DIR"

		git clone https://github.com/google/brotli.git
		cd brotli/

		./bootstrap
		./configure \
			--prefix="$PREFIX" \
			--disable-dependency-tracking \
			--enable-shared=no \
			--enable-static=yes
		
		make && make install
	}
}
pr
################
### Features ###
################

## Supplementary ##
installXml2() {
	apk add --no-cache \
		zlib-dev \
		zlib-static \
		libxml2-dev
	
	addFeature --enable-libxml2
}

installFreetype() {
	apk add --no-cache \
		freetype \
		freetype-dev \
		freetype-static
	
	addFeature --enable-libfreetype
}

compileFreetype() {
	hasBeenInstalled freetype2
	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built freetype2" \
	|| {
		provide Xml2
		provide LibPng
		provide Brotli
		provide LibBzip2
		
		hasBeenInstalled harfbuzz true
		HAS_HARFBUZZ=$RESULT
	
		[ $HAS_HARFBUZZ -eq 0 ] \
			&& FREETYPE_FLAGS="--with-harfbuzz=yes" \
			|| FREETYPE_FLAGS=""
		
		hasBeenInstalled libbz2 true
		HAS_LIBBZ2=$RESULT
		
		[ $HAS_LIBBZ2 -eq 0 ] \
			&& FREETYPE_FLAGS="$FREETYPE_FLAGS --with-bzip2=yes" 
			
		apk add --no-cache \
			zlib-dev \
			zlib-static

		DIR=/tmp/freetype2
		mkdir -p "$DIR"
		cd "$DIR"

		[ -d freetype2 ] && rm -rf freetype2
		git clone --depth 1 https://git.savannah.nongnu.org/git/freetype/freetype2.git
		cd freetype2/
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes \
			--enable-freetype-config \
			--with-zlib=yes \
			--with-png=yes \
			--with-brotli=yes \
			$FREETYPE_FLAGS

		make && make install
	}

	addFeature --enable-libfreetype

	provide Harfbuzz
}

compileFontConfig() {
	hasBeenInstalled fontconfig

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built fontconfig" \
	|| {
		provide Freetype
		provide LibPng

		apk add --no-cache \
			expat-dev \
			expat-static \
			gperf

		DIR=/tmp/fontconfig
		mkdir -p "$DIR"
		cd "$DIR"

		wget https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.92.tar.gz \
			-O fontconfig.tar.gz
		tar -xf fontconfig.tar.gz
		cd fontconfig-2.13.92
		

		PKG_CONFIG_PATH="$PKG_CONFIG_PATH" ./configure \
			--prefix="$PREFIX" \
			--enable-static=yes \
			--enable-shared=no \
			--disable-docs \
			--disable-dependency-tracking

		make && make install
	}

	addFeature --enable-fontconfig
}

## Imaging ##
installLibPng() {
	apk add --no-cache \
		libpng-dev \
		libpng-static
}

compileLibPng() {
	hasBeenInstalled fontconfig

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built libPng" \
	|| {
		DIR=/tmp/libPng
		mkdir -p "$DIR"
		cd "$DIR"

		git clone --depth 1 https://github.com/glennrp/libpng.git
		cd libpng/

		./configure \
			--prefix="$PREFIX" \
			--disable-dependency-tracking \
			--enable-shared=no \
			--enable-static=yes \
			--enable-unversioned-links \
			--enable-unversioned-libpng-pc \
			--enable-unversioned-libpng-config
		
		make && make install
	}
}

## Audio ##
installOpus() {
	apk add --no-cache libopusenc-dev
	addFeature --enable-libopus
}

compileOpus() {
	hasBeenInstalled opus
	
	[ $RESULT -eq 0 ] \
	&& echo "-- Skipping already built opus" \
	|| {
		DIR=/tmp/opus
		mkdir -p "$DIR"
		cd "$DIR"
		
		git clone --depth 1 https://github.com/xiph/opus.git
		cd opus
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes \
			--disable-doc \
			--disable-extra-programs

		make && make install
	}

	addFeature --enable-libopus
}

installSoxr() {
	apk add --no-cache \
		soxr-dev \
		soxr-static

	addFeature --enable-libsoxr
}

compileSpeex() {
	hasBeenInstalled speex

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built speex" \
	|| {
		DIR=/tmp/speex
		mkdir -p "$DIR"
		cd "$DIR"

		git clone --depth 1 https://github.com/xiph/speex.git
		cd speex
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes

		make && make install
	}

	addFeature --enable-libspeex
}

installTheora() {
	apk add --no-cache libtheora-dev libtheora-static
	addFeature --enable-libtheora
}

compileTheora() {
	hasBeenInstalled theora
	
	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built theora" \
	|| {
		provide Ogg
		echo "--- Installing Theora"
		
		DIR=/tmp/theora
		mkdir -p "$DIR"
		cd "$DIR"
		
		git clone --depth 1 https://github.com/xiph/theora.git
		cd theora
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes \
			--disable-doc \
			--disable-examples \
			--with-ogg="$PREFIX/lib" \
			--with-ogg-libraries="$PREFIX/lib" \
			--with-ogg-includes="$PREFIX/include/" \
			--with-vorbis="$PREFIX/lib" \
			--with-vorbis-libraries="$PREFIX/lib" \
			--with-vorbis-includes="$PREFIX/include/"

		make && make install
	}

	addFeature --enable-libtheora
}

installOgg() {
	apk add --no-cache libogg-dev
}

compileOgg() {
	hasBeenInstalled ogg
	
	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built ogg" \
	|| {
		DIR=/tmp/ogg
		mkdir -p "$DIR"
		cd "$DIR"
		
		git clone --depth 1 https://github.com/xiph/ogg.git
		cd ogg
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes
			
		make && make install
	}
}

installVorbis() {
	apk add --no-cache libvorbis-dev
	addFeature --enable-libvorbis
}

compileVorbis() {
	hasBeenInstalled vorbis
	
	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built vorbis" \
	|| {
		provide Ogg
		
		DIR=/tmp/vorbis
		mkdir -p "$DIR"
		cd "$DIR"
		
		git clone --depth 1 https://github.com/xiph/vorbis.git
		cd vorbis

		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes

		make && make install
	}

	addFeature --enable-libvorbis
}

## Video ##
compileAom() {
	hasBeenInstalled aom

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built aom" \
	|| {
		DIR=/tmp/aom
		mkdir -p "$DIR"
		cd "$DIR"

		git clone --depth 1 https://aomedia.googlesource.com/aom
		mkdir -p aom/compile
		cd aom/compile

		cmake \
			-DCMAKE_INSTALL_PREFIX="$PREFIX" \
			-DBUILD_SHARED_LIBS=OFF \
			-DENABLE_TESTS=0 \
			-DENABLE_EXAMPLES=OFF \
			-DENABLE_DOCS=OFF \
			-DENABLE_TOOLS=OFF \
			-DAOM_TARGET_CPU=generic \
			..

		make && make install
	}

	addFeature --enable-libaom
}

compileDav1d() {
	hasBeenInstalled dav1d

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built dav1d" \
	|| {
	echo "--- Installing dav1d"

		apk add --no-cache \
			meson \
			ninja \
			nasm

		DIR=/tmp/dav1d
		mkdir -p "$DIR"
		cd "$DIR"

		git clone --depth 1 https://code.videolan.org/videolan/dav1d.git
		cd dav1d

		meson build \
			--prefix "$PREFIX" \
			--buildtype release \
			-Ddefault_library=static

		ninja -C build
		ninja -C build install
	}

	addFeature --enable-libdav1d
}

compileDavs2() {
	[ -n "$BUILDING_DAVS2" ] && return
	hasBeenInstalled davs2

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built davs2" \
	|| {
		apk add --no-cache \
			nasm

		DIR=/tmp/davs2
		mkdir -p "$DIR"
		cd "$DIR"

		wget https://github.com/pkuvcl/davs2/archive/master.zip -O davs2.zip
		unzip davs2.zip
		cd davs2-master/build/linux/

		./configure \
			--prefix="$PREFIX" \
			--enable-pic \
			--disable-cli

		make && make install
	}

	addFeature --enable-libdavs2
}

compileKvazaar() {
	hasBeenInstalled kvazaar

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built Kvazaar" \
	|| {
		DIR=/tmp/kvazaar
		mkdir -p "$DIR"
		cd "$DIR"

		git clone --depth 1 https://github.com/ultravideo/kvazaar.git
		cd kvazaar
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes

		make && make install
	}

	addFeature --enable-libkvazaar
}

# compile VP8/VP9
compileVpx() {
	hasBeenInstalled vpx

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built libVpx" \
	|| {
		DIR=/tmp/vpx
		mkdir -p "$DIR"
		cd "$DIR"

		apk add --no-cache diffutils

		git clone --depth 1 https://github.com/webmproject/libvpx.git
		cd libvpx

		./configure \
			--prefix="$PREFIX" \
			--enable-static \
			--disable-shared \
			--disable-examples \
			--disable-tools \
			--disable-install-bins \
			--disable-docs \
			--target=generic-gnu \
			--enable-vp8 \
			--enable-vp9 \
			--enable-vp9-highbitdepth \
			--enable-pic \
			--disable-examples \
			--disable-docs \
			--disable-debug

		make && make install
	}

	addFeature --enable-libvpx
}

compileX264() {
	hasBeenInstalled x264

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built x264" \
	|| {
		apk add --no-cache nasm
		
		DIR=/tmp/x264
		mkdir -p "$DIR"
		cd "$DIR"
	
		git clone --depth 1 https://code.videolan.org/videolan/x264.git
		cd x264/

		./configure \
			--prefix="$PREFIX" \
			--enable-static \
			--enable-pic

		make && make install
	}

	addFeature --enable-libx264
}

compileX265() {			# TODO: compile as multi-lib
	hasBeenInstalled x265

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built x265" \
	|| {
		DIR=/tmp/x265
		mkdir -p "$DIR"
		cd "$DIR"

		git clone https://github.com/videolan/x265.git
		cd x265/build/linux/

		cmake -G "Unix Makefiles" \
			-DCMAKE_INSTALL_PREFIX="$PREFIX" \
			-DENABLE_SHARED:bool=OFF \
			-DENABLE_AGGRESSIVE_CHECKS=ON \
			-DENABLE_PIC=ON \
			-DENABLE_CLI=ON \
			-DENABLE_HDR10_PLUS=ON \
			-DENABLE_LIBNUMA=OFF \
			../../source

		make && make install
	}

	addFeature --enable-libx265
}

compileXavs2() {
	[ -n "$BUILDING_XAVS2" ] && return
	hasBeenInstalled xavs2

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built xavs2" \
	|| {
		apk add --no-cache \
			nasm

		DIR=/tmp/xavs2
		mkdir -p "$DIR"
		cd "$DIR"

		wget https://github.com/pkuvcl/xavs2/archive/master.zip -O xavs2.zip
		unzip xavs2.zip
		cd xavs2-master/build/linux/

		./configure \
			--prefix "$PREFIX" \
			--enable-pic \
			--enable-static \
			--disable-cli

		make && make install
	}

	addFeature --enable-libxavs2
}

installXvid() {
	apk add --no-cache \
		xvidcore-dev \
		xvidcore-static
	
	addFeature --enable-libxvid
}

compileXvid() {
	hasBeenInstalled xvid

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built xvid" \
	|| {
		DIR=/tmp/xvid
		mkdir -p "$DIR"
		cd "$DIR"

		wget https://downloads.xvid.com/downloads/xvidcore-1.3.7.tar.gz -O xvid.tar.gz
		tar xf xvid.tar.gz
		cd xvidcore/build/generic/
		
		CFLAGS="$CLFAGS -fstrength-reduce -ffast-math" ./configure \
			--prefix="$PREFIX"

		make && make install
	}

	addFeature --enable-libxvid
}

##############
### FFMPEG ###
##############
compileFfmpeg() {
	# add some default features
	addFeature --enable-libxcb
	addFeature --enable-libxcb-shm
	addFeature --enable-libxcb-xfixes
	addFeature --enable-libxcb-shape
	
	FFMPEG_OPTIONS="--disable-shared --enable-static --enable-pic"
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS --disable-debug --disable-doc"
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS --enable-gpl --enable-nonfree --enable-version3"
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS $FFMPEG_FEATURES"

	echo "--- Compiling ffmpeg with features $FFMPEG_OPTIONS"

	apk add zlib-dev zlib-static

	DIR=/tmp/ffmpeg
	if [ -d "$DIR" ]; then
	    rm -rf "$DIR"
	fi
	mkdir -p "$DIR"
	cd "$DIR"

	wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
	tar xjf ffmpeg-snapshot.tar.bz2
	cd ffmpeg/

	./configure \
		--env=PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
		--prefix="$PREFIX" \
		--extra-cflags="-I${PREFIX}/include -fopenmp" \
		--extra-ldflags="-L${PREFIX}/lib -static -fopenmp" \
		--extra-ldexeflags="-static" \
		--pkg-config=pkg-config \
		--pkg-config-flags=--static \
		--toolchain=hardened \
		--extra-libs="-lz $FFMPEG_EXTRA_LIBS" \
		$FFMPEG_OPTIONS
		#--extra-libs="-lpthread -lm -lz" \

	make && make install
}

#############################################
### Comment out what you don't need below ###
#############################################
#just for individual testing
# note: c=compile, i=install
testPrerequisites() {
	#provide LibPng
	#provide Glib2
	#provide Graphite2
	#provide Cairo
	#provide Harfbuzz
	:					# NOOP
}

compileSupportingLibs() {
	#provide Xml2
	#provide Freetype
	#provide FontConfig
	##provide Fribidi
	##provide Ass
	##provide OpenSsl
	##compileVidStab
	##compileZimg
	:					# NOOP
}

compileImageLibs() {
	##compileOpenJpeg
	##compileWebp
	:					# NOOP
}

compileAudioCodecs() {
	##compileFdkAac
	##compileMp3Lame
	provide Opus		# x86: ic
	#provide Soxr		# x86: i
	#provide Speex		# x86: c
	#provide Theora		# x86: ic
	#provide Vorbis		# x86: ic
	:					# NOOP
}

compileVideoCodecs() {
	#provide Aom		# x86: c
	#provide Dav1d		# x86: c
	#provide Davs2		# x86: c
	#provide Kvazaar	# x86: c
	#provide Vpx		# x86: c
	#provide X264		# x86: c
	#provide X265		# x86: c
	#provide Xavs2		# x86: c
	#provide Xvid		# x86: ic
	:					# NOOP
}

### Leave the rest as is ####################
installFfmpegToolingDependencies
testPrerequisites
compileSupportingLibs
compileImageLibs
compileAudioCodecs
compileVideoCodecs

# almost there
provide Ffmpeg

# fingers crossed
sanityCheck
