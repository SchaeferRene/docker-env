installAss() {
        apk add --no-cache libass-dev \
        && addFeature --enable-libass
}

compileAss() {
        hasBeenInstalled libass true

        [ $CHECK -eq 0 ] \
        && echo "--- Skipping already built libAss" \
        || {
                provide Glib2
                provide FontConfig # font config also builds Freetype builds Harfbuzz builds Graphite
                provide Fribidi

                apk add --no-cache nasm

                # force install of Harfbuzz lib if disabled for FontConfig
                [ "$BUILDING_HARFBUZZ" == "disabled" ] \
                && apk add --no-cache harfbuzz-dev

                DIR=/tmp/ass
                mkdir -p "$DIR"
                cd "$DIR"

                git clone --depth 1 https://github.com/libass/libass.git
                cd libass

                ./autogen.sh \
                && ./configure \
                        --prefix="$PREFIX" \
                        --enable-static=no \
                        --enable-shared=yes

                RESULT=$?
                [ $RESULT -eq 0 ] \
                && make \
                && make install \
                && cd \
                && rm -rf "$DIR"
                RESULT=$?
        }

        addFeature --enable-libass
}

installGlib2 () {
        apk add --no-cache glib-dev
}

compleGlib2 () {
        hasBeenInstalled glib-2.0 true

        [ $CHECK -eq 0 ] \
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
                        -DBUILD_SHARED_LIBS=ON \
                        -Dman=false \
                        -Dgtk_doc=false \
                        .. \
                && ninja \
                && ninja install \
                && cd \
                && rm -rf "$DIR"
                RESULT=$?
        }
}

installGraphite2() {
        apk add --no-cache graphite2-dev
}

compileGraphite2() {
        hasBeenInstalled graphite2 true

        [ $CHECK -eq 0 ] \
        && echo "--- Skipping already built Graphite2" \
        || {
                DIR=/tmp/graphite2
                mkdir -p "$DIR"
                cd "$DIR"

                # see https://gist.github.com/rkitover/418600634d7cf19e2bf1c3708b50c042
                wget https://github.com/silnrsi/graphite/releases/download/${GRAPHITE2_VERSION}/graphite2-${GRAPHITE2_VERSION}.tgz
                tar -xzf graphite2-${GRAPHITE2_VERSION}.tgz
                cd graphite2-${GRAPHITE2_VERSION}/

                patch -p1 --ignore-whitespace << 'EOF'
diff -ruN graphite2-1.3.10/CMakeLists.txt graphite2-1.3.10.new/CMakeLists.txt
--- graphite2-1.3.10/CMakeLists.txt     2017-05-05 08:35:18.000000000 -0700
+++ graphite2-1.3.10.new/CMakeLists.txt 2017-11-28 06:20:03.278842876 -0800
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
--- graphite2-1.3.10/src/CMakeLists.txt 2017-05-05 08:35:18.000000000 -0700
+++ graphite2-1.3.10.new/src/CMakeLists.txt     2017-11-28 06:21:34.313304857 -0800
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
                        -DBUILD_SHARED_LIBS=ON \
                        .. \
                && make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }
}

installPixman() {
        apk add --no-cache pixman-dev
}

compileCairo() {
        hasBeenInstalled cairo true

        [ $CHECK -eq 0 ] \
        && echo "--- Skipping already built Cairo" \
        || {
                provide Pixman
                provide Glib2
                provide FontConfig      # compiles freetype+harfbuzz+graphite2 installs xml2 installs zlib
                provide LibPng

                apk add --no-cache \
                        libx11-dev \
                        libxcb-dev

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
                        --enable-shared=yes \
                        --enable-static=no

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }
}

compileHarfbuzz () {
        # temporarily disable harfbuzz for freetype not to retrigger function
        BUILDING_HARFBUZZ_BAK=$BUILDING_HARFBUZZ
        BUILDING_HARFBUZZ=disabled

        hasBeenInstalled harfbuzz true

        [ $CHECK -eq 0 ] \
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
                        --enable-shared=yes \
                        --enable-static=no \
                        --with-graphite2

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"

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

installBrotli() {
        apk add --no-cache brotli-dev
}

compileBrotli() {
        hasBeenInstalled libbrotlidec true

        [ $CHECK -eq 0 ] \
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
                        --enable-shared=yes \
                        --enable-static=no

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }
}

installLibBzip2 () {
        apk add --no-cache bzip2-dev
}

