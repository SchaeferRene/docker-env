



return 0

# copy libs
ldd $PREFIX/bin/ffmpeg | grep -v musl  | cut -d ' ' -f 3 | xargs -i cp {} /usr/local/lib/

# symlink libs
for lib in /usr/local/lib/*.so.*; do FN="${lib##*/}"; LN="${lib%%.so.*}.so"; ln -sf "$FN" "$LN"; done

# copy binaries
cp ${PREFIX}/bin/* /usr/local/bin/

# copy includes
mkdir /usr/local/include
cp -r $PREFIX/include/* /usr/local/include/

# copy and patch package config files
mkdir -p /usr/local/lib/pkgconfig
for pc in ${PREFIX}/lib/pkgconfig/*.pc; do sed "s:${PREFIX}:/usr/local:g" < "$pc" > /usr/local/lib/pkgconfig/"${pc##*/}"; done

