#! /bin/sh
# This script monitors mpd while it is playing an internet stream. It checks every $INTERVAL_CHECK seconds
# to see if the status time variable has changed. (The stream is not playing when the time
# is not changing.) Then it restarts playing.
#
# It also checks the current state of MPD and only takes care of state 'play'. This provides you the comfort
# to use MPD like before without having to care about the watchdog when you want to pause or stop the stream.
#
# If the mpd daemon is not running for some reason, it starts it. i.e. if mpd were to crash.
#
# This is great for a robust stream player that keeps on playing, even after a network
# outage or stream server outage. Useful in situations where the networking is less than perfect.
#
# Also does logging trough syslog.

INTERVAL_CHECK=30  # Seconds between checks
INTERVAL_WAIT=10  # Seconds to wait after mpd (re)start (buffering)
LOG_TAG="mpd-watchdog"

LOGGER="logger -st \"$LOG_TAG\" -- "

$LOGGER Startup with interval of $INTERVAL_CHECK Seconds
OLD_TIME=
OLD_STATE="UNKNOWN"
SLEEP_INTERVAL=0
MPD_COMMAND="/usr/bin/mpd --stdout"

while sleep $SLEEP_INTERVAL;
do
       SLEEP_INTERVAL=$INTERVAL_CHECK

       ps -A | egrep -c "^[[:blank:]]+[0-9]+[[:blank:]]mpd.*${MPD_COMMAND}$"

       STATUS=`ps -A | egrep -c "^[[:blank:]]+[0-9]+[[:blank:]]mpd.*${MPD_COMMAND}$"`
       if [ $STATUS -eq 0 ]; then
               $LOGGER "no mpd processes, starting mpd"
               /usr/bin/mpd --stdout
               $LOGGER waiting $INTERVAL_WAIT Seconds...
               sleep $INTERVAL_WAIT
               continue
       fi

       TIME="0"
       STATE="UNKNOWN"
       RESP=`echo -e "status\\nclose" | nc localhost 6600 `

       IFS=": "
       echo "$RESP" | while read KEY VALUE; do
               case "$KEY" in
                       state) STATE="$VALUE";;
                       time)  TIME="$VALUE";;
               esac
       done
       unset IFS

       if   [ "$OLD_STATE" != "$STATE" ]; then
               $LOGGER "MPD changed state from '$OLD_STATE' to '$STATE' "
       fi
       if   [ "$STATE" == "play" ]; then
               if [ "$TIME" = "$OLD_TIME" ]; then
                       $LOGGER "mpd hanging, restarting"
                       mpc stop
                       mpc play
                       $LOGGER waiting $INTERVAL_WAIT Seconds...
                       sleep $INTERVAL_WAIT
               fi
       fi
       if   [ "$STATE" != "play" ]; then
            $LOGGER "mpd stopped, restarting"
            mpc play
            $LOGGER waiting $INTERVAL_WAIT Seconds...
            sleep $INTERVAL_WAIT
       fi
       OLD_STATE=$STATE
       OLD_TIME=$TIME
done

