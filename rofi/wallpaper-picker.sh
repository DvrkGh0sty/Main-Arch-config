#!/bin/bash
# wallpaper-picker.sh - rofi video wallpaper picker with thumbnail previews
# Depends on: rofi, ffmpeg, wallpaper.sh

WALLPAPER_DIR="$HOME/Pictures/Live Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper-thumbs"
WALLPAPER_SCRIPT="$HOME/.config/rofi/wall.sh"
ROFI_THEME="$HOME/.config/rofi/wallpaper-picker.rasi"

mkdir -p "$THUMB_DIR"

# --- Generate thumbnails for all videos ---
generate_thumbs() {
  for video in "$WALLPAPER_DIR"/*.mp4 "$WALLPAPER_DIR"/*.webm "$WALLPAPER_DIR"/*.mkv; do
    [ -f "$video" ] || continue
    name=$(basename "$video")
    thumb="$THUMB_DIR/${name%.*}.png"
    if [ ! -f "$thumb" ] || [ "$video" -nt "$thumb" ]; then
      echo "Generating thumbnail: $name"
      ffmpeg -ss 5 -i "$video" -vf scale=400:225 -frames:v 1 "$thumb" -y -loglevel quiet
    fi
  done
}

# --- Build rofi menu and launch picker ---
run_picker() {
  generate_thumbs

  ENTRIES=""
  for video in "$WALLPAPER_DIR"/*.mp4 "$WALLPAPER_DIR"/*.webm "$WALLPAPER_DIR"/*.mkv; do
    [ -f "$video" ] || continue
    name=$(basename "$video")
    label="${name%.*}"
    thumb="$THUMB_DIR/${name%.*}.png"
    [ -f "$thumb" ] || continue
    ENTRIES+="$label\0icon\x1f$thumb\n"
  done

  CHOSEN=$(echo -e "$ENTRIES" | rofi \
    -dmenu \
    -p "Wallpaper" \
    -show-icons \
    -theme "$ROFI_THEME")

  [ -z "$CHOSEN" ] && exit 0

  for video in "$WALLPAPER_DIR"/*.mp4 "$WALLPAPER_DIR"/*.webm "$WALLPAPER_DIR"/*.mkv; do
    [ -f "$video" ] || continue
    name=$(basename "$video")
    label="${name%.*}"
    if [ "$label" = "$CHOSEN" ]; then
      bash "$WALLPAPER_SCRIPT" "$video"
      exit 0
    fi
  done
}

run_picker
