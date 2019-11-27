# docker-env
## About
`docker-env` is my personal playground to create Docker images for different architectures. It has been tested with:

* armv7h (Odroid-XU4)
* x86_64 (Schenker XMG)

## Whats in it?
* Script to create alpine based docker base image from scratch
* build nginx image on top of base image

# Usage
The script can be controlled by the following command line arguments

* `-h` | `--help` - display help
* `-p` | `--push` - push created images to docker registry
* `-l` | `--logs` - once deployed, follow the logs of deployed services
* `--nginx` - build nginx service

# Configuration
*tbd*