compileFreetype() {
        hasBeenInstalled freetype2 true

        [ $CHECK -eq 0 ] \
        && echo "--- Skipping already built freetype2" \
        || {
                provide Xml2
                provide LibPng
                provide Brotli
                provide LibBzip2

                hasBeenInstalled harfbuzz
                HAS_HARFBUZZ=$CHECK

                [ $HAS_HARFBUZZ -eq 0 ] \
                        && FREETYPE_FLAGS="--with-harfbuzz=yes" \
                        || FREETYPE_FLAGS=""

                hasBeenInstalled libbz2
                HAS_LIBBZ2=$CHECK

                [ $HAS_LIBBZ2 -eq 0 ] \
                        && FREETYPE_FLAGS="$FREETYPE_FLAGS --with-bzip2=yes"

                apk add --no-cache zlib-dev

                DIR=/tmp/freetype2
                mkdir -p "$DIR"
                cd "$DIR"

                [ -d freetype2 ] && rm -rf freetype2
                git clone --depth 1 https://git.savannah.nongnu.org/git/freetype/freetype2.git
                cd freetype2/

                ./autogen.sh
                ./configure \
                        --prefix="$PREFIX" \
                        --enable-shared=yes \
                        --enable-static=no \
                        --enable-freetype-config \
                        --with-zlib=yes \
                        --with-png=yes \
                        --with-brotli=yes \
                        $FREETYPE_FLAGS

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libfreetype

        provide Harfbuzz
}

compileFontConfig() {
        hasBeenInstalled fontconfig true

        [ $CHECK -eq 0 ] \
        && echo "--- Skipping already built fontconfig" \
        || {
                provide Freetype        # provides LibPng

                apk add --no-cache \
                        expat-dev \
                        gperf

                DIR=/tmp/fontconfig
                mkdir -p "$DIR"
                cd "$DIR"

                wget https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.gz \
                        -O fontconfig.tar.gz
                tar -xf fontconfig.tar.gz
                cd fontconfig-${FONTCONFIG_VERSION}


                PKG_CONFIG_PATH="$PKG_CONFIG_PATH" ./configure \
                        --prefix="$PREFIX" \
                        --enable-static=no \
                        --enable-shared=yes \
                        --disable-docs \
                        --disable-dependency-tracking

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-fontconfig
}

compileVidStab() {
        hasBeenInstalled vidstab true

        [ $CHECK -eq 0 ] \
        && echo "--- Skipping already built vidstab" \
        || {
                DIR=/tmp/vidstab
                mkdir -p "$DIR"
                cd "$DIR"

                git clone --depth 1 https://github.com/georgmartius/vid.stab.git
                mkdir -p vid.stab/build
                cd vid.stab/build

                cmake \
                        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
                        -DBUILD_SHARED_LIBS=ON \
                        ..

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libvidstab
}

compileLibPng() {
        # TODO: check artifact
        hasBeenInstalled libPng true

        [ $CHECK -eq 0 ] \
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
                        --enable-shared=yes \
                        --enable-static=no \
                        --enable-unversioned-links \
                        --enable-unversioned-libpng-pc \
                        --enable-unversioned-libpng-config

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }
}

compileOpenJpeg() {
        hasBeenInstalled libopenjp2 true

        [ $CHECK -eq 0 ] \
        && echo "--- Skipping already built OpenJpeg" \
        || {
                DIR=/tmp/openjpeg
                mkdir -p "$DIR"
                cd "$DIR"

                git clone --depth 1 https://github.com/uclouvain/openjpeg.git
                cd openjpeg

                cmake -G "Unix Makefiles" \
                        -DBUILD_SHARED_LIBS=ON \
                        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libopenjpeg
}

compileWebp() {
        hasBeenInstalled libwebp true

        [ $CHECK -eq 0 ] \
        && echo "--- Skipping already built libWebp" \
        || {
                DIR=/tmp/webp
                mkdir -p "$DIR"
                cd "$DIR"

                git clone --depth 1 https://github.com/webmproject/libwebp.git
                cd libwebp

                ./autogen.sh
                ./configure \
                        --prefix="$PREFIX" \
                        --enable-shared=yes \
                        --enable-static=no

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libwebp
}

installLibPng() {
        apk add --no-cache libpng-dev
}

compileFdkAac() {
        hasBeenInstalled fdk-aac true

        [ $CHECK -eq 0 ] \
        && echo "--- Skipping already built fdk-aac" \
        || {
                DIR=/tmp/fdkaac
                mkdir -p "$DIR"
                cd "$DIR"

                git clone --depth 1 https://github.com/mstorsjo/fdk-aac
                cd fdk-aac

                autoreconf -fiv
                ./configure \
                        --prefix="$PREFIX" \
                        --enable-shared=yes \
                        --enable-static=no

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libfdk-aac
}

compileMp3Lame() {
        [ -e "$PREFIX/lib/libmp3lame.so" ] \
        && echo "--- Skipping already built mp3lame" \
        || {
                DIR=/tmp/mp3lame
                mkdir -p "$DIR"
                cd "$DIR"

                wget https://sourceforge.net/projects/lame/files/lame/$LIBMP3LAME_VERSION/lame-$LIBMP3LAME_VERSION.tar.gz/download -O lame.tar.gz
                tar xzf lame.tar.gz
                cd lame*

                ./configure \
                        --prefix="$PREFIX" \
                        --enable-shared=yes \
                        --enable-static=no

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libmp3lame
}

compileOpus() {
        hasBeenInstalled opus true

        [ $CHECK -eq 0 ] \
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
                        --enable-shared=yes \
                        --enable-static=no \
                        --disable-doc \
                        --disable-extra-programs

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libopus
}

installOgg() {
        apk add --no-cache libogg-dev
}

compileOgg() {
        hasBeenInstalled ogg true

        [ $CHECK -eq 0 ] \
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
                        --enable-shared=yes \
                        --enable-static=no

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        THEORA_FLAGS="$THEORA_FLAGS --with-ogg=\"$PREFIX/lib\" --with-ogg-libraries=\"$PREFIX/lib\" --with-ogg-includes=\"$PREFIX/include/\""
}

compileSpeex() {
        hasBeenInstalled speex true

        [ $CHECK -eq 0 ] \
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
                        --enable-shared=yes \
                        --enable-static=no

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libspeex
}

compileTheora() {
        hasBeenInstalled theora true

        [ $CHECK -eq 0 ] \
        && echo "--- Skipping already built theora" \
        || {
                provide Ogg
                provide Vorbis

                echo "--- Installing Theora"

                DIR=/tmp/theora
                mkdir -p "$DIR"
                cd "$DIR"

                git clone --depth 1 https://github.com/xiph/theora.git
                cd theora

                ./autogen.sh
                ./configure \
                        --prefix="$PREFIX" \
                        --enable-shared=yes \
                        --enable-static=no \
                        --disable-doc \
                        --disable-examples \
                        $THEORA_FLAGS


                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libtheora
}

compileVorbis() {
        hasBeenInstalled vorbis true

        [ $CHECK -eq 0 ] \
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
                        --enable-shared=yes \
                        --enable-static=no

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        THEORA_FLAGS="$THEORA_FLAGS  --with-vorbis=\"$PREFIX/lib\" --with-vorbis-libraries=\"$PREFIX/lib\" --with-vorbis-includes=\"$PREFIX/include/\""
        addFeature --enable-libvorbis
}

compileAom() {
        hasBeenInstalled aom true

        [ $CHECK -eq 0 ] \
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
                        -DBUILD_SHARED_LIBS=ON \
                        -DENABLE_TESTS=0 \
                        -DENABLE_EXAMPLES=OFF \
                        -DENABLE_DOCS=OFF \
                        -DENABLE_TOOLS=OFF \
                        -DAOM_TARGET_CPU=generic \
                        ..

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libaom
}

compileDav1d() {
        hasBeenInstalled dav1d true

        [ $CHECK -eq 0 ] \
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

                ninja -C build \
                && ninja -C build install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libdav1d
}

compileVpx() {
        hasBeenInstalled vpx true

        [ $CHECK -eq 0 ] \
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
                        --disable-static \
                        --enable-shared \
                        --disable-examples \
                        --disable-tools \
                        --disable-install-bins \
                        --disable-docs \
                        --target=generic-gnu \
                        --enable-vp8 \
                        --enable-vp9 \
                        --enable-vp9-highbitdepth \
                        --enable-pic \
                        --disable-debug

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libvpx
}

compileX264() {
        hasBeenInstalled x264 true

        [ $CHECK -eq 0 ] \
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
                        --enable-shared \
                        --enable-pic \
                        --disable-cli

                make \
                && make install \
                && cd \
                && rm-rf "$DIR"
        }

        addFeature --enable-libx264
}

compileXvid() {
        hasBeenInstalled xvid true

        [ $CHECK -eq 0 ] \
        && echo "--- Skipping already built xvid" \
        || {
                DIR=/tmp/xvid
                mkdir -p "$DIR"
                cd "$DIR"

                wget https://downloads.xvid.com/downloads/xvidcore-${XVID_VERSION}.tar.gz -O xvid.tar.gz
                tar xf xvid.tar.gz
                cd xvidcore/build/generic/

                CFLAGS="$CLFAGS -fstrength-reduce -ffast-math" ./configure \
                        --prefix="${PREFIX}" \
                        --bindir="${PREFIX}/bin"

                make \
                && make install \
                && cd \
                && rm -rf "$DIR"
        }

        addFeature --enable-libxvid
}


