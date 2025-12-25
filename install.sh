#!/bin/bash

BASE_DIR="$HOME/mux-os"
PLUGIN_DIR="$BASE_DIR/plugins"
VENDOR_TARGET="$BASE_DIR/vendor.sh"

echo -e "\033[1;33m :: Starting Mux-OS Installation & Calibration...\033[0m"

# 1. 環境依賴檢查
PACKAGES=(ncurses-utils fzf git termux-api)
for pkg in "${PACKAGES[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        echo "    ›› Installing missing part: $pkg"
        pkg install "$pkg" -y
    fi
done

# 2. 設備身分識別 (移動到啟動前)
echo -e "\033[1;33m :: Detecting Device Identity...\033[0m"
BRAND=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]' | xargs)
case "$BRAND" in
    "redmi"|"poco") BRAND="xiaomi" ;;
    "rog"|"asus")   BRAND="asus" ;;
    "samsung")      BRAND="samsung" ;;
    *)              BRAND="${BRAND:-unknown}" ;;
esac

# 3. 配置生產廠家模組 (Vendor)
TARGET_PLUGIN="$PLUGIN_DIR/$BRAND.sh"
if [ -f "$TARGET_PLUGIN" ]; then
    cp "$TARGET_PLUGIN" "$VENDOR_TARGET"
else
    echo "# vendor.sh - Generic" > "$VENDOR_TARGET"
fi
chmod +x "$VENDOR_TARGET"

# 4. 寫入開機引導 (.bashrc)
RC_FILE="$HOME/.bashrc"
LOAD_CMD="source $BASE_DIR/core.sh"
if ! grep -Fq "$LOAD_CMD" "$RC_FILE"; then
    echo -e "\n# === Mux-OS Auto-Loader ===\n$LOAD_CMD" >> "$RC_FILE"
fi

# 5. 最後交接：所有權限賦予
chmod +x "$BASE_DIR/"*.sh
echo " :: All systems calibrated. Re-engaging Terminal..."
sleep 1
exec bash
