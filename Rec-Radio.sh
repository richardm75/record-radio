#!/usr/bin/env bash
# Copyright 2023 Richard Mott
#
# This bash shell script records a live internet radio show tramsitted via HLS/DASH or Icecast/Shoutcast using ffmpeg.
# (Optional) Log script run start/end times.
# It requires ffmpeg installed. 

# IMPORTANT: See SETUP SECTION below to set paths.

# Three parameters are required
#    Station         # The name of the station streaming the show, NO SPACES ARE ALLOWED, EVER
#    NameOfShow      # Note: NO SPACES ARE ALLOWED, EVER
#    nn              # Time in minutes of recording
# e.g.
# Rec-Radio.sh KPBS MyShow 30
#
# The recorded filename will be "NameOfShow-date_time_rec.mp3"
# The recorded file will be placed under the given recording path.
# Metadata (ID3) will be added. For available tags see https://gist.github.com/eyecatchup/0757b3d8b989fe433979db2ea7d95a01
# Use cron to schedule recordings. 
#
# SETUP SECTION
# ============= 
# Change the next variables to set file paths. IMPORTANT: Do not include / on the end of paths.
# IMPORTANT: these paths must exist or the script will fail to store the recorded file, sometimes without flagging an error.
# Location of ffmpeg. If installed to a standard path, just leave this as `ffmpeg`.
# If installed to a private location, enter /full-path/ffmpeg
ffmpegPath="ffmpeg"
# Location to store recordings.
# Note: a subdirectory /NameOfShow will be added automatically.
RecordingPath="$HOME/Radio-Recordings"
# Log File (optional)
# LoggingRequired can be "yes" or "no". If "yes", also set the file path for log file RecLog.txt.
LoggingRequired="yes"
LogfilePath="$HOME/Radio-Recordings"
# Details for the station to be recorded. Add as many as you wish.
declare -A stations
stations["station-name-1"]="http://station-1-stream-url"
stations["station-name-2"]="http://station-2-stream-url"
# END OF SETUP
# ============
#

echo "DO NOT CLOSE THIS TERMINAL - Recording in progress"
echo "Recording $* mins. Started on $(date)"

NameOfStation=$1
NameOfShow=$2
Mins=$3

# If logging is active, log start of task
if [[ ${LoggingRequired} == "yes" ]]; then
    echo "$(date): $(basename "$0") Recording start: ${NameOfShow} for ${Mins} minutes to ${RecordingPath}" >> "${LogfilePath}/RecLog.txt"
fi

# Discover stream URL from the station name
StationName=""
for key in ${!stations[@]};
do 
    if [[ ${NameOfStation,,} == ${key,,} ]]; then
        StationName=${key}
        Stream=${stations[$key]}
        break
    fi
done
if [[ ${StationName} == "" ]]; then
    echo "Station Name not recognized. Script is terminating."
    exit
fi

# Recording will be placed in /tmp/rpiradio/
# Why there? We cannot use RecordingPath/temp because pscp is used in rpiradio.bat to fetch mp3 files.
# Unfortunately, pscp acts like find and finds all mp3 file below RecordingPath. To avoid that problem we use /tmp.
# Beware: on Pi, /tmp gets cleared out every night. So we need to recreate /tmp/rpiradio/ if it is missing. 
if [ ! -e "/tmp/rpiradio" ]; then
    mkdir "/tmp/rpiradio"
fi

timestamp=$(date +%Y%m%d_%H-%M)
title=$(date +%d/%m/%Y)

if [[ ${Mins} == "" ]]; then 
    Mins=1
fi
secs=$(( Mins * 60 ))

# Make sure a sleeping hard drive spins up before downloading
touch "/tmp/rpiradio/spin-up-sleeping-HD"
# Pause to let the network get established
sleep 1s
# Remove the HD spin-up file
rm "/tmp/rpiradio/spin-up-sleeping-HD"

# Now download the stream for the show
"${ffmpegPath}" -i ${Stream} \
-map 0:a:0 -t ${secs} -filter:a "volume=3dB" -y -hide_banner -loglevel warning \
-metadata album="${NameOfShow}" -metadata title="${title}" -metadata date="$(date +%Y)" -metadata artist="${StationName}" \
"/tmp/rpiradio/${NameOfShow}-${timestamp}_rec.mp3"

ErrorLevel=$?
if [[ ${ErrorLevel} != "0" ]]; then
    if [[ ${LoggingRequired} == "yes" ]]; then
        echo "Error after ffmpeg. ErrorLevel is ${ErrorLevel}" >> "${LogfilePath}/RecLog.txt"
		echo "Variables: NameOfShow=${NameOfShow}, Mins=${Mins}, date=$(date)" >> "${LogfilePath}/RecLog.txt"
		echo "secs=${secs}, ffmpegpath=${ffmpegPath}, title=${title}" >> "${LogfilePath}/RecLog.txt"
		echo "RecordingPath=${RecordingPath}, timestamp=${timestamp}, stream=${Stream}" >> "${LogfilePath}/RecLog.txt"
    fi
    exit
else
    mv "/tmp/rpiradio/${NameOfShow}-${timestamp}_rec.mp3" "${RecordingPath}/"

    # If logging is active, log end of task
    if [[ ${LoggingRequired} == "yes" ]]; then
        echo "$(date): $(basename "$0") Recording end  : ${NameOfShow} for ${Mins} minutes to ${RecordingPath}" >> "${LogfilePath}/RecLog.txt"
    fi
fi

exit
