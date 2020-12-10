# Ffmpeg
## `compileFfmpeg` script
This is most likely the hardest build I've ever made (and most likely will be). x265 and v4l will certainly give me bad dreams for years.

It's not complete yet, but at least it has reached a usable state. The script to compile ffmpeg took a lot of effort, googling tons of websites where people smarter than me solved a particular issue, and also involving lots of trial and error. With all that the script most likely has turned into the most comprehensive guide on how to compile ffmpeg for Alpine ARM devices currently in existence and publicly available. It might not run on all machines, but at least it runs on my Odroid-XU4, which is all that matters to me for now.

## What's in it, what's next?
The script compiles a static version of the latest snapshot release ffmpeg with hardened toolchain, containing the following features:

    - aom										@latest from git
    - ass										@latest from git
        - with _fontconfig_
        - with _fribidi_
    - dav1d									@latest from git
    - davs									@latest from zip
    - fontconfig							<red>release 2.13.92</red>
        - with _freetype_
    - freetype								@latest from git
        - with _xml2_
        - with _harfbuzz_				@latest from git
            - with _freetype_
            - with cairo					@latest from git
                - with pixman			@latest from repo
                - with _fontconfig_
                - with glib2			@latest from git
                - with libPng			@latest from git
            - with graphite2			<red>release 1.3.10</red>
                - with _harfbuzz_
    - fribidi								@latest from repo
    - kvazaar								@latest from git
    - libfdk-aac							@latest from git
    - mp3lame								<red>release 3.100</red>
    - openjpeg								@latest from git
    - openssl								@latest from repo
    - opus									@latest from repo
    - pic
    - soxr									@latest from tar / repo
    - speex									@latest from git
    - theora									@latest from repo
    - vidstab								@latest from git
    - vorbis									@latest from repo
        - with ogg							@latest from repo
    - vp8 + vp9 aka. vpx					@latest from git
    - webp									@latest from git
    - x264									@latest from git
    - x265									@latest from git
    - xcb
    - xcb-shm
    - xcb-xfixes
    - xcb-shape
    - xml2									@latest from tar / repo
    - xavs									@latest from zip
    - xvid									<red>release 1.3.7</red>
    - zimg									@latest from git

Upcoming features are:

    - v4l
    - opencv
    - hardware acceleration
    - optimizations for Raspberry Pi, Nvidia, Mali

# Links
These are the main resources that helped me most in creating this script:

- [Ffmpeg Compilation Guide](https://trac.ffmpeg.org/wiki/CompilationGuide)
- [Linux from Scratch](http://www.linuxfromscratch.org/blfs/view/svn/index.html)
- [JRottenberg's Alpine Ffmpeg Docker Image](https://github.com/jrottenberg/ffmpeg/blob/master/docker-images/4.3/alpine38/Dockerfile)
- [MWader's statically compiled Ffmpeg Docker image](https://hub.docker.com/r/mwader/static-ffmpeg/dockerfile)
- [pkuvcl/buildFFmpegAVS2](https://github.com/pkuvcl/buildFFmpegAVS2/blob/master/build_linux.sh)
