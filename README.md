# docker-env
## About
`docker-env` is my personal playground to create different Docker images for different architectures. It has been tested with:

* armv7h (ArchLinux on Odroid-XU4)
* x86_64 (Manjaro on Schenker XMG)

## Whats in it?
* Script to create alpine based docker base image from scratch
* build nginx image on top of base image

# Usage
## create_docker_images.sh
Run the ain script `create_docker_images.sh` as a docker enabled user in order to create the docker images. The script can be controlled by the following command line arguments:

* `-h` | `--help` - display help
* `-p` | `--push` - push created images to docker registry
* `-l` | `--logs` - once deployed, follow the logs of deployed services
* `--nginx` - build nginx service

## set_env.sh
Source the script `set_env.sh` to have the environment variables set, so you can run docker-compose commands on your own.

# Configuration
*tbd*
