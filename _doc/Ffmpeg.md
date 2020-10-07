# Ffmpeg
## `compileFfmpeg` script
This is most likely the hardest build I've ever made (and most likely will be). x265 and v4l will certainly give me bad dreams for years.

It's not complete yet, but at least it has reached a usable state. The script to compile ffmpeg took a lot of effort, googling tons of websites where people smarter than me solved a particular issue, and also involving lots of trial and error. With all that the script most likely has turned into the most comprehensive guide on how to compile ffmpeg for Alpine ARM devices currently in existence and publicly available. It might not run on all machines, but at least it runs on my Odroid-XU4, which is all that matters to me for now.

## What's in it, what's next?
The script compiles a static version of ffmpeg with hardened toolchain, containing the following features:

- done:
    - aom
    - ass
    - dav1d
    - fontconfig
    - freetype
    - fribidi
    - kvazaar
    - libfdk-aac
    - mp3lame
    - openjpeg
    - openssl
    - opus
    - soxr
    - speex
    - theora
    - vidstab
    - vorbis
    - vp8
    - vp9
    - webp
    - x264
    - x265
    - xml2
    - xvid
    - zimg
- wip:
    - v4l
- todo:
    - opencv
    - hardware acceleration
    - optimizations for Raspberry Pi, Nvidia, Mali

# Links
These are the main resources that helped me most in creating this script:

- [Ffmpeg Compilation Guide](https://trac.ffmpeg.org/wiki/CompilationGuide)
- [Linux from Scratch](http://www.linuxfromscratch.org/blfs/view/svn/index.html)
- [JRottenberg's Alpine Ffmpeg Docker Image](https://github.com/jrottenberg/ffmpeg/blob/master/docker-images/4.3/alpine38/Dockerfile)
- [MWader's statically compiled Ffmpeg Docker image](https://hub.docker.com/r/mwader/static-ffmpeg/dockerfile)

