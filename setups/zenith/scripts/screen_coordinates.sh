#!/bin/bash

# ensure that all required dependencies are installed
ensure_dependencies_installed() {
 declare -a cmds=("xrandr" "perl") 
 for cmd in "${cmds[@]}"; do
  if ! command -v $cmd &> /dev/null; then
   printf '%s is required to run this script!\n' "$cmd"
  fi
 done
}

ensure_dependencies_installed
xrandr | perl -e '$str = do { local $/; <> }; while ($str =~ /(\b\d+x\d+\+\d+\+\d+\b)/sg) { print "$1\n" }'
