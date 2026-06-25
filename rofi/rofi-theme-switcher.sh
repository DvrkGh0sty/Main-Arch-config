#!/bin/bash
# Rofi Theme Switcher with swww and pywal
# This script displays wallpapers in a rofi menu and applies them with swww + pywal
# Configuration
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CACHE_DIR="$HOME/.cache/rofi-theme-switcher"
THUMBNAIL_SIZE="200x200"
BLUR_STRENGTH="0x20" # Adjust for more/less blur (e.g. 0x8 = subtle, 0x30 = heavy)
# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR/thumbnails"
# Check dependencies
check_dependencies() {
  local missing=()
  command -v rofi >/dev/null 2>&1 || missing+=("rofi")
  command -v swww >/dev/null 2>&1 || missing+=("swww")
  command -v wal >/dev/null 2>&1 || missing+=("pywal")
  command -v convert >/dev/null 2>&1 || missing+=("imagemagick")
  if [ ${#missing[@]} -gt 0 ]; then
    echo "Error: Missing dependencies: ${missing[*]}"
    echo "Please install them first."
    exit 1
  fi
}
# Initialize swww daemon if not running
init_swww() {
  if ! pgrep -x swww-daemon >/dev/null; then
    echo "Starting swww daemon..."
    swww-daemon &
    sleep 1
  fi
}
# Generate thumbnail for wallpaper
generate_thumbnail() {
  local wallpaper="$1"
  local filename=$(basename "$wallpaper")
  local thumbnail="$CACHE_DIR/thumbnails/${filename%.*}.png"
  if [ ! -f "$thumbnail" ]; then
    convert "$wallpaper[0]" -resize "$THUMBNAIL_SIZE" "$thumbnail" 2>/dev/null
    # Fallback: if thumbnail creation failed, use original image
    if [ ! -f "$thumbnail" ]; then
      echo "$wallpaper"
      return
    fi
  fi
  echo "$thumbnail"
}
# Get list of wallpapers
get_wallpapers() {
  if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: Wallpaper directory not found: $WALLPAPER_DIR"
    echo "Please create it and add some wallpapers, or set WALLPAPER_DIR environment variable."
    exit 1
  fi
  find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) | sort
}
# Generate blurred rofi sidebar preview from wallpaper
generate_blurred_preview() {
  local wallpaper="$1"
  # Crop portrait slice from center, then apply gaussian blur
  convert "$wallpaper" \
    -gravity Center \
    -crop 600x1080+0+200 \
    +repage \
    -blur "$BLUR_STRENGTH" \
    ~/.cache/wal/rofi-preview.jpg
}
# Apply wallpaper and colorscheme
apply_theme() {
  local wallpaper="$1"
  if [ -z "$wallpaper" ]; then
    echo "No wallpaper selected"
    exit 0
  fi
  echo "Applying wallpaper: $wallpaper"
  # Set wallpaper with swww
  swww img "$wallpaper" \
    --transition-type wipe \
    --transition-duration 2 \
    --transition-fps 60 \
    --transition-angle 30
  # Generate and apply pywal colorscheme
  echo "Generating colorscheme with pywal..."
  wal -i "$wallpaper" -n
  # Update symlink for rofi background-image
  ln -sf "$wallpaper" ~/.cache/wal/current-wallpaper
  # Generate blurred sidebar preview for rofi
  echo "Generating blurred rofi preview..."
  generate_blurred_preview "$wallpaper"
  # Optional: Reload other applications
  # Reload waybar
  killall -SIGUSR2 waybar 2>/dev/null
  # Reload kitty terminal colors
  # killall -SIGUSR1 kitty 2>/dev/null
  # Reload dunst notification daemon
  # killall dunst 2>/dev/null; dunst &
  # Reload polybar
  # ~/.config/polybar/launch.sh 2>/dev/null &
  # Reload i3/sway
  # i3-msg reload 2>/dev/null
  # swaymsg reload 2>/dev/null
  echo "Theme applied successfully!"
  # Save current wallpaper path
  echo "$wallpaper" >"$CACHE_DIR/current_wallpaper"
}
# Create rofi menu with wallpaper previews
show_menu() {
  local wallpapers=()
  local wallpaper_paths=()
  local preview_file="$CACHE_DIR/preview.txt"
  echo "Scanning wallpapers..."
  >"$preview_file"
  while IFS= read -r wallpaper; do
    local basename=$(basename "$wallpaper")
    local name="${basename%.*}"
    local thumbnail=$(generate_thumbnail "$wallpaper")
    if [ -f "$thumbnail" ]; then
      wallpapers+=("$name")
      wallpaper_paths+=("$wallpaper")
      echo -e "$name\x00icon\x1f$thumbnail" >>"$preview_file"
    else
      echo "Warning: Failed to generate thumbnail for $basename" >&2
    fi
  done < <(get_wallpapers)
  if [ ${#wallpapers[@]} -eq 0 ]; then
    rofi -e "No wallpapers found in $WALLPAPER_DIR"
    exit 0
  fi
  # Show rofi menu with thumbnails
  local selected=$(cat "$preview_file" | rofi -dmenu \
    -i \
    -p "Select Wallpaper" \
    -theme ~/.config/rofi/rofi-theme-switcher.rasi \
    -show-icons \
    -format 's' \
    -no-custom)
  # Find and apply selected wallpaper
  if [ -n "$selected" ]; then
    for i in "${!wallpapers[@]}"; do
      if [ "${wallpapers[$i]}" = "$selected" ]; then
        apply_theme "${wallpaper_paths[$i]}"
        break
      fi
    done
  fi
}
# Main function
main() {
  check_dependencies
  init_swww
  # Ensure blurred preview exists on first run
  if [ ! -f ~/.cache/wal/rofi-preview.jpg ] && [ -f ~/.cache/wal/current-wallpaper ]; then
    echo "Generating initial blurred preview..."
    generate_blurred_preview "$(readlink -f ~/.cache/wal/current-wallpaper)"
  fi
  show_menu
}
# Run main function
main
