#!/bin/bash
# wallpaper.sh - mpvpaper + pywal sync via ffmpeg best-frame extraction
# Usage: ./wallpaper.sh '/path/to/video.mp4' [display] [widthxheight]
# Example: ./wallpaper.sh '/path/to/video.mp4' eDP-1 1920x1080
#          ./wallpaper.sh '/path/to/video.mp4' HDMI-A-1 1400x900

if [ -z "$1" ]; then
  echo "Usage: wallpaper.sh <video path> [display] [widthxheight]"
  echo "Example: wallpaper.sh video.mp4 eDP-1 1920x1080"
  exit 1
fi

VIDEO="$1"
DISPLAY_OUTPUT="${2:-eDP-1}"
RESOLUTION="${3:-1920x1080}"
WIDTH="${RESOLUTION%x*}"
HEIGHT="${RESOLUTION#*x}"

FRAME="$HOME/.cache/wallpaper-frame.png"
FRAME_DIR="$HOME/.cache/wallpaper-frames"
SOCKET="/tmp/mpvsocket"

sync_wal() {
  rm -rf ~/.cache/wal 2>/dev/null

  mkdir -p "$FRAME_DIR"
  rm -f "$FRAME_DIR"/*.png 2>/dev/null

  DURATION=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$VIDEO" 2>/dev/null | cut -d. -f1)

  echo "→ Extracting frames from: $(basename "$VIDEO") (${WIDTH}x${HEIGHT} on $DISPLAY_OUTPUT)"

  STEP=$((DURATION / 10))
  for i in $(seq 1 10); do
    TIMESTAMP=$((i * STEP))
    ffmpeg -ss "$TIMESTAMP" -i "$VIDEO" -vf scale=${WIDTH}:${HEIGHT} -frames:v 1 \
      "$FRAME_DIR/frame_$(printf '%02d' $i).png" -y -loglevel quiet
  done

  BEST_FRAME=""
  BEST_SCORE=0
  for f in "$FRAME_DIR"/*.png; do
    SCORE=$(convert "$f" -colorspace HSL -channel Saturation \
      -separate -format "%[fx:standard_deviation]" info: 2>/dev/null)
    IS_BETTER=$(awk -v s="$SCORE" -v b="$BEST_SCORE" 'BEGIN { print (s > b) }')
    if [ "$IS_BETTER" = "1" ]; then
      BEST_SCORE="$SCORE"
      BEST_FRAME="$f"
    fi
  done

  if [ -z "$BEST_FRAME" ]; then
    echo "⚠ Frame scoring failed, falling back to 5s"
    ffmpeg -ss 5 -i "$VIDEO" -vf scale=${WIDTH}:${HEIGHT} -frames:v 1 "$FRAME" -y -loglevel quiet
  else
    echo "✓ Best frame: $(basename $BEST_FRAME) (saturation: $BEST_SCORE)"
    cp "$BEST_FRAME" "$FRAME"
  fi

  echo "→ Running pywal..."
  wal -i "$FRAME" -n --backend colorthief
  WAL_EXIT=$?

  if [ $WAL_EXIT -ne 0 ]; then
    echo "✗ pywal failed — trying default backend..."
    wal -i "$FRAME" -n
  fi

  if [ ! -f ~/.cache/wal/colors-waybar.css ]; then
    echo "✗ colors-waybar.css missing — pywal did not generate files"
    return 1
  fi

  # Update rofi preview with the best frame
  cp "$FRAME" ~/.cache/wal/current-wallpaper

  echo "✓ New color scheme:"
  cat ~/.cache/wal/colors-waybar.css

  pkill -SIGUSR2 waybar && echo "✓ Waybar reloaded" || echo "⚠ Waybar not running"

  kitty @ --to unix:/tmp/mykitty set-colors -a -c ~/.cache/wal/colors-kitty.conf 2>/dev/null &&
    echo "✓ Kitty reloaded" || echo "⚠ Kitty remote control not available"
}

pkill -x mpvpaper 2>/dev/null
sleep 0.5

mpvpaper -o "hwdec=auto profile=fast --keepaspect=no loop no-audio input-ipc-server=$SOCKET" \
  ALL "$VIDEO" &

sleep 2

sync_wal
