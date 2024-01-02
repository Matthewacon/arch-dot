#!/bin/bash

# help message
HELP_MESSAGE="
A script that spits out a text section for a conky script.
This is not indended to be invoked except inside of a conky script!

When there is a playerctl compatible media source running, the relevant art,
artist, title and album will be displayed with date information below. When no
playerctl compatible media source is running, only the date information will be
displayed.

Example usage: (some-conky-config.conf)

config.text = [[
\${execp /path/to/playerctl-conky-music-and-clock.sh}
]]
"

# check for required software
declare -a CMDS=("wget" "playerctl")
for cmd in "${CMDS[@]}"; do
 if ! command -v $cmd &> /dev/null; then
  printf '%s is required to run this script!\n' "$cmd"
  exit -1
 fi
done
unset CMDS

# this script takes no arguments
if [[ $# -ne 0 ]]; then
 printf "This script takes no arguments.\n%s\n" "$HELP_MESSAGE"
 exit -1
fi

# TODO: handle multiple players; precedence follow list of supported players
declare -a SUPPORTED_PLAYERS=("spotify" "firefox")

# destination for downloaded album art
ART_DIR="$HOME/.cache/album-art"

# downloads the current album art, if not already downlaoded, and returns the
# path to the image
get_album_art() {
 local url
 url="$(playerctl metadata mpris:artUrl 2> /dev/null)"

 # if the command did not exit correctly, do not render the image
 local status=$?
 if [[ $status -ne 0 ]]; then
  echo ""
  return $status
 fi
 
 if [[ "$url" =~ ^http://* || "$url" =~ ^https://* ]]; then
  # if the art url is not local, fetch it
  local art_name="${url##*/}"
  local art_dst="$ART_DIR/$art_name"

  mkdir -p "$ART_DIR"
  wget -O "$art_dst" "$url" &> /dev/null
  echo "$art_dst"
 elif [[ "$url" =~ ^file://* ]]; then
  # if the art url is local, serve that
  echo "${url#file://}"
 else
  # if we don't know how to handle the url, serve nothing
  echo ""
  return -1
 fi
}

# retrieves the name of the song
get_song_name() {
 echo "$(playerctl metadata xesam:title 2> /dev/null)"
}

# retrieves the name of the album
get_album_name() {
 echo "$(playerctl metadata xesam:album 2> /dev/null)"
}

# retrieves the name of the artist
get_artist_name() {
 echo "$(playerctl metadata xesam:artist 2> /dev/null)"
}

# retrieves the completion percentage of the song
get_song_percent() {
 local value
 value="$(playerctl metadata --format "{{ 100 * position / mpris:length }}" 2> /dev/null)"
 local ret=$?
 echo "$value"
 return $ret
}

# check if a player is running
playerctl status > /dev/null 2>&1
PLAYER_RUNNING=$?

# draw album information
if [[ $PLAYER_RUNNING -eq 0 ]]; then
 # don't draw the image line if there is no image information
 IMAGE_LINE=""
 IMAGE_LOCATION="$(get_album_art)"
 if [[ $? -eq 0 ]]; then
  IMAGE_LINE="\${image $IMAGE_LOCATION -p 1101,50 -s 250x250}"
 fi

 # don't draw bar line if there is no progress information
 BAR_LINE=""
 SONG_PERCENT="$(get_song_percent)"
 if [[ $? -eq 0 ]]; then
  BAR_LINE="$(printf "\${voffset 15}\${alignc}\${lua_bar 5,375 passthrough %s}" "$SONG_PERCENT")"
 fi

 # draw album information
 printf "
$IMAGE_LINE

\${voffset 200}

\${voffset 25}\${font KronaOne-Regular:size=20}\${alignc}$(get_song_name)\${font}
\${voffset 10}\${font Quicksand:size=16}\${alignc}$(get_artist_name)\${font}
\${voffset 10}\${font Quicksand:size=14}\${alignc}$(get_album_name)\${font}
$BAR_LINE

" 
fi

# draw date and time
printf "
\${voffset 50}
\${voffset -25}\${color D6D6D6}\${alignc}\${font Anurati:size=50}\${lua conky_getweekday}\${font}\${color}
\${voffset 020}\${color D6D6D6}\${alignc}\${font Quicksand:size=22}\${lua conky_getdate}\${font}\${color}
\${voffset 010}\${color D6D6D6}\${alignc}\${font Quicksand:size=18}\${lua conky_gettime}\${font}\${color}

"
