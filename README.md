_Note:_ Updates are currently broken (at least for 32bit ARM devices) by the [Alpine Update 3.13.0](https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.13.0) with its time64 requirements and `docker build` / `docker-compose` not supporting setting seccomp profile via the `--security-opt` flag. Dunno when/if I'll find the time to get this fixed.

<hr/>

# docker-env
## About
`docker-env` is my personal playground to create and/or orchestrate different Docker images for different architectures on local machine.

The scripts have been tested with:

* armv7 (ArchLinux on Odroid-XU4)
* x86_64 (Manjaro on Schenker XMG)
* aarch64 (Manjaro on Raspberry Pi 4)

## Prerequisites
The following programs need to be installed for the scripts to be used:

* bash
* curl
* docker
* docker-compose

## Conventions
* The user running the scripts must belong to docker group. (use `sudo usermod -aG docker $USER` )
* The scripts expect all files and folders to be mounted into the docker containers to be located below `DOCKER_VOLUME_ROOT`.
* Images are always built from the latest program versions in the alpine repositories.
* Images are tagged with the `ALPINE_VERSION` they are created from.

## Configuration
### General configuration in `.env`
Central configuration is done in `.env`. This file is loaded both by `set_env.sh` script as well as `docker-compose` command. (*see: [Docker compose environment variables](https://docs.docker.com/compose/environment-variables/)*)

The `.env` file contains the following variables:

* `ALPINE_VERSION` - the Alpine version to build all alpine based images on
* `DOCKER_ID` - The [DockerId](https://success.docker.com/article/how-do-you-register-for-a-docker-id) to be used to push the created images<br>(Make sure [log in](https://docs.docker.com/engine/reference/commandline/login/) to your account prior to running these scripts with `--push` option)
* `DOCKER_VOLUME_ROOT` - the root folder that holds all files and folders mounted into the docker images (see *Service specific configuration*)
* ˋSECRETS_ROOTˋ - the directory where secrets are stored
* `PULSE_SOCKET` - the pulse audio socket to be mounted into and used by the docker containers (e.g. mpd) (Default: `/tmp/pulse-socket`)


# Services
## [gitea] Git repository manager
Gitea's web interface runs on port 3000, and the ssh interface is connected to port 2200.

## [ffmpeg]
for description and usage instructions see [Ffmpeg.md](_doc/Ffmpeg.md)

## [mpd] Music player Daemon
for description and usage instructions see [Mpd.md](_doc/Mpd.md)

## [nginx] WebServer & Reverse Proxy
*tbd*

## [PostgreSQL][postgres] database
The scripts use the official PostgreSQL imagei exposing it via standard port 5432. To use it store the credentials in a file named ˋpostgresUser.txtˋ respectively ˋpostgresPassword.txtˋ in the secrets directory.

## `youtube-dl` Flash Video Downloader
for description and usage instructions see [Youtube-dl.md](_doc/Youtube-dl.md)

## Scripts
### `create_docker_images.sh`
Run the main script `create_docker_images.sh` as a docker enabled user in order to create the docker images. The script can be controlled by the following command line arguments:

* `-h` | `--help` - display help
* `-p` | `--push` - push created images to docker registry
* `-a` | `--all`  - build (and push) all features, though only deploying the ones specified
* `-l` | `--logs` - once deployed, follow the logs of deployed services
* `-r` | `--run`  - run created base image for further evaluation
* `--ffmpeg` - build ffmpeg
* `--mpd` - build mpd service
* `--nginx` - build nginx service
* `--ydl` , `--youtube-dl` - build youtube-dl

### `set_env.sh`
Source the script `set_env.sh` to have the environment variables set, so you can run docker-compose commands on your own.

<b>Note:</b> there are service specific set_env scripts in _set_env folder, which would be needed
for manually running docker compose scripts as well.

### `docker-run-*.sh`
script to launch a base image for doing some evaluations.


<!-- links -->
[ffmpeg]: https://ffmpeg.org
[gitea]: https://gitea.io/en-us/
[mpd]: https://www.musicpd.org
[mpd clients]: https://www.musicpd.org/clients/
[nginx]: https://www.nginx.com/
[postgres]: https://hub.docker.com/_/postgres
