# Setup Pulse Audio Socket
In order for the mpd image to work, pulse audio socket must be established and mounted into the docker container. The required steps for an Arch Linux based system would be as follows:

1. update system and install required dependencies using your favourite package manager, e.g.
    ```bash
    yay -Suy
	yay -S pulseaudio pulseaudio-alsa pulsemixer
    ```

2. create user for the pulse service
    ```bash
	sudo useradd -U -G audio -m -s /bin/false pulse
	```
	
3. allow streaming via socket using `sudo vim /etc/pulse/system.pa` and adding
    ```
	# enable pulseaudio as a server via socket
	load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse-socket
	```

4. configure pulse deamon to not stop on idleing using `sudo vim /etc/pulse/daemon.conf` and adding
    ```
	exit-idle-time = -1
	```

5. configure clients to use the socket as default using `sudo vim /etc/pulse/client.conf` and adding
	```
	default-server = unix:/tmp/pulse-socket
	autospawn = no
	#daemon-binary = /bin/true
	#enable-shm = false
	```

6. create a `systemd` service to automatically run pulse audio server using `sudo vim /etc/systemd/system/pulseaudio.service` and adding
	```
	[Unit]
	Description=PulseAudio sound server
	#After=avahi-daemon.service network.target

	[Service]
	Type=notify
	ExecStart=/usr/bin/pulseaudio --system --disallow-exit --disallow-module-loading --realtime --no-cpu-limit --log-target=journal
	ExecReload=/bin/kill -HUP $MAINID
	Restart=always
	RestartSec=30

	[Install]
	WantedBy=multi-user.target
	```

7. reload config and start service
	```bash
	sudo systemctl daemon-reload
	sudo systemctl enable --now pulseaudio
	```

8. for access to `/tmp/pulse-socket` add user to pulse group
    ```bash
	gpasswd -a $USER pulse
	```

9. Optional: test pulse server
	```bash
	# check if device is ready
	alsamixer
	
	# test pulse
	pacat < /dev/urandom
	
	# respectively
	sudo -u pulse pacat < /dev/urandom

	# or
	pacmd play-sample pulse-hotplug 0
	```
	
10. Optional: Create playlist with your favorite internet radio station(s), e.g. using `vi /srv/docker/mpd/radio.m3u` and adding:
	```
    #EXTM3U

	#EXTINF:-1,Radio Bonn/Rhein-Sieg
	http://rbrs-live.cast.addradio.de/rbrs/live/mp3/high
    ```
    (see: [unofficial M3U and PLS specification](http://www.scvi.net/pls.htm))
