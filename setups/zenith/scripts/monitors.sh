#!/bin/bash

MAX_ATTEMPTS=5

check_failed() {
 if [[ $? -ne 0 ]]; then
  printf "Failed to set up displays, attempt $1 / $MAX_ATTEMPTS!\n"
  return 1
 fi

 return 0
}

for ((i=1; i < $(($MAX_ATTEMPTS + 1)); i++)); do
 printf "Attempting to configure displays ($i / $MAX_ATTEMPTS)...\n"
 xrandr --output DP-4 --off
 check_failed $1 || continue

 xrandr --output DP-2 --off
 check_failed $1 || continue

 xrandr --auto
 check_failed $i || continue

 sleep 2
 xrandr --output DP-4 --mode 3840x2160 --rate 144 #143.99
 check_failed $1 || continue

 xrandr --output DP-2 --mode 3840x2160 --rate 144 #143.99
 check_failed $1 || continue

 xrandr --output DP-4 --left-of DP-2
 check_failed $1 || continue

 printf "Displays configured!\n"
 displays_configured=0
 break
done

if [[ $displays_configured -ne 0 ]]; then
 printf "Failed to configure displays!\n"
 exit -1
fi
