#!/bin/bash

export MUX_VERSION="1.2.3"
export MUX_ROOT="$HOME/mux-os"

BASE_DIR="$HOME/mux-os"
SYSTEM_MOD="$BASE_DIR/system.sh"
APP_MOD="$BASE_DIR/app.sh"
VENDOR_MOD="$BASE_DIR/vendor.sh"
INSTALLER="$BASE_DIR/install.sh"

if [ ! -d "$HOME/storage" ]; then
    echo " > Initializing Storage Permission..."
    echo " > Please allow file access in the popup window."
    termux-setup-storage
    sleep 2
fi

if ! command -v git &> /dev/null; then
    echo " > Installing Git..."
    pkg update -y && pkg install git -y
fi

if [ ! -f "$VENDOR_MOD" ]; then
    echo " > First time setup detected..."
    
    if [ -f "$INSTALLER" ]; then
        echo " > Granting permission to installer..."
        chmod +x "$INSTALLER"
        
        echo " > Running auto-configuration..."
        "$INSTALLER"
    else
        echo "❌ Error: install.sh not found!"
    fi
fi

if [ -f "$SYSTEM_MOD" ]; then
    source "$SYSTEM_MOD"
else
    echo -e "\033[1;31m❌ Error: system.sh module missing!\033[0m"
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
        _bot_say "error" "Launch Failed: Target package not found."
        echo -e "    Target: $package_name"
        
        read -p "📥 Install from Google Play? (y/n): " choice
        
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            _bot_say "loading" "Redirecting to Store..."
            am start -a android.intent.action.VIEW -d "market://details?id=$package_name" >/dev/null 2>&1
        else
            echo -e "❌ Canceled."
            return 1
        fi
        return 1
    fi
}

function _require_no_args() {
    if [ -n "$1" ]; then
        _bot_say "no_args" "Unexpected input: $*"
        return 1
    fi
    return 0
}

function _bot_say() {
    local mood="$1"
    local detail="$2"
    
    local C_RESET="\033[0m"
    local C_CYAN="\033[1;36m"
    local C_GREEN="\033[1;32m"
    local C_RED="\033[1;31m"
    local C_YELLOW="\033[1;33m"
    local C_GRAY="\033[1;30m"

    local icon=""
    local color=""
    local phrases=()

    case "$mood" in
        "hello")
            icon="🤖"
            color=$C_CYAN
            phrases=(
                "Mux-OS online. Awaiting input."
                "Systems nominal. Ready when you are."
                "Greetings, Commander."
                "Core logic initialized."
                "At your service."
                "Digital horizon secure. What's next?"
                "I am ready to serve."
            )
            ;;
            
        "success")
            icon="✅"
            color=$C_GREEN
            phrases=(
                "Execution perfect."
                "As you commanded."
                "Consider it done."
                "Operation successful."
                "That was easy."
                "I have arranged the bits as requested."
                "Smooth as silk."
            )
            ;;
            
        "error")
            icon="🚫"
            color=$C_RED
            phrases=(
                "I'm afraid I can't do that."
                "Mission failed successfully."
                "Computer says no."
                "That... didn't go as planned."
                "Protocol mismatch. Try again."
                "My logic circuits refuse this request."
                "User error... presumably."
            )
            ;;
            
        "no_args")
            icon="🛡️ "
            color=$C_YELLOW
            phrases=(
                "I need less talking, more action. (No args please)"
                "That command stands alone."
                "Don't complicate things."
                "Arguments are irrelevant here."
                "Just the command, nothing else."
            )
            ;;
            
        "loading")
            icon="⏳"
            color=$C_GRAY
            phrases=(
                "Processing..."
                "Entropy increasing..."
                "Calculating probabilities..."
                "Hold your horses..."
                "Compiling reality..."
            )
            ;;
    esac

    local rand_index=$(( RANDOM % ${#phrases[@]} ))
    local selected_phrase="${phrases[$rand_index]}"

    echo -e "${color}${icon} ${selected_phrase}${C_RESET}"
    
    if [ -n "$detail" ]; then
        echo -e "   ${C_GRAY}> ${detail}${C_RESET}"
    fi
}

function mux() {
    local cmd="$1"
    if [ -z "$cmd" ]; then
        _bot_say "hello"
        return
    fi

    case "$cmd" in
        "menu"|"m")
            _show_menu_dashboard
            ;;
            
        "version"|"v")
            echo -e "🤖 \033[1;33mMux-OS Core v$MUX_VERSION\033[0m"
            ;;
            
        "update"|"up")
            _mux_update_system
            ;;
            
        "help"|"h")
            echo "Available commands:"
            echo "  mux           : Acknowledge presence"
            echo "  mux menu      : Show command dashboard"
            echo "  mux version   : Show current version"
            echo "  mux update    : Check for updates"
            echo "  mux reload    : Reload system modules"
            ;;

        "reload"|"r")
            _mux_reload_kernel
            ;;
        *)
            echo "Unknown command: $cmd"
            echo "Try 'mux help'"
            ;;
    esac
}

function _show_menu_dashboard() {
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

function menu() {
    mux menu
}

function _mux_reload_kernel() {
    echo -e "\033[1;33m > System Reload Initiated...\033[0m"
    
    if [ -f "$INSTALLER" ]; then
        echo " > Re-calibrating vendor ecosystem..."
        chmod +x "$INSTALLER"
        "$INSTALLER"
    else
        echo "❌ Installer module not found. Skipping vendor config."
    fi
    
    echo " > Reloading Kernel..."
    source "$BASE_DIR/core.sh"
}

function _mux_update_system() {
    echo " > Checking for updates..."
    cd "$BASE_DIR" || return

    git fetch origin
    
    local LOCAL=$(git rev-parse HEAD)
    local REMOTE=$(git rev-parse @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "✅ System is up-to-date (v$MUX_VERSION)."
    else
        echo " > New version available!"
        read -p "📥 Update Mux-OS now? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo " > Updating..."
            git pull
            
            _bot_say "success" "Update complete. Reloading kernel..."
            _mux_reload_kernel
        else
            echo " > Update cancelled."
        fi
    fi
}


echo "✅ Mux-OS Loaded."
mux version
echo " > Input \"apklist\" to search installed Android apps."
echo " > Input \"menu\" to check all available commands."
