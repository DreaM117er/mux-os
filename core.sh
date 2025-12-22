#!/bin/bash

BASE_DIR="$HOME/mux-os"
SYSTEM_MOD="$BASE_DIR/system.sh"
APP_MOD="$BASE_DIR/app.sh"
VENDOR_MOD="$BASE_DIR/vendor.sh"
INSTALLER="$BASE_DIR/install.sh"

if [ ! -d "$HOME/storage" ]; then
    echo "⚠️ Initializing Storage Permission..."
    echo " > Please allow file access in the popup window."
    termux-setup-storage
    sleep 2
fi

if ! command -v git &> /dev/null; then
    echo "⚠️ Installing Git..."
    pkg update -y && pkg install git -y
fi

if [ ! -f "$VENDOR_MOD" ]; then
    echo "⚙️ First time setup detected..."
    
    if [ -f "$INSTALLER" ]; then
        echo " > Granting permission to installer..."
        chmod +x "$INSTALLER"
        
        echo " > Running auto-configuration..."
        "$INSTALLER"
    else
        echo "🚫 Error: install.sh not found!"
    fi
fi

if [ -f "$SYSTEM_MOD" ]; then
    source "$SYSTEM_MOD"
else
    echo -e "\033[1;31m🚫 Error: system.sh module missing!\033[0m"
fi

if [ -f "$VENDOR_MOD" ]; then
    source "$VENDOR_MOD"
fi

if [ -f "$APP_MOD" ]; then
    source "$APP_MOD"
else
    echo "# === My Apps ===" > "$APP_MOD"
fi

function _launch_android_app() {
    local app_name="$1"
    local package_name="$2"
    local activity_name="$3"

    echo " > Launching: $app_name ..."
    
    local output
    if [ -n "$activity_name" ]; then
        output=$(am start --user 0 -n "$package_name/$activity_name" 2>&1)
    else
        output=$(am start --user 0 -p "$package_name" 2>&1)
    fi

    if [[ "$output" == *"Error"* ]] || [[ "$output" == *"does not exist"* ]]; then
        echo -e "\033[1;31m❌ Launch Failed: App not found. \033[0m"
        echo -e "    Target: $package_name"
        
        read -p -r " 📥 Install from Google Play? (y/n): " choice
        
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo -e "\033[1;33m 🚀 Redirecting to Store... \033[0m"
            am start -a android.intent.action.VIEW -d "market://details?id=$package_name" >/dev/null 2>&1
        else
            echo -e "🚫 Canceled."
            return 1
        fi
        return 1
    fi
}

function menu() {
    echo -e "\n\033[1;33m" [" Mux-OS Command Center "]"\033[0m"
    
    awk '
    BEGIN {
        COLOR_CAT="\033[1;32m"
        COLOR_FUNC="\033[1;36m"
        RESET="\033[0m"
    }

    /^# ===|^# ---/ {
        clean_header = $0;
        gsub(/^# |^#===|^#---|===|---|^-+|-+$|^\s+|\s+$/, "", clean_header);
        if (length(clean_header) > 0 && clean_header !~ /^[=-]+$/) {
             print "\n" COLOR_CAT " [" clean_header "]" RESET
        }
    }
    
    /^function / {
        match($0, /function ([a-zA-Z0-9_]+)/, arr);
        func_name = arr[1];
        
        if (substr(func_name, 1, 1) != "_") {
            desc = "";
            if (prev_line ~ /^# :/) {
                desc = prev_line;
                gsub(/^# : /, "", desc);
            } else if (prev_line ~ /^# [0-9]+\./) {
                desc = prev_line;
                gsub(/^# [0-9]+\. /, "", desc);
            }

            if (length(desc) > 38) {
                desc = substr(desc, 1, 35) "..";
            }

            if (desc != "") {
                printf "  " COLOR_FUNC "%-12s" RESET " %s\n", func_name, desc;
            }
        }
    }
    { prev_line = $0 }
    ' "$0" "$SYSTEM_MOD" "$APP_MOD" "$VENDOR_MOD"
    
    echo -e "\n"
}


echo "✅ Mux-OS Loaded."
echo " > Input \"apklist\" to search installed Android apps."
echo " > Input \"menu\" to check all available commands."