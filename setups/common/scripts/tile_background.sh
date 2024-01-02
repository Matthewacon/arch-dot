#!/bin/bash
SCRIPT_DIR=$(dirname "$0") && [[ "$SCRIPT_DIR" == "." ]] && SCRIPT_DIR="$(pwd)"
PID_FILE="${HOME}/.local/bg.pid"

# help string
read -r -d '' HELP_MESSAGE << EOM
Tile a video as the background across all monitors

./tile_background.sh [mpv | vlc] [PATH_TO_VIDEO]
EOM

# xwinwrap command to make the mpv / vlc frame opaque to the WM
xwin="xwinwrap \
 -sub WID\
 -ni\
 -fdt\
 -un\
 -b\
 -nf\
 -ov\
 -g %s -- \
"

# mpv alternative 
#--keepaspect=no
#--vo=vx
mpv="mpv \
 -wid WID\
 --no-config\
 --loop\
 --no-border\
 --vd-lavc-fast\
 --x11-bypass-compositor=no\
 --gapless-audio=yes\
 --hwdec=API\
 --really-quiet\
 --name=mpvbg\
 --keepaspect=no\
"

# vlc alternative
vlc="vlc \
 --loop\
 --qt-minimal-view\
 --no-qt-name-in-title\
 --no-video-title-show\
"

# if the background is already running, kill it
kill_everything() {
 if [[ -f "$PID_FILE" ]]; then
  printf 'PID file found, killing old instances...\n'
  for pid in $(cat $PID_FILE); do
   kill -9 $pid > /dev/null 2>&1
  done
  rm $PID_FILE
 fi
}

# simple utility function to handle command failures
check_failed() {
 local exit_code=$?

 # $1 fmt string, $2 args
 local msg
 if [[ -z "${1+x}" ]]; then
  msg="$(printf 'Critical command failed with exit code: %s\n' $exit_code; printf TERMINATOR)"
 else
  msg="$(printf "$1" "$2"; printf TERMINATOR)"
 fi
 msg=${msg%TERMINATOR}

 # if command failed, exit with error code and message
 if [[ $exit_code -ne 0 ]]; then
  printf "%s" "$msg"
  kill_everything > /dev/null 2>&1
  exit $exit_code
 fi
}

# ensure that all required dependencies are installed
ensure_dependencies_installed() {
 declare -a cmds=("xwinwrap" "$1")
 for cmd in "${cmds[@]}"; do
  if ! command -v $cmd &> /dev/null; then
   printf '%s is required to run this script!\n' "$cmd"
   exit -1
  fi
 done
}

# start background on all displays
start_background() {
 for screen in $(${SCRIPT_DIR}/screen_coordinates.sh | sort -u); do
  xwin_cmd=$(printf "$xwin" "$screen")
  printf 'Running %s\n' "$xwin_cmd $1 $2"
  $xwin_cmd $1 "$2" > /dev/null 2>&1 &
  printf '%s\n' "$!" >> "$PID_FILE"
 done
}

# if no background video was supplied, exit
if [[ $# -ne 2 ]]; then
 printf 'Missing required arguments!\n%s\n' "$HELP_MESSAGE"
 exit -1
fi

# validate video player argument
VIDEO_PLAYERS="mpv vlc"
echo $VIDEO_PLAYERS | grep "$1" > /dev/null 2>&1
check_failed "Invalid video player specified '%s'\nValid options are: mpv vlc\n" "$1"

# validate provided file path
if [[ ! -f "$2" ]]; then
 printf "The provided video file does not exist: '%s'\n" "$2"
 exit -1
fi

ensure_dependencies_installed "$1"
kill_everything > /dev/null 2>&1

sleep 3
start_background "${!1}" "$2"
