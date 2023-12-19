#!/bin/bash

# help message
HELP_MESSAGE="Simple script for controlling display brightness using i2c-dev and ddcutil

./backlignt [command] [arguments...]

Commands: ([command])
  get-displays                          Get all display numbers
  get-brightness DISPLAY_NUM            Get the max brightness for a specific display, returns a value between [0-100]
  set-brightness DISPLAY_NUM BRIGHENESS Set the brightness for a specific display, expects a value between [0-100]
"

# utility to check whether the last command failed
check_failed() {
 local exit_code=$?

 if [[ $exit_code -eq 0 ]]; then
  return 0
 fi

 # $1 fmt string, $2 args (optional)
 local msg="$(printf "$1" "$2"; printf TERMINATOR)"
 msg="${msg%TERMINATOR}"

 printf "$msg" >&2
 exit $exit_code
}

# print help and exit
help_and_exit() {
 # $1 fmt string, $2 args (optional)
 local msg="$(printf "$1" "$2"; printf TERMINATOR)"
 msg="${msg%TERMINATOR}"

 # $3 exit code (optional)
 local exit_code=${3:--1}

 printf "$HELP_MESSAGE"
 printf "$msg" >&2
 exit $exit_code
}

# ensure i2c-dev module is loaded
lsmod | grep -i i2c_dev &> /dev/null 
if [[ $? -ne 0 ]]; then
 printf 'The i2c-dev kernel module is not loaded!\n'
 exit -1
fi

# ensure required commands are present
declare -a CMDS=("ddcutil" "sed")
for cmd in "${CMDS[@]}" ; do
 if ! command -v $cmd &> /dev/null; then
  printf '%s is requried to run this script!\n' "$cmd"
  exit -1
 fi
done
unset CMDS

# returns an array of display integers
get_displays() {
 local exit_code
 local displays
 displays="$(ddcutil detect | sed -rn 's/^Display ([[:digit:]])$/\1/p' | tr '\n' ' ' 2> /dev/null)"
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 echo $displays
 return 0
}

# returns the raw output of ddcutil for vcp 0x10
declare -A BRIGHTNESS_INFO
get_brightness_information() {
 # need display number
 if [[ -z "${1+x}" ]]; then
  return -1
 fi

 local exit_code
 local brightness_info

 # cache ddcutil info since it's slow
 if [[ -z "${BRIGHTNESS_INFO[$1]}" ]]; then
  # if cache not populated, fetch and populate
  brightness_info="$(ddcutil -d $1 getvcp 0x10 2> /dev/null)"
  exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
   return $exit_code
  fi

  BRIGHTNESS_INFO[$1]="$brightness_info"
 else
  # if cache already popualted, reuse
  brightness_info="${BRIGHTNESS_INFO[$1]}"
 fi

 echo "$brightness_info"
 return 0
}

# returns the non-normalized max integer value for the brightness of a display
get_max_brightness_raw() {
 # need display number
 if [[ -z "${1+x}" ]]; then
  return -1
 fi

 local exit_code
 local max_brightness
 # get the brightness info from ddcutil 
 max_brightness="$(get_brightness_information $1)"
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 # parse out the max brightness
 max_brightness="$(echo "$max_brightness" | sed -r '/.*max value\s*=\s*([[:digit:]]+).*/!{q1}; {s//\1/}')"
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 echo "$max_brightness"
 return 0
}

# returns the non-normalized current integer value for the brightness of a display
get_current_brightness_raw() {
 # display number required
 if [[ -z "${1+x}" ]]; then
  return -1
 fi

 local exit_code
 local current_brightness
 current_brightness="$(get_brightness_information $1)"
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 current_brightness="$(echo "$current_brightness" | sed -r '/.*current value\s*=\s*([[:digit:]]+).*/!{q1}; {s//\1/}')"
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 echo "$current_brightness"
 return 0
}

# returns the normalized brightness for a display on a scale from [0-100]
get_brightness_percent() {
 # display number required
 if [[ -z "${1+x}" ]]; then
  return -1
 fi

 local exit_code

 local max_brightness
 max_brightness="$(get_max_brightness_raw $1)"
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 local current_brightness
 current_brightness="$(get_current_brightness_raw $1)"
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 echo "$((100 * $current_brightness / $max_brightness))"
 return 0
}

# sets the brightness percentage for a display; input range [0-100]
set_brightness_percent() {
 # $1 is the display number, $2 is the percent
 if [[ $# -ne 2 ]]; then
  return -1
 elif [[ -z "${1+x}" || -z "${2+x}" ]]; then
  return -1
 fi

 # brightness must be between 0 and 100 inclusive
 if [[ $2 -le 0 || $2 -gt 100 ]]; then
  return -1
 fi

 local exit_code
 local max_brightness
 max_brightness="$(get_max_brightness_raw $1)"
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 # calculate and set new brightness
 local new_brightness=$((($2 * $max_brightness) / 100))
 ddcutil -d $1 setvcp 0x10 $new_brightness &> /dev/null
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return -1
 fi
}

# handle command dispatch
handle_command() {
 local exit_code
 case "$1" in
  get-displays)
   get_displays | tr ' ' '\n'
  ;;

  get-brightness)
   if [[ -z "${2+x}" ]]; then
    help_and_exit "Missing display number!\n"
   fi
   get_brightness_percent $2
   check_failed "Failed to retrieve display brightness!\n"
  ;;

  set-brightness)
   if [[ -z "${2+x}" ]]; then
    help_and_exit "Missing display number!\n"
   fi
   if [[ -z "${3+x}" ]]; then
    help_and_exit "Missing brightness value!\n"
   fi
   set_brightness_percent $2 $3
   check_failed "Failed to set display brightness!\n"
  ;;

  *)
    help_and_exit "Unrecognizied command: '%s'\n" "$1"
  ;;
 esac
}

# only run the CLI if this script was not sourced
if [[ "${BASH_SOURCE[0]}" -ef "$0" ]]; then
 handle_command "$@"
fi
