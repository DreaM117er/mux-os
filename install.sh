#!/bin/bash

BASE_DIR="$HOME/mux-os"
PLUGIN_DIR="$BASE_DIR/plugins"
VENDOR_TARGET="$BASE_DIR/vendor.sh"

echo " > Detecting Device Identity..."

BRAND=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]' | xargs)

case "$BRAND" in
    "redmi"|"poco") BRAND="xiaomi" ;;
    "rog"|"asus")   BRAND="asus" ;;
esac

echo " > Device Brand Detected: [$BRAND]"

TARGET_PLUGIN="$PLUGIN_DIR/$BRAND.sh"

if [ -z "$BRAND" ]; then
    BRAND="unknown"
fi

if [ -f "$TARGET_PLUGIN" ]; then
    echo " > Found matching ecosystem: $BRAND.sh"
    echo " > Installing $BRAND specific apps..."
    cp "$TARGET_PLUGIN" "$VENDOR_TARGET"
else
    echo " > No specific plugin found for [$BRAND]."
    echo " > Creating a generic empty vendor module."
    
    {
        echo "# vendor.sh - Manufacturer Specific Apps"
        echo "# Device Detected: $BRAND"
        echo "# You can add your device specific apps here."
        echo ""
    } > "$VENDOR_TARGET"
fi

echo " > Setting permissions for vendor module..."
chmod +x "$VENDOR_TARGET"

echo "✅ Configuration Complete."