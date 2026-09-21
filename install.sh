#!/bin/bash

# Pixie Lockscreen - Universal Smart Installer
# Author: xCaptaiN09 (adapted for Lockscreen by Marlon554)

set -e

THEME_NAME="pixie"
LOCKSCREEN_DIR="/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen"
BACKUP_DIR="${LOCKSCREEN_DIR}.bak"
PIXIE_SDDM_DIR="/usr/share/sddm/themes/${THEME_NAME}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==>${NC} Starting KPixie Lockscreen Installation..."

# 1. ROOT CHECK
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error:${NC} Please run as root (use sudo)."
    exit 1
fi

# 2. KDE PLASMA CHECK
if [ ! -d "/usr/share/plasma/shells/org.kde.plasma.desktop" ]; then
    echo -e "${RED}Error:${NC} KDE Plasma not detected. Lockscreen only works on Plasma Desktop."
    exit 1
fi

# 3. BACKUP EXISTING LOCKSCREEN
if [ -d "${LOCKSCREEN_DIR}" ]; then
    echo -e "${BLUE}==>${NC} Backing up existing lockscreen to ${BACKUP_DIR}..."
    mv "${LOCKSCREEN_DIR}" "${BACKUP_DIR}"
fi

# 4. CREATE NEW LOCKSCREEN DIRECTORY
echo -e "${BLUE}==>${NC} Creating new lockscreen directory..."
mkdir -p "${LOCKSCREEN_DIR}"

# 5. COPY REQUIRED FILES FROM PIXIE SOURCE
echo -e "${BLUE}==>${NC} Copying KPixie assets and components..."

# Copy assets and components directories
cp -r assets "${LOCKSCREEN_DIR}/"
cp -r components "${LOCKSCREEN_DIR}/"

# Copy specific QML and config files
cp config.qml "${LOCKSCREEN_DIR}/"
cp config.xml "${LOCKSCREEN_DIR}/"
cp LockOsd.qml "${LOCKSCREEN_DIR}/"
cp LockScreen.qml "${LOCKSCREEN_DIR}/"
cp LockScreenUi.qml "${LOCKSCREEN_DIR}/"
cp MainBlock.qml "${LOCKSCREEN_DIR}/"
cp NoPasswordUnlock.qml "${LOCKSCREEN_DIR}/"
cp PixieAccentExtractor.qml "${LOCKSCREEN_DIR}"

# Set proper permissions
chmod -R 755 "${LOCKSCREEN_DIR}"

echo -e "${GREEN}Done!${NC} KPixie is now installed."

# 6. WALLPAPER PROMPT (Pixie SDDM Integration)
echo -e ""
if [ -d "${PIXIE_SDDM_DIR}" ]; then
    echo -e "${YELLOW}Pixie SDDM detected!${NC}"
    read -p "Apply Pixie SDDM wallpaper to lockscreen? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}==>${NC} Copying wallpaper from Pixie SDDM..."
        # Copy wallpaper/assets from SDDM theme (adjust paths as needed)
        if [ -d "${PIXIE_SDDM_DIR}/assets/wallpapers" ]; then
            cp -r "${PIXIE_SDDM_DIR}/assets/wallpapers" "${LOCKSCREEN_DIR}/assets/"
        elif [ -f "${PIXIE_SDDM_DIR}/assets/wallpaper.jpg" ]; then
            cp "${PIXIE_SDDM_DIR}/assets/wallpaper.jpg" "${LOCKSCREEN_DIR}/assets/"
        fi
        echo -e "${GREEN}Wallpaper applied successfully!${NC}"
    fi
else
    echo -e "${YELLOW}Pixie SDDM not found.${NC} Skipping wallpaper integration."
fi

echo -e ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "${BLUE}ℹ️  ${NC}Use your distribution's greeter test to see how it looks."
cat << 'EOF'
  • Arch Linux:
    /usr/lib/kscreenlocker_greet --testing

  • Fedora:
    /usr/lib64/kscreenlocker_greet --testing

  • Debian / Ubuntu:
    /usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet --testing
EOF
echo ""
echo -e "${BLUE}ℹ️  ${NC}To revert: sudo mv ${BACKUP_DIR} ${LOCKSCREEN_DIR}"
