#!/bin/bash

export MUX_VERSION="1.8.8"
export MUX_ROOT="$HOME/mux-os"
export BASE_DIR="$HOME/mux-os"
export MUX_REPO="https://github.com/DreaM117er/mux-os"

SYSTEM_MOD="$BASE_DIR/system.sh"
APP_MOD="$BASE_DIR/app.sh"
VENDOR_MOD="$BASE_DIR/vendor.sh"
INSTALLER="$BASE_DIR/install.sh"

[ -f "$BASE_DIR/ui.sh" ] && source "$BASE_DIR/ui.sh"
[ -f "$SYSTEM_MOD" ] && source "$SYSTEM_MOD" || echo -e "\033[1;31m❌ Error: system.sh missing!\033[0m"
[ -f "$VENDOR_MOD" ] && source "$VENDOR_MOD"
[ -f "$APP_MOD" ] && source "$APP_MOD" || echo "# === My Apps ===" > "$APP_MOD"

function _system_check() {
    if [ ! -d "$HOME/storage" ]; then
        echo " > Initializing Storage Permission..."
        termux-setup-storage
        sleep 2
    fi

    if ! command -v git &> /dev/null; then
        echo " > Installing Git..."
        pkg update -y && pkg install git -y
    fi
    
    if [ ! -f "$VENDOR_MOD" ]; then
        if [ -f "$INSTALLER" ]; then
            chmod +x "$INSTALLER"
            "$INSTALLER"
        fi
    fi
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
                " Mux-OS online. Awaiting input."
                " Systems nominal. Ready when you are."
                " Greetings, Commander."
                " Core logic initialized."
                " At your service."
                " Digital horizon secure. What's next?"
                " I am ready to serve."
                " Yo, Commander. Systems ready."
                " Mux-OS awake. Coffee time?"
                " What are we building today?"
                " System green. Vibes good."
                " Back online. Let's rock."
                " I was sleeping... but okay, I'm up."
            )
            ;;
        "success")
            icon="✅"
            color=$C_GREEN
            phrases=(
                " Execution perfect."
                " As you commanded."
                " Consider it done."
                " Operation successful."
                " That was easy."
                " I have arranged the bits as requested."
                " Smooth as silk."
                " Boom. Done."
                " Too easy."
                " Nailed it."
                " Smooth."
                " I'm actually a genius."
                " Sorted."
                " Consider it handled."
            )
            ;;
        "neural")
            icon="🌐"
            color=$C_CYAN
            phrases=(
                " Establishing Neural Link..."       
                " Injecting query into Datasphere..."
                " Handshaking with the Grid..."
                " Accessing Global Network..."
                " Broadcasting intent..."
                " Opening digital gateway..."
                " Uplink established."
            )
            ;;
        "error")
            icon="🚫"
            color=$C_RED
            phrases=(
                " I'm afraid I can't do that."
                " Mission failed successfully."
                " Computer says no."
                " That... didn't go as planned."
                " Protocol mismatch. Try again."
                " My logic circuits refuse this request."
                " User error... presumably."
                " Yeah... that's a negative."
                " Oof. That didn't work."
                " I refuse to do that."
                " You typed that wrong, didn't you?"
                " 404: Motivation not found."
                " Mission failed... awkwardly."
                " Computer says no."
            )
            ;;
        "no_args")
            icon="⚠️"
            color=$C_YELLOW
            phrases=(
                " I need less talking, more action. (No args please)"
                " That command stands alone."
                " Don't complicate things."
                " Arguments are irrelevant here."
                " Just the command, nothing else."
                " Whoa, too many words."
                " Just the command, chief."
                " I don't need arguments for this."
                " Solo command only."
                " Don't complicate things."
                " Chill with the parameters."
            )
            ;;
        "loading")
            icon="⏳"
            color=$C_GRAY
            phrases=(
                " Processing..."
                " Entropy increasing..."
                " Calculating probabilities..."
                " Hold your horses..."
                " Compiling reality..."
                " Hold up..."
                " Gimme a sec..."
                " Doing the magic..."
                " Processing... maybe."
                " One moment..."
            )
            ;;
        "launch")
            icon="🚀"
            color=$C_CYAN
            phrases=(
                " Spinning up module..."
                " Injecting payload..."
                " Materializing interface..."
                " Accessing neural partition..."
                " Construct loading..."
                " Summoning application..."
                " Executing launch sequence..."
            )
            ;;
        "system")
            icon="⚡"
            color=$C_YELLOW
            phrases=(
                " Interfacing with Host Core..."
                " Modulating system parameters..." 
                " Establishing neural link..."
                " Overriding droid protocols..."
                " Syncing with hardware layer..."
                " Requesting host compliance..."
                " Accessing control matrix..."
            )
            ;;
        *)
            icon="💬"
            color=$C_CYAN
            phrases=(" Processing: $detail" " I hear you." " Input received.")
            ;;
    esac

    local rand_index=$(( RANDOM % ${#phrases[@]} ))
    local selected_phrase="${phrases[$rand_index]}"

    echo -e "${color}${icon}${selected_phrase}${C_RESET}"
    if [ -n "$detail" ]; then
        echo -e "   ${C_GRAY}> ${detail}${C_RESET}"
    fi
}

function _launch_android_app() {
    local app_name="$1"
    local package_name="$2"
    local activity_name="$3"

    _bot_say "launch" "Target: [$app_name]"
    local output

    if [ -n "$activity_name" ]; then
        output=$(am start --user 0 -n "$package_name/$activity_name" 2>&1)
    else
        output=$(am start --user 0 -p "$package_name" 2>&1)
    fi

    if [[ "$output" == *"Error"* ]] || [[ "$output" == *"does not exist"* ]]; then
        _bot_say "error" "Launch Failed: Target package not found."
        echo -e "    Target: $package_name"

        echo -ne "\033[1;36m📥 Install from Google Play? (y/n): \033[0m"
        read choice
        
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


function mux() {
    local cmd="$1"
    if [ -z "$cmd" ]; then
        _bot_say "hello"
        return
    fi

    case "$cmd" in
        "menu"|"m")
            _mux_fuzzy_menu
            ;;
        "info"|"i")
            _mux_show_info
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
            echo "  mux reset     : Force sync (Discard changes)"
            echo "  mux info      : Show system information"
            ;;
        "reload"|"r")
            _mux_reload_kernel
            ;;
        "reset")
            _mux_force_reset
            ;;
        *)
            echo "Unknown command: $cmd"
            echo "Try 'mux help'"
            ;;
    esac
}



