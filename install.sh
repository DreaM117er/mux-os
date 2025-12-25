#!/bin/bash

BASE_DIR="$HOME/mux-os"
PLUGIN_DIR="$BASE_DIR/plugins"
VENDOR_TARGET="$BASE_DIR/vendor.sh"

echo -e "\033[1;33m :: Starting Mux-OS Installation & Calibration...\033[0m"

PACKAGES=(ncurses-utils fzf git termux-api)

for pkg in "${PACKAGES[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        echo "    ›› Installing missing part: $pkg"
        pkg install "$pkg" -y
    fi
done

echo " :: Granting execution permissions to modules..."
chmod +x "$HOME/mux-os/"*.sh

if [ -f "$HOME/mux-os/core.sh" ]; then
    echo " :: Handing over to Core Engine..."
    source "$HOME/mux-os/core.sh"
else
    echo -e "\033[1;31m :: Critical Error: core.sh not found in $HOME/mux-os/\033[0m"
    exit 1
fi

echo -e "\033[1;33m :: Detecting Device Identity...\033[0m"

BRAND=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]' | xargs)

case "$BRAND" in
    "redmi"|"poco") BRAND="xiaomi" ;;
    "rog"|"asus")   BRAND="asus" ;;
    "samsung")      BRAND="samsung" ;;
esac

echo "    ›› Device Brand Detected: [$BRAND]"

if [ -z "$BRAND" ]; then
    BRAND="unknown"
fi

TARGET_PLUGIN="$PLUGIN_DIR/$BRAND.sh"

if [ -f "$TARGET_PLUGIN" ]; then
    echo "    ›› Found matching ecosystem: $BRAND.sh"
    echo "    ›› Installing $BRAND specific apps..."
    cp "$TARGET_PLUGIN" "$VENDOR_TARGET"
else
    echo "    ›› No specific plugin found for [$BRAND]."
    echo "    ›› Creating a generic empty vendor module."
    
    {
        echo "# vendor.sh - Manufacturer Specific Apps"
        echo "# Device Detected: $BRAND"
        echo "# You can add your device specific apps here."
        echo ""
    } > "$VENDOR_TARGET"
fi

echo -e "\033[1;33m :: Setting permissions for vendor module...\033[0m"
chmod +x "$VENDOR_TARGET"

RC_FILE="$HOME/.bashrc"
LOAD_CMD="source $BASE_DIR/core.sh"

echo -e "\033[1;33m :: Configuring auto-start sequence...\033[0m"

if [ ! -f "$RC_FILE" ]; then
    touch "$RC_FILE"
fi

if grep -Fq "$LOAD_CMD" "$RC_FILE"; then
    echo "    ›› Startup protocol already active."
else
    echo "" >> "$RC_FILE"
    echo "# === Mux-OS Auto-Loader ===" >> "$RC_FILE"
    echo "$LOAD_CMD" >> "$RC_FILE"
    echo "    ›› Injecting startup code into .bashrc... [DONE]"
fi

echo "    ›› Installation Complete. ✅"