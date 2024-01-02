#!/bin/bash

# TODO: help message
HELP_MESSAGE=""

# ensure required commands are present
declare -a CMDS=("conky")
for cmd in "${CMDS[@]}" ; do
 if ! command -v $cmd &> /dev/null; then
  printf '%s is requried to run this script!\n' "$cmd"
  exit -1
 fi
done
unset CMDS

# constants
PID_FILE="${HOME}/.local/conky.pid"
CONKY_BIN="$(which conky)"

# if the conky widget is already running, kill it
kill_everything() {
 if [[ ! -f "$PID_FILE" ]]; then
  return 0
 fi

 printf 'PID file found, killing old instances...\n'
 for pid in $(cat "$PID_FILE"); do
  if [[ ! "/proc/$pid/exe" -ef "$CONKY_BIN" ]]; then
   printf 'WARN: PID %d is not conky, refusing to kill!\n'
   continue
  fi

  printf 'Killing %d\n' $pid
  kill -9 $pid &> /dev/null
 done
 rm "$PID_FILE"
 printf 'Done!\n'

 return 0
}

# utility function to handle command failures and clean up
check_failed() {
 local exit_code=$?

 if [[ $exit_code -eq 0 ]]; then
  return 0
 fi

 # $1 fmt string, $2 args (optional)
 local msg="$(printf "$1" "$2"; printf TERMINATOR)"
 msg="${msg%TERMINATOR}"

 printf "$msg" >&2
 kill_everything
 exit $exit_code
}

# TODO: try without xwinwrap since conky shittly tries to manage its own xwindow properties
#  - also look into setting xinerama
# xwinwrap command to make the mpv / vlc frame opaque to the WM
xwin="xwinwrap \
 -sub WID\
 -ni\
 -fdt\
 -un\
 -a\
 -nf\
 -ov\
 -g 3840x2160+0+0 -- \
"

kill_everything
cd ~/.config/conky
$xwin $CONKY_BIN -w WID -c conky_playerctl.conf
