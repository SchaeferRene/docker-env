# Music player Daemon [mpd]
## Description
This mpd docker container is intended for use as an always up and running internet radio. Different from other images, this one is controlled by a watchdog script, which starts mpd if it is not running, triggers play if not playing, and restarts playing if frozen. The original script can be found [here](https://gist.github.com/5ess/7d29a6e285cd641b6e17).

### Preparation
Prior to building this image pulse audio socket must be set up: see [Setup Pulse Audio Socket](./SetupPulseAudioSocket.md)

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
