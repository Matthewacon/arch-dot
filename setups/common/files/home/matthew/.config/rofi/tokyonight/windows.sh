#!/bin/bash

SCRIPT_DIR=$(dirname "$0") && [[ "$SCRIPT_DIR" == "." ]] && SCRIPT_DIR="$(pwd)"

rofi -config "$SCRIPT_DIR/tokyonight-config.rasi" -show window 
