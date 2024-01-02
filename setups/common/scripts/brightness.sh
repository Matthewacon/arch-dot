#!/bin/bash

# help message
HELP_MESSAGE="Simple script for controlling display brightness using either sysfs or i2c-dev and ddcutil

./backlignt [backend] [command] [arguments...]

Backends: ([backend])
  sysfs:   Uses '/sys/class/backlight/*' for setting and getting brightness. User must be part of the 'video' group. 'DISPLAY_NUM' must be 0 for all commands when using the 'sysfs' backend
  ddcutil: Uses ddcutil and i2c-dev to get and set brightness. User must be part of the 'i2c' group

Commands: ([command])
  get-displays                          Get all display numbers. Unsupported on the 'sysfs' backend
  get-brightness DISPLAY_NUM            Get the max brightness for a specific display, returns a value between [0-100]
  set-brightness DISPLAY_NUM BRIGHENESS Set the brightness for a specific display, expects a value between [0-100]
  inc-brightness DISPLAY_NUM BRIGHTNESS Incremenet the brightness for a specific display, expects value between [0-100]
  dec-brightness DISPLAY_NUM BRIGHTNESS Decrement the brightness for a specific display, expects value between [0-100]
"

# utility math functions

# max of 2 values
min() {
 if [[ $# -ne 2 ]]; then
  return -1
 elif [[ -z "${1+x}" || -z "${2+x}" ]]; then
  return -1
 fi

 echo "$(($1 > $2 ? $2 : $1))"
}

# min of 2 values
max() {
 if [[ $# -ne 2 ]]; then
  return -1
 elif [[ -z "${1+x}" || -z "${2+x}" ]]; then
  return -1
 fi

 echo "$(($1 < $2 ? $2 : $1))"
}

# clamp a value to lower and upper bounds, inclusive
clamp() {
 # $1 - lower bound, inclusive
 # $2 - upper bound, inclusive
 # $3 - value
 if [[ $# -ne 3 ]]; then
  return -1
 elif [[ -z "${1+x}" || -z "${2+x}" || -z "${3+x}" ]]; then
  return -1
 fi

 local exit_code
 local lower
 local upper

 lower=$(min $2 $3)
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return -1
 fi

 upper=$(max $1 $lower)
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return -1
 fi

 echo $upper
}

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
ddcutil_get_displays() {
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
ddcutil_get_brightness_information() {
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
ddcutil_get_max_brightness_raw() {
 # need display number
 if [[ -z "${1+x}" ]]; then
  return -1
 fi

 local exit_code
 local max_brightness
 # get the brightness info from ddcutil
 max_brightness="$(ddcutil_get_brightness_information $1)"
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
ddcutil_current_brightness_raw() {
 # display number required
 if [[ -z "${1+x}" ]]; then
  return -1
 fi

 local exit_code
 local current_brightness
 current_brightness="$(ddcutil_get_brightness_information $1)"
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
ddcutil_get_brightness_percent() {
 # display number required
 if [[ -z "${1+x}" ]]; then
  return -1
 fi

 local exit_code

 local max_brightness
 max_brightness="$(ddcutil_get_max_brightness_raw $1)"
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 local current_brightness
 current_brightness="$(ddcutil_current_brightness_raw $1)"
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 echo "$((100 * $current_brightness / $max_brightness))"
 return 0
}

# sets the brightness percentage for a display; input range [0-100]
ddcutil_set_brightness_percent() {
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
 max_brightness="$(ddcutil_get_max_brightness_raw $1)"
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

# TODO:
ddcutil_inc_brightness_percent() {
 return -1
}

ddcutil_dec_brightness_percent() {
 return -1
}

# gets the raw max brightness value for the main display
sysfs_get_max_brightness_raw() {
 echo "$(</sys/class/backlight/intel_backlight/max_brightness)"
}

# gets the raw current brightness value for the main display
sysfs_get_current_brightness_raw() {
 echo "$(</sys/class/backlight/intel_backlight/actual_brightness)"
}

# gets the brightness percent for the main display
sysfs_get_brightness_percent() {
 local exit_code
 local max_raw
 local current_raw

 max_raw=$(sysfs_get_max_brightness_raw)
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 current_raw=$(sysfs_get_current_brightness_raw)
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 echo $((100 * $current_raw / $max_raw))
}

# sets the brightness percent for the main display
sysfs_set_brightness_percent() {
 # $1 is the percent
 if [[ $# -ne 1 ]]; then
  return -1
 elif [[ -z "${1+x}" ]]; then
  return -1
 fi

 # brightness must be between 0 and 100 inclusive
 if [[ $1 -le 0 || $1 -gt 100 ]]; then
  return -1
 fi

 local exit_code
 local max_raw
 max_raw=$(sysfs_get_max_brightness_raw)
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 echo "$((($1 * $max_raw) / 100))" > /sys/class/backlight/intel_backlight/brightness
}

# increments the screen brightness percent; results clamped to [0, 100]
sysfs_inc_brightness_percent() {
 # $1 - brightness
 if [[ -z "${1+x}" ]]; then
  return -1
 fi

 local exit_code
 local curr_percent
 local new_percent

 curr_percent=$(sysfs_get_brightness_percent)
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 new_percent=$(clamp 0 100 $(($curr_percent + $1)))
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 sysfs_set_brightness_percent $new_percent
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi
}

# decrements the screen brightness percent; results clamped to [0, 100]
sysfs_dec_brightness_percent() {
 # $1 - brightness
 if [[ -z "${1+x}" ]]; then
  return -1
 fi

 local exit_code
 local curr_percent
 local new_percent

 curr_percent=$(sysfs_get_brightness_percent)
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 new_percent=$(clamp 0 100 $(($curr_percent - $1)))
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi

 sysfs_set_brightness_percent $new_percent
 exit_code=$?
 if [[ $exit_code -ne 0 ]]; then
  return $exit_code
 fi
}

# handle command dispatch
handle_command() {
 local exit_code

 # Parse backend
 # $1 - backend
 local backend
 case "$1" in
  sysfs) backend='sysfs';;
  ddcutil) backend='ddcutil';;
  *)
   help_and_exit "Unrecognized backend '%s'\n" "$1"
  ;;
 esac

 # Handle command
 if [[ "$backend" -eq "sysfs" ]]; then
  # Handle sysfs backlight
  # $2 - command
  # $3 - display (always '0' for this backend)
  # $4... - command arguments
  if [[ $3 -ne 0 ]]; then
   help_and_exit "The 'sysfs' backend does not support multiple displays. This value must always be '0'!\n"
  fi

  case "$2" in
   get-displays)
    help_and_exit "Unsupported command for the 'sysfs' backend!\n"
   ;;

   get-brightness)
    sysfs_get_brightness_percent
    check_failed "Failed to retrieve display brightness!\n"
   ;;

   set-brightness)
    if [[ -z "${4+x}" ]]; then
     help_and_exit "Missing brightness value!\n"
    fi
    sysfs_set_brightness_percent $4
    check_failed "Failed to set display brightness!\n"
   ;;

   inc-brightness)
    if [[ -z "${4+x}" ]]; then
     help_and_exit "Missing brightness value!\n"
    fi
    sysfs_inc_brightness_percent $4
    check_failed "Failed to increment display brightness!\n"
   ;;

   dec-brightness)
    if [[ -z "${4+x}" ]]; then
     help_and_exit "Missing brightness value!\n"
    fi
    sysfs_dec_brightness_percent $4
    check_failed "Failed to decrement display brightness!\n"
   ;;

   *)
     help_and_exit "Unrecognizied command: '%s'\n" "$2"
   ;;
  esac
 elif [[ "$backned" -eq "ddcutil" ]]; then
  # Handle ddcutil backlight
  # $2 - command
  # $3 - display number
  # $4... - command arguments
  case "$2" in
   get-displays)
    ddcutil_get_displays | tr ' ' '\n'
   ;;

   get-brightness)
    if [[ -z "${3+x}" ]]; then
     help_and_exit "Missing display number!\n"
    fi
    ddcutil_get_brightness_percent $3
    check_failed "Failed to retrieve display brightness!\n"
   ;;

   set-brightness)
    if [[ -z "${3+x}" ]]; then
     help_and_exit "Missing display number!\n"
    fi
    if [[ -z "${4+x}" ]]; then
     help_and_exit "Missing brightness value!\n"
    fi
    ddcutil_set_brightness_percent $3 $4
    check_failed "Failed to set display brightness!\n"
   ;;

   inc-brightness)
    if [[ -z "${3+x}" ]]; then
     help_and_exit "Missing display number!\n"
    fi
    if [[ -z "${4+x}" ]]; then
     help_and_exit "Missing brightness value!\n"
    fi
    ddcutil_inc_brightness_percent $3 $4
    check_failed "Failed to increment display brightness!\n"
   ;;

   dec-brightness)
    if [[ -z "${3+x}" ]]; then
     help_and_exit "Missing display number!\n"
    fi
    if [[ -z "${4+x}" ]]; then
     help_and_exit "Missing brightness value!\n"
    fi
    ddcutil_dec_brightness_percent $3 $4
    check_failed "Failed to decrement display brightness!\n"
   ;;

   *)
     help_and_exit "Unrecognizied command: '%s'\n" "$2"
   ;;
  esac
 else
  # Raise error for unimplemented backend
  printf "Missing implementation for backend: '%s'!\n" "$backend"
  exit -1
 fi
}

# only run the CLI if this script was not sourced
if [[ "${BASH_SOURCE[0]}" -ef "$0" ]]; then
 handle_command "$@"
fi
