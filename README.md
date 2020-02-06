# docker-env
## About
`docker-env` is my personal playground to create and orchestrate different Docker images for different architectures on local machine.

The scripts have been tested with:

* armv7h (ArchLinux on Odroid-XU4)
* x86_64 (Manjaro on Schenker XMG)
* aarch64 (ArchLinux on Odroid-C2, Manjaro on Raspberry Pi 4)

## What's in it?
* Script to create [alpine](https://alpinelinux.org/) based docker base image from scratch
* build Music Player Deamon [mpd] image, intended mainly as an internet radio player

wip:
* *build Webserver and reverse proxy [nginx]*
* *build git hoster [gitea] for your private repositories*

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

* `ALPINE_VERSION` - the alpine version to build all images based on
* `DOCKER_ID` - The [DockerId](https://success.docker.com/article/how-do-you-register-for-a-docker-id) to be used to push the created images<br>(Make sure [log in](https://docs.docker.com/engine/reference/commandline/login/) to your account prior to running these scripts with `--push` option)
* `DOCKER_VOLUME_ROOT` - the root folder that holds all files and folders mounted into the docker images (see *Service specific configuration*)
* `PULSE_SOCKET` - the pulse audio socket to be mounted into and used by the docker containers (Default: `/tmp/pulse-socket`)

### Service specific configuration
_see particular services_

# Services
## Music player Daemon [mpd]
### Description
This mpd docker container is intended for use as an always up and running internet radio. Different from other images, this one is controlled by a watchdog script, which starts mpd if it is not running, triggers play if not playing, and restarts playing if frozen. The original script can be found [here](https://gist.github.com/5ess/7d29a6e285cd641b6e17).

### Setup
see [Setup Pulse Audio Socket](doc/SetupPulseAudioSocket.md)

### Configuration
The pulse socket file must be configured as `PULSE_SOCKET` in `.env` file.
Owning user and group will be picked up by `set_env.sh` and preconfigured in the environment variables
`PULSE_UUID` and `PULSE_GUID`, which are then picked up in the respective docker-compose file.

The pulse socket is mounted into the docker container as `/tmp/pulse-socket`.
Despite that, the following volumes are mounted into the container:
* `${DOCKER_VOLUME_ROOT}/mpd/music` (read only folder):
	
	your music library to be accessible by mpd

* `${DOCKER_VOLUME_ROOT}/mpd/playlists` (read/write folder):
	
	contains custom playlists or playlists created by mpd

* `${DOCKER_VOLUME_ROOT}/mpd/state` (read write file):
	
	persistant state of mpd

### Interfaces
The mpd docker container serves audio played on both the pulse socket and as http stream on port 8080.

The mpd server can be controlled through one of the many [mpd clients] connecting at port 6600.

## WebServer & Reverse Proxy [nginx]
*tbd*


## Scripts
### `create_docker_images.sh`
Run the ain script `create_docker_images.sh` as a docker enabled user in order to create the docker images. The script can be controlled by the following command line arguments:

* `-h` | `--help` - display help
* `-p` | `--push` - push created images to docker registry
* `-a` | `--all`  - build (and push) all features, though only deploying the ones specified
* `-l` | `--logs` - once deployed, follow the logs of deployed services
* `-r` | `--run`  - run created base image for further evaluation
* `--mpd` - build mpd service
* `--nginx` - build nginx service

### `set_env.sh`
Source the script `set_env.sh` to have the environment variables set, so you can run docker-compose commands on your own.


[gitea]: https://gitea.io/en-us/
[mpd]: https://www.musicpd.org
[mpd clients]: https://www.musicpd.org/clients/
[nginx]: https://www.nginx.com/
