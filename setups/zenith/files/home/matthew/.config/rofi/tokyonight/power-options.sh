#!/bin/bash

SCRIPT_DIR=$(dirname "$0") && [[ "$SCRIPT_DIR" == "." ]] && SCRIPT_DIR="$(pwd)"
OPTIONS='shutdown\nreboot\nfirmware'

SELECTED="$(echo -e "$OPTIONS" | rofi -config "$SCRIPT_DIR/tokyonight-power-config.rasi" -dmenu -p " ")"
if [[ $? -ne 0 ]]; then
 printf "No option selected\n"
 exit 0
fi
printf 'Selected: %s\n' "$SELECTED"

case "$SELECTED" in
 shutdown) systemctl poweroff;;
 reboot) systemctl reboot;;
 firmware) systemctl reboot --firmware-setup;;
esac
