#!/bin/bash
#####################################################################################
# This file is part of the FGCom-mumble distribution (https://github.com/hbeni/fgcom-mumble).
# Copyright (c) 2020 Benedikt Hallinger
# 
# This program is free software: you can redistribute it and/or modify  
# it under the terms of the GNU General Public License as published by  
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see <http://www.gnu.org/licenses/>. ]]
#####################################################################################
#
# FGCOM-mumble bot manager
# 
# This script is intendet as the main server side "executable".
# It will:
#   - setup a fifo filenode
#   - spawn a radio recorder bot into the channel and instructs it to notify to the generated fifo
#   - read from the fifo to call playback bots for new samples
#


# Define defaults
host="localhost"
port="64738"
rcert="recbot.pem"
rkey="recbot.key"
pcert="playbot.pem"
pkey="playbot.key"
path="./recordings"
limit="120" # default time limit for recordings in secs
ttl="7200"  # default time-to-live after recordings in secs
fnotify="/tmp/fgcom-fnotify-fifo"

recorderbot_log=/dev/null
playbackbot_log=/dev/null

# print usage information
function usage() {
    echo "Manage FGCOM-mumble bots"
    echo "Options:"
    echo "    --help -h  print usage and exit"
    echo ""
    echo "Common options, that will be passed to bots:"
    echo "    --host=    host to connect to               (default=$host)"
    echo "    --port=    port to connect to               (default=$port)"
    echo ""
    echo "Recording bot options:"
    echo "    --rcert=   path to PEM encoded cert         (default=$rcert)"
    echo "    --rkey=    path to the certs key            (default=$rkey)"
    echo "    --path=    Path to store the recordings to  (default=$path)"
    echo "    --limit=   Max limit to record, in seconds  (default=$limit)"
    echo "    --ttl=     Max timeToLive in seconds        (default=$ttl)"
    echo "    --fnotify= fifo to where the recorder notifies (default=$fnotify)"
    echo "    --rlog=    Recorder bot logfile (\"-\"=STDOUT) (default=$recorderbot_log)"
    echo ""
    echo "Playback bot options:"
    echo "    --pcert=   path to PEM encoded cert         (default=$pcert)"
    echo "    --pkey=    path to the certs key            (default=$pkey)"
    echo "    --plog=    Playback bot logfile (\"-\"=STDOUT) (default=$playbackbot_log)"
}

# Parse cmdline args
for opt in "$@"; do
    case $opt in
       --help)  usage; exit 0  ;;
       -h)      usage; exit 0 ;;
       --host=*)  host=$(echo $opt|cut -d"=" -f2);;
       --port=*)  port=$(echo $opt|cut -d"=" -f2);;
       --rcert=*) rcert=$(echo $opt|cut -d"=" -f2);;
       --rkey=*)  rkey=$(echo $opt|cut -d"=" -f2);;
       --pcert=*) pcert=$(echo $opt|cut -d"=" -f2);;
       --pkey=*)  pkey=$(echo $opt|cut -d"=" -f2);;
       --path=*)  key=$(echo $opt|cut -d"=" -f2);;
       --limit=*) limit=$(echo $opt|cut -d"=" -f2);;
       --ttl=*)   ttl=$(echo $opt|cut -d"=" -f2);;
       --fnotify=*)   fnotify=$(echo $opt|cut -d"=" -f2);;
       --plog=*)  playbackbot_log=$(echo $opt|cut -d"=" -f2);;
       --rlog=*)  recorderbot_log=$(echo $opt|cut -d"=" -f2);;
       *) echo "unknown option $opt!"; usage; exit 1;;
   esac
done

# Print a nice message when starting, so its clear what will happen
echo "Starting FGCom-mumble bot manager..."
echo "  --host=$host"
echo "  --port=$port"
echo "  --rcert=$rcert"
echo "  --rkey=$rkey"
echo "  --pcert=$pcert"
echo "  --pkey=$pkey"
echo "  --path=$path"
echo "  --limit=$limit"
echo "  --ttl=$ttl"
echo "  --rlog=$recorderbot_log"
echo "  --plog=$playbackbot_log"

# define cmd options for the bot callups
common_opts="--host=$host --port=$port"
playback_opts="$common_opts --cert=$pcert --key=$pkey"
recorder_opts="$common_opts --cert=$rcert --key=$rkey --path=$path --limit=$limit --ttl=$ttl"


# setup the fifo
echo "Setup fifo '$fnotify'"
trap "rm -f $fnotify" EXIT

if [[ ! -p $fnotify ]]; then
    mkfifo $fnotify
fi

if [[ ! -p "$fnotify" ]]; then
    echo "error creating/opening fifo $fnotify"
    exit 1
fi


# Spawn the radio recorder bot
recorderbot_cmd="luajit fgcom-radio-recorder.bot.lua $recorder_opts --fnotify=$fnotify"
echo "Spawn bot: $recorderbot_cmd"
if [ -n $recorderbot_log ] && [ $recorderbot_log != "-" ]; then
    $recorderbot_cmd > $recorderbot_log &
else
    $recorderbot_cmd &
fi

# wait for new recordings and call playback bots
while true; do
    if read line <$fnotify; then
        if [[ "$line" == 'quit' ]]; then
            break
        fi
        date "+[%Y-%m-%d %H:%M:%S] notification received: '$line'"
        
        #spawn bot
        playbackbot_cmd="luajit fgcom-radio-playback.bot.lua $playback_opts --sample=$line"
        echo "Spawn bot: $playbackbot_cmd"
        if [ -n $playbackbot_log ] && [ $playbackbot_log != "-" ]; then
            $playbackbot_cmd > $playbackbot_log &
        else
            $playbackbot_cmd &
        fi
    fi
done

echo "Reader exiting"
