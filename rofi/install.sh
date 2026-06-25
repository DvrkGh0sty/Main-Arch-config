#!/bin/bash

# Installation script for Rofi Theme Switcher

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Rofi Theme Switcher Installer${NC}"
echo -e "${GREEN}================================${NC}\n"

# Function to print colored messages
print_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
  print_error "Please do not run this script as root"
  exit 1
fi

# Detect distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO=$ID
else
  print_error "Cannot detect distribution"
  exit 1
fi

# Check dependencies
check_dependencies() {
  print_info "Checking dependencies..."

  local missing=()

  command -v rofi >/dev/null 2>&1 || missing+=("rofi")
  command -v swww >/dev/null 2>&1 || missing+=("swww")
  command -v wal >/dev/null 2>&1 || missing+=("pywal")
  command -v convert >/dev/null 2>&1 || missing+=("imagemagick")

  if [ ${#missing[@]} -gt 0 ]; then
    print_warning "Missing dependencies: ${missing[*]}"
    echo ""
    echo "Install instructions:"
    echo ""

    case $DISTRO in
    arch | manjaro | endeavouros)
      echo "  sudo pacman -S rofi imagemagick"
      echo "  yay -S swww" # or paru -S swww
      echo "  pip install pywal"
      ;;
    ubuntu | debian | pop | linuxmint)
      echo "  sudo apt install rofi imagemagick python3-pip"
      echo "  pip3 install pywal"
      echo "  # Install swww from: https://github.com/LGFae/swww"
      ;;
    fedora)
      echo "  sudo dnf install rofi ImageMagick python3-pip"
      echo "  pip3 install pywal"
      echo "  # Install swww from: https://github.com/LGFae/swww"
      ;;
    *)
      echo "  Please install: rofi, swww, pywal, imagemagick"
      ;;
    esac

    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  else
    print_info "All dependencies found!"
  fi
}

# Create necessary directories
create_directories() {
  print_info "Creating directories..."

  mkdir -p ~/Pictures/Wallpapers
  mkdir -p ~/.config/rofi
  mkdir -p ~/.cache/rofi-theme-switcher/thumbnails
  mkdir -p ~/.local/bin

  print_info "Directories created"
}

# Install script
install_script() {
  print_info "Installing theme switcher script..."

  if [ -f "./rofi-theme-switcher.sh" ]; then
    cp rofi-theme-switcher.sh ~/.local/bin/rofi-theme-switcher
    chmod +x ~/.local/bin/rofi-theme-switcher
    print_info "Script installed to ~/.local/bin/rofi-theme-switcher"
  else
    print_error "rofi-theme-switcher.sh not found in current directory"
    exit 1
  fi
}

# Install rofi theme
install_theme() {
  print_info "Installing rofi theme..."

  if [ -f "./rofi-theme-switcher.rasi" ]; then
    cp rofi-theme-switcher.rasi ~/.config/rofi/
    print_info "Theme installed to ~/.config/rofi/"
  else
    print_warning "rofi-theme-switcher.rasi not found, skipping"
  fi
}

# Check PATH
check_path() {
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    print_warning "~/.local/bin is not in your PATH"
    echo ""
    echo "Add the following to your shell rc file (~/.bashrc or ~/.zshrc):"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
  fi
}

# Create example wallpapers directory structure
create_example_structure() {
  print_info "Creating example directory structure..."

  cat >~/Pictures/Wallpapers/README.txt <<'EOF'
Place your wallpapers in this directory.

Supported formats:
- JPG/JPEG
- PNG
- WEBP

You can organize wallpapers in subdirectories if you want.

To run the theme switcher:
    rofi-theme-switcher

Or set a custom wallpaper directory:
    WALLPAPER_DIR=/path/to/wallpapers rofi-theme-switcher
EOF

  print_info "Created README in ~/Pictures/Wallpapers/"
}

# Create startup script example
create_startup_example() {
  print_info "Creating startup script example..."

  mkdir -p ~/.config/scripts

  cat >~/.config/scripts/restore-wallpaper.sh <<'EOF'
#!/bin/bash

# Restore last selected wallpaper on startup

CACHE_FILE="$HOME/.cache/rofi-theme-switcher/current_wallpaper"

if [ -f "$CACHE_FILE" ]; then
    WALLPAPER=$(cat "$CACHE_FILE")
    
    # Start swww daemon if not running
    if ! pgrep -x swww-daemon >/dev/null; then
        swww-daemon &
        sleep 1
    fi
    
    # Set wallpaper
    swww img "$WALLPAPER" --transition-type fade
    
    # Apply pywal colors
    wal -i "$WALLPAPER" -n -q
fi
EOF

  chmod +x ~/.config/scripts/restore-wallpaper.sh

  print_info "Startup script created at ~/.config/scripts/restore-wallpaper.sh"
  echo ""
  echo "To auto-restore wallpaper on login, add this to your WM config:"
  echo "  ~/.config/scripts/restore-wallpaper.sh"
}

# Main installation
main() {
  check_dependencies
  create_directories
  install_script
  install_theme
  check_path
  create_example_structure
  create_startup_example

  echo ""
  print_info "${GREEN}Installation complete!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Add wallpapers to ~/Pictures/Wallpapers/"
  echo "  2. Run: rofi-theme-switcher"
  echo "  3. (Optional) Add to your WM config for a keybind"
  echo ""
  echo "Example keybind for i3/sway:"
  echo "  bindsym \$mod+w exec rofi-theme-switcher"
  echo ""
  echo "For Hyprland:"
  echo "  bind = SUPER, W, exec, rofi-theme-switcher"
  echo ""
}

# Run main installation
main
