# Flash Video Downloader `youtube-dl`
## Description
`youtube-dl` can be used to download flash videos from the internet (not only youtube).

## Usage
The `youtube-dl` docker image is only built, not deployed, since it does not provide server functionality. Once the image is built, `youtube-dl` can be used by running:

```bash
docker run --rm -u $UID:$(id -g) -v $PWD:/downloads reneschaefer/youtube-dl-alpine-<ARCH>
```

For convenience, it is recommended to create an alias e.g. in `~/.bashrc` or `/etc/profile.d/aliases.sh`. For instance:

```bash
alias youtube-dl='P=$(pwd) docker run --rm -u $UID:$(id -g) -v "$P":/downloads reneschaefer/youtube-dl-alpine-armv7'
```

`youtube-dl` can then be used as if it was installed locally, e.g.:

```bash
# download video:
youtube-dl <URL>

# list available formats:
youtube-dl -F <URL>

# download video with particular format:
youtube-dl -f <FORMAT CODE> <URL>

# download and merge particular video only / audio only streams
youtube-dl -f <VIDEO FORMAT CODE>+<AUDIO FORMAT CODE> <URL>
```