function _mux_show_info() {
    clear
    _draw_logo
    
    local C_CYAN="\033[1;36m"
    local C_WHITE="\033[1;37m"
    local C_GRAY="\033[1;30m"
    local C_RESET="\033[0m"
    local C_GREEN="\033[1;32m"

    echo -e " ${C_CYAN}:: SYSTEM MANIFEST ::${C_RESET}"
    echo ""
    echo -e "  ${C_GRAY}PROJECT    :${C_RESET} ${C_WHITE}Mux-OS (Terminal Environment)${C_RESET}"
    echo -e "  ${C_GRAY}VERSION    :${C_RESET} ${C_GREEN}v$MUX_VERSION${C_RESET}"
    echo -e "  ${C_GRAY}CODENAME   :${C_RESET} ${C_CYAN}Neural Link${C_RESET}"
    echo -e "  ${C_GRAY}ARCHITECT  :${C_RESET} ${C_WHITE}Commander${C_RESET}" 
    echo -e "  ${C_GRAY}BASE SYS   :${C_RESET} ${C_WHITE}Android $(getprop ro.build.version.release) / Linux $(uname -r | cut -d- -f1)${C_RESET}"
    echo ""
    echo -e " ${C_CYAN}:: PHILOSOPHY ::${C_RESET}"
    echo -e "  ${C_GRAY}\"Logic in mind, Hardware in hand.\"${C_RESET}"
    echo -e "  ${C_GRAY}Designed for efficiency, built for control.${C_RESET}"
    echo ""
    echo -e " ${C_CYAN}:: SOURCE CONTROL ::${C_RESET}"
    echo -e "  ${C_GRAY}Repo       :${C_RESET} ${C_WHITE}$MUX_REPO${C_RESET}"
    echo ""
    
    echo -ne " ${C_GREEN}👉 Open GitHub Repository? (y/n): ${C_RESET}"
    read choice
    
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        if command -v wb &> /dev/null; then
            wb "$MUX_REPO"
        else
            am start -a android.intent.action.VIEW -d "$MUX_REPO" >/dev/null 2>&1
        fi
    else
        echo ""
        _bot_say "system" "Returning to command line..."
    fi
}

function menu() {
    mux menu
}

function _mux_reload_kernel() {
    clear
    echo -e "\033[1;33m > System Reload Initiated...\033[0m"
    if [ -f "$INSTALLER" ]; then
        echo " > Re-calibrating vendor ecosystem..."
        chmod +x "$INSTALLER"
        "$INSTALLER"
    else
        echo "❌ Installer module not found. Skipping vendor config."
    fi
    source "$BASE_DIR/core.sh"
}

function _mux_force_reset() {
    _bot_say "system" "Protocol Override: Force Sync"
    echo -e "\033[1;31m⚠️  WARNING: All local changes will be obliterated.\033[0m"
    
    echo -ne "\033[1;33m🛠️ Confirm system restore? (y/n): \033[0m"
    read choice
    
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        cd "$BASE_DIR" || return
        
        echo " > Fetching latest protocols..."
        git fetch --all
        
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
        
        echo " > Resetting timeline to [origin/$branch]..."
        git reset --hard "origin/$branch"
        
        _bot_say "success" "Timeline synchronized. System clean."
        sleep 0.9
        _mux_reload_kernel
    else
        echo " > Reset canceled."
    fi
}

function _mux_update_system() {
    echo " > Checking for updates..."
    cd "$BASE_DIR" || return

    git fetch origin
    
    local LOCAL=$(git rev-parse HEAD)
    local REMOTE=$(git rev-parse @{u} 2>/dev/null)

    if [ -z "$REMOTE" ]; then
         echo "⚠️ Remote branch not found. Skipping check."
         return
    fi

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "✅ System is up-to-date (v$MUX_VERSION)."
    else
        echo " > New version available!"
        echo -ne "\033[1;36m📥 Update Mux-OS now? (y/n): \033[0m"
        read choice
        
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo " > Updating..."
            
            if git pull; then
                sleep 2.6
                _mux_reload_kernel
            else
                _bot_say "error" "Update conflict detected."
                echo -e "\033[1;31m > Critical Error: Local timeline divergent.\033[0m"
                echo -e "\033[1;33m > Suggestion: Run 'mux reset' to force synchronization.\033[0m"
            fi
        else
            echo " > Update cancelled."
        fi
    fi
}

sleep 1.9
clear
_draw_logo
_system_check
_show_hud
sleep 0.4
echo ""
_bot_say "hello"