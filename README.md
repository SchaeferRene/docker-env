# docker-env
## About
`docker-env` is my personal playground to create and orchestrate different Docker images for different architectures on local machine.

The scripts have been tested with:

* armv7h (ArchLinux on Odroid-XU4)
* x86_64 (Manjaro on Schenker XMG)
* aarch64 (ArchLinux on Odroid-C2)

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

## Configuration
### General configuration in `.env`
Central configuration is done in `.env`. This file is loaded both by `set_env.sh` script as well as `docker-compose` command. (*see: [Docker compose environment variables](https://docs.docker.com/compose/environment-variables/)*)

The `.env` file contains the following variables:

* `ALPINE_VERSION` - the alpine version to build all images based on
* `DOCKER_ID` - The [DockerId](https://success.docker.com/article/how-do-you-register-for-a-docker-id) to be used to push the created images<br>(Make sure [log in](https://docs.docker.com/engine/reference/commandline/login/) to your account prior to running these scripts)
* `DOCKER_VOLUME_ROOT` - the root folder that holds all files and folders mounted into the docker images (see *Service specific configuration*)
* `PULSE_SOCKET` - the pulse audio socket to be mounted into and used by the docker containers

### Service specific configuration
#### Music player Daemon [mpd]
*tbd*

#### WebServer & Reverse Proxy [nginx]
*tbd*


## Scripts
### `create_docker_images.sh`
Run the ain script `create_docker_images.sh` as a docker enabled user in order to create the docker images. The script can be controlled by the following command line arguments:

* `-h` | `--help` - display help
* `-p` | `--push` - push created images to docker registry
* `-l` | `--logs` - once deployed, follow the logs of deployed services
* `-r` | `--run`  - run created base image for further evaluation
* `--mpd` - build mpd service
* `--nginx` - build nginx service

### `set_env.sh`
Source the script `set_env.sh` to have the environment variables set, so you can run docker-compose commands on your own.


[gitea]: https://gitea.io/en-us/
[mpd]: https://www.musicpd.org
[nginx]: https://www.nginx.com/
