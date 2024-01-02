#!/bin/bash
PID_FILE="${HOME}/.local/picom.pid"

# help string
HELP_MESSAGE="A script that manages a single instance of picom per session

Usage: ./picom.sh
"

# if picom is already running, kill it
if [[ -f "$PID_FILE" ]]; then
 printf 'PID file found, killing old instance...\n'
 for pid in $(cat $PID_FILE); do
  kill -9 $pid &> /dev/null
 done
 rm $PID_FILE
fi

# start picom
picom --config ~/.config/picom/picom.conf &> /dev/null || exit $?
echo "$!" > "$PID_FILE"
