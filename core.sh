#!/bin/bash

export MUX_VERSION="1.5.0"
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

function _draw_logo() {
    # Mux-OS ASCII Art
    echo -e "\033[1;36m"
    cat << "EOF"
  __  __                  ___  ____  
 |  \/  |_   ___  __     / _ \/ ___| 
 | |\/| | | | \ \/ /____| | | \___ \ 
 | |  | | |_| |>  <_____| |_| |___) |
 |_|  |_|\__,_/_/\_\     \___/|____/ 
EOF
    echo -e "\033[0m"
    echo -e " \033[1;30m:: Mux-OS Core v$MUX_VERSION :: Target: Android/Termux ::\033[0m"
    echo ""
}

function _system_check() {
    local C_CHECK="\033[1;32m✓\033[0m"
    local C_PROC="\033[1;33m⟳\033[0m"
    
    local steps=(
        "Initializing Kernel Bridge..."
        "Mounting Vendor Ecosystem [Samsung]..."
        "Verifying Neural Link (fzf)..."
        "Calibrating Touch Matrix..."
        "Bypassing Knox Security Layer..."
        "Establish Uplink..."
    )

    for step in "${steps[@]}"; do
        echo -ne " $C_PROC $step\r"
        sleep 0.08
        
        echo -e " $C_CHECK $step                    "
        sleep 0.02
    done
    echo ""
}

function _show_hud() {
    local android_ver=$(getprop ro.build.version.release)
    local brand_raw=$(getprop ro.product.brand | tr '[:lower:]' '[:upper:]' | cut -c1)$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]' | cut -c2-)
    local model=$(getprop ro.product.model)
    local kernel_ver=$(uname -r | awk -F- '{print $1}')
    local mem_info=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
    local host_str="$brand_raw $model (Android $android_ver)"

    if [ ${#host_str} -gt 36 ]; then
        host_str="${host_str:0:33}..."
    fi
   
    echo -e "\033[1;34m╔════════════════════════════════════════╗\033[0m"
    printf "\033[1;34m║\033[0m \033[1;37mHOST   \033[0m: %-30s \033[1;34m║\033[0m\n" "$host_str"
    printf "\033[1;34m║\033[0m \033[1;37mKERNEL \033[0m: %-30s \033[1;34m║\033[0m\n" "$kernel_ver"
    printf "\033[1;34m║\033[0m \033[1;37mMEMORY \033[0m: %-30s \033[1;34m║\033[0m\n" "$mem_info"
    echo -e "\033[1;34m╚════════════════════════════════════════╝\033[0m"
    echo ""
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

function _mux_fuzzy_menu() {
    if ! command -v fzf &> /dev/null; then
        _show_menu_dashboard
        
        echo -e "\n\033[1;33m⚠️  Neural Search Module (fzf) is missing.\033[0m"
        echo -ne "\033[1;36m📥 Install now to enable interactive interface? (y/n): \033[0m"
        read choice
        
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo " > Installing fzf..."
            pkg install fzf -y
            
            echo -e "\033[1;32m✅ Module installed. Initializing Neural Link...\033[0m"
            sleep 1
            _mux_fuzzy_menu
            return
        else
            echo " > Keeping legacy menu."
            return
        fi
    fi

    local selected=$(
        awk '
        BEGIN {
            C_CMD="\033[1;36m"
            C_DESC="\033[1;30m"
            C_RESET="\033[0m"
        }
        
        /^function / {
            match($0, /function ([a-zA-Z0-9_]+)/, arr);
            func_name = arr[1];
            
            if (substr(func_name, 1, 1) != "_" && func_name != "mux") {
                desc = "";
                if (prev_line ~ /^# :/) {
                    desc = prev_line;
                    gsub(/^# : /, "", desc);
                }
                
                if (desc != "") {
                    printf C_CMD "%-12s" C_DESC " %s" C_RESET "\n", func_name, desc;
                }
            }
        }
        { prev_line = $0 }
        ' "$SYSTEM_MOD" "$APP_MOD" "$VENDOR_MOD" | \
        fzf --ansi --height=45% --layout=reverse --border \
            --prompt="🔍 Neural Link > " \
            --pointer="▶" \
            --marker="✓" \
            --header="[Select Protocol to Execute]" \
            --color=fg:white,bg:-1,hl:green,fg+:cyan,bg+:black,hl+:yellow,info:yellow,prompt:cyan,pointer:red
    )

    if [ -n "$selected" ]; then
        local cmd_to_run=$(echo "$selected" | awk '{print $1}')
        
        history -s "$cmd_to_run"
        _bot_say "neural" "Executing: $cmd_to_run"
        eval "$cmd_to_run"
    else
        :
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
        _mux_reload_kernel
    else
        echo " > Reset canceled."
    fi
}

function _mux_update_system() {
    clear
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
                _bot_say "success" "Update complete. Reloading kernel..."
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
echo ""
sleep 0.4
_bot_say "hello"