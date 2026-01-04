#!/bin/bash

# 安全檢測：確保核心模組授權載入 - Security Check: Ensure Core Module Authorized Load
if [ -f "$HOME/mux-os/setup.sh" ] && [ ! -f "$HOME/mux-os/.mux_identity" ]; then
    if [ -z "$__MUX_SETUP_ACTIVE" ]; then
        echo -e "\033[1;31m"
        echo " :: SECURITY ALERT :: System Not Initialized."
        echo " :: Identity Signature Missing."
        echo " :: Access Denied. Please execute './setup.sh' to initialize."
        echo -e "\033[0m"
        return 1 2>/dev/null || exit 1
    fi
fi

# 基礎路徑與版本定義 - Base Paths and Version Definition
export MUX_REPO="https://github.com/DreaM117er/mux-os"
export MUX_VERSION="5.0.0"
export MUX_ROOT="$HOME/mux-os"
export BASE_DIR="$MUX_ROOT"
export __MUX_CORE_ACTIVE=true

# 模組註冊表 - Module Registry
export CORE_MOD="$BASE_DIR/core.sh"
export BOT_MOD="$BASE_DIR/bot.sh"
export UI_MOD="$BASE_DIR/ui.sh"
export SYSTEM_MOD="$BASE_DIR/system.sh"
export VENDOR_MOD="$BASE_DIR/vendor.sh"
export APP_MOD="$BASE_DIR/app.sh"
export IDENTITY_MOD="$BASE_DIR/identity.sh"

# 按依賴順序排列：Bot & UI 必須最先載入 - Order by dependency: Bot & UI must load first
MODULES=(
    "$BOT_MOD"
    "$UI_MOD"
    "$IDENTITY_MOD"
    "$SYSTEM_MOD"
    "$VENDOR_MOD"
    "$APP_MOD"
)

# 核心自動掃描 - Core Auto-Scan & Load
for mod in "${MODULES[@]}"; do
    if [ -f "$mod" ]; then
        source "$mod"
    else
        case "$mod" in
            "$SYSTEM_MOD") echo -e "\033[1;31m :: Critical Error: system.sh missing!\033[0m" ;;
            "$APP_MOD")    echo "# === My Apps ===" > "$mod" && source "$mod" ;;
            *)             : ;;
        esac
    fi
done

# 初始化身份矩陣
if command -v _init_identity &> /dev/null; then
    _init_identity
fi

# 環境初始化檢測 (僅在必要時運行) - Environment Initialization Check (Run if necessary)
[ ! -d "$HOME/storage" ] && { echo -e "\033[1;33m :: Setup Storage...\033[0m"; termux-setup-storage; sleep 2; }
[ ! -f "$VENDOR_MOD" ] && [ -f "$INSTALLER" ] && { chmod +x "$INSTALLER"; "$INSTALLER"; }

# 核心指令項 - Core Command Functions
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
        echo ""
        echo -ne "\033[1;32m :: Install from Google Play? (y/n): \033[0m"
        read choice
        
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            _bot_say "loading" "Redirecting to Store..."
            am start -a android.intent.action.VIEW -d "market://details?id=$package_name" >/dev/null 2>&1
        else
            echo -e "\033[1;30m    ›› Canceled.\033[0m"
            return 1
        fi
        return 1
    fi
}

# 無參數檢測輔助函式 - No-Argument Check Helper Function
function _require_no_args() {
    if [ -n "$1" ]; then
        _bot_say "no_args" "Unexpected input: $*"
        return 1
    fi
    return 0
}

# 系統輸入鎖定與解鎖 - System Input Lock and Unlock
function _system_lock() {
    stty -echo
}

function _system_unlock() {
    stty echo
}

# 安全介面寬度計算 - Safe UI Width Calculation
function _safe_ui_calc() {
    local width=$(tput cols)
    content_limit=$(( width > 10 ? width - 10 : 2 ))
}


# Mux-OS 主指令入口 - Mux-OS Main Command Entry
# === Mux ===

# : Core Command Entry
function mux() {
    local cmd="$1"
    if [ "$__MUX_MODE" == "factory" ]; then
        echo -e "\033[1;31m :: Core commands disabled during Factory session.\033[0m"
        return 1
    fi

    if [ -z "$cmd" ]; then
        _bot_say "hello"
        return
    fi

    case "$cmd" in
        # : Open Command Dashboard
        "menu"|"m")
            if command -v fzf &> /dev/null; then
                _mux_fuzzy_menu
            else
                _show_menu_dashboard
            fi
            ;;

        "oldmenu"|"om")
            if command -v fzf &> /dev/null; then
                _show_menu_dashboard
            else
                echo "Unknown command: '$cmd'. No '$cmd' exist."
            fi
            ;;

        # : Show Mux-OS info
        "info"|"i")
            _mux_show_info
            ;;

        # : Install Dependencies
        "link")
            if command -v fzf &> /dev/null; then
                echo -e "\n\033[1;32m :: Neural Link (fzf) Status: \033[1;37mONLINE\033[0m ✅"
                _bot_say "success" "Link is stable, Commander."
                return
            fi

            echo -e ""
            echo -e "\033[1;33m :: Initialize Neural Link Protocol? \033[0m"
            echo -e "\033[1;30m    ›› Required for Multiverse Warp & Fuzzy Menu.\033[0m"
            echo -ne "\033[1;32m :: Authorize construction? [Y/n]: \033[0m"
            read choice

            if [[ "$choice" == "y" || "$choice" == "Y" || "$choice" == "" ]]; then
                if command -v _mux_uplink_sequence &> /dev/null; then
                    _mux_uplink_sequence
                else
                    echo -e "\033[1;34m    ›› Downloading Neural Interface packages...\033[0m"
                    pkg install fzf -y
                    echo -e "\033[1;32m    ›› Neural Link Established.\033[0m"
                fi
            else
                echo -e "\033[1;30m    ›› Operation aborted. Link remains offline.\033[0m"
            fi
            ;;

        # : Show System Status
        "status"|"st"|"v")
            local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
            local last_commit=$(git log -1 --format='%h - %s (%cr)' 2>/dev/null)

            if [ "$current_branch" == "main" ]; then
                    export MUX_ID="Unknown (main)"
            fi
            
            echo -e "\033[1;34m :: Mux-OS System Status \033[0m"
            echo -e "\033[1;37m    ›› Core Protocol :\033[0m \033[1;33mv$MUX_VERSION\033[0m"
            echo -e "\033[1;37m    ›› Current Meta  :\033[0m \033[1;35m$current_branch\033[0m"
            echo -e "\033[1;37m    ›› Last Uplink   :\033[0m \033[0;36m$last_commit\033[0m"
            ;;

        # : Neural Link Deploy
        "nlsdep")
            _neural_link_deploy
            ;;

        # : Check for Updates
        "update"|"up")
            _mux_update_system
            ;;

        # : Run Setup Protocol
        "setup")
            if [ -f "$MUX_ROOT/setup.sh" ]; then
                bash "$MUX_ROOT/setup.sh"
                if [ -f "$MUX_ROOT/core.sh" ]; then
                    _mux_reload_kernel
                else
                    exec bash
                fi
            else
                _bot_say "error" "Lifecycle module (setup.sh) missing."
                echo -e "\033[1;30m    ›› Please re-download setup.sh from repository.\033[0m"
            fi
            ;;

        "help"|"h")
            _mux_dynamic_help_core
            ;;

        # : Reload System Kernel
        "reload"|"r")
            _mux_reload_kernel
            ;;

        # : Force System Sync
        "reset")
            _mux_force_reset
            if [ $? -eq 0 ]; then
                _mux_reload_kernel
            fi
            ;;

        # : Multiverse Warp Drive
        "warpto"|"jumpto")
            echo -e "\033[1;36m :: Scanning Multiverse Coordinates...\033[0m"
            git fetch --all >/dev/null 2>&1

            local target_branch=$(git branch -r | grep -v '\->' | sed 's/origin\///' | fzf --ansi \
                --height=10 \
                --layout=reverse \
                --border=bottom \
                --prompt=" :: Warp Target › " \
                --header=" :: Select Timeline (Branch) ::" \
                --info=hidden \
                --pointer="››" \
                --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                --color=info:yellow,prompt:cyan,pointer:red,marker:green,border:blue,header:240 \
                --bind="resize:clear-screen"
            )

            target_branch="${target_branch// /}"

            if [ -z "$target_branch" ]; then
                _bot_say "warp" "fail"
                return 1
            fi

            local warp_type="start_local"
            if [ "$target_branch" == "main" ] || [ "$target_branch" == "master" ]; then
                warp_type="home"
            elif [[ "$target_branch" != *"$(whoami)"* ]] && [[ "$target_branch" != *"DreaM117er"* ]]; then
                warp_type="start_remote"
            fi

            _bot_say "warp" "$warp_type" "$target_branch"
            
            if [ -n "$(git status --porcelain)" ]; then
                echo -e "    ›› Stashing local modifications..."
                git stash push -m "Auto-stash before warp to $target_branch" >/dev/null 2>&1
            fi

            git checkout "$target_branch" 2>/dev/null

            if [ $? -eq 0 ]; then
                echo -e "\033[1;30m    ›› Stabilizing Reality Matrix...\033[0m"
                sleep 1.2
                echo -e "\033[1;30m    ›› Flushing Quantum Cache...\033[0m"
                sleep 0.8
                echo -e "\033[1;30m    ›› Realigning Neural Pathways...\033[0m"
                sleep 1
                echo -e "\033[1;30m    ›› System Link Established.\033[0m"
                sleep 0.5
                echo -e "\033[1;33m :: Reloading System Core...\033[0m"
                sleep 1.6
                mux reload
            else
                _bot_say "warp" "fail"
            fi
        ;;

        # : Enter the Arsenal (Factory Mode)
        "factory"|"tofac")
            if [ -f "$MUX_ROOT/factory.sh" ]; then
                source "$MUX_ROOT/factory.sh"
                
                _factory_boot_sequence
                if [ $? -ne 0 ]; then return; fi

                echo "factory" > "$MUX_ROOT/.mux_state"

                echo -e "\n\033[1;33m :: Switching to Neural Forge... \033[0m"
                sleep 0.5
                exec bash
            else
                _bot_say "error" "Factory module not found."
            fi
            ;;

        *)
            if command -v "$cmd" &> /dev/null; then
                "$cmd" "${@:2}"
                return
            fi
            
            echo -e "\033[1;37m :: Unknown Directive: $cmd\033[0m"
            ;;
    esac
}

# 重新載入核心模組 - Reload Core Modules
function _mux_reload_kernel() {
    _system_lock
    echo -e "\033[1;33m :: System Reload Initiated...\033[0m"
    sleep 1.6
    clear
    unset MUX_INITIALIZED
    source "$MUX_ROOT/core.sh"
    _mux_integrity_scan
    if [ $? -eq 0 ]; then
        _system_unlock
    else
        _system_unlock
        echo -e "\033[1;30m    ›› Neural link stabilized, but structural flaws detected.\033[0m"
        echo -e "    (Run 'fac check' in factory to auto-repair)"
    fi
}

# 強制同步系統狀態 - Force Sync System State
function _mux_force_reset() {
    _system_lock
    _bot_say "system" "Protocol Override: Force Syncing Timeline..."
    echo -e "\033[1;31m :: WARNING: Obliterating all local modifications.\033[0m"
    echo ""
    _system_unlock
    echo -ne "\033[1;32m :: Confirm system restore? (y/n): \033[0m"
    read choice
    
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        _system_lock
        cd "$BASE_DIR" || return
        
        echo "    ›› Pulling pristine protocols from origin..."
        git fetch --all
        
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
        
        git reset --hard "origin/$branch"
        
        chmod +x "$BASE_DIR/"*.sh
        
        _bot_say "success" "Timeline restored. Re-engaging Terminal Control..."
        _system_unlock
        sleep 1
        return 0
    else
        echo -e "\033[1;30m    ›› Reset canceled.\033[0m"
        _system_unlock
        return 1
    fi
}

# 系統更新檢測與執行 - System Update Check and Execution
function _mux_update_system() {
    _system_lock
    echo -e "\033[1;33m :: Checking for updates...\033[0m"
    cd "$BASE_DIR" || return

    git fetch origin
    
    local LOCAL=$(git rev-parse HEAD)
    local REMOTE=$(git rev-parse @{u} 2>/dev/null)

    if [ -z "$REMOTE" ]; then
         echo "   ›› Remote branch not found. Skipping check."
         _system_unlock
         return
    fi

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "    ›› System is up-to-date (v$MUX_VERSION). ✅"
        _system_unlock
    else
        echo -e "\033[1;33m :: New version available!\033[0m"
        echo ""
        _system_unlock
        echo -ne "\033[1;32m :: Update Mux-OS now? (y/n): \033[0m"
        read choice
        
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            _system_lock
            echo "    ›› Updating..."
            
            if git pull; then
                sleep 2.2
                _mux_reload_kernel
                _system_unlock
            else
                _bot_say "error" "Update conflict detected."
                echo -e "\033[1;31m :: Critical Error: Local timeline divergent.\033[0m"
                echo -e "\033[1;33m    ›› Suggestion: Run 'mux reset' to force synchronization.\033[0m"
                _system_unlock
            fi
        else
            echo -e "\033[1;30m    ›› Update canceled.\033[0m"
            _system_unlock
        fi
    fi
}

function _git_preflight_check() {
    echo -e "${F_GRAY} :: Verifying Neural Signature (Git Identity)...${F_RESET}"

    local git_user=$(git config user.name)
    local git_email=$(git config user.email)
    
    if [ -z "$git_user" ] || [ -z "$git_email" ]; then
        echo -e ""
        _bot_say "error" "Identity Unknown. Protocol blocked."
        echo -e "${F_GRAY}    The Grid requires a signature to accept your code.${F_RESET}"
        
        echo -e ""
        echo -ne "${F_WARN}    ›› Enter GitHub Name: ${F_RESET}"
        read input_name
        echo -ne "${F_WARN}    ›› Enter GitHub Email: ${F_RESET}"
        read input_email
        
        if [ -n "$input_name" ] && [ -n "$input_email" ]; then
            git config --global user.name "$input_name"
            git config --global user.email "$input_email"
            _bot_say "success" "Identity matrix updated: $input_name"
            echo -e ""
        else
            _bot_say "error" "Identity required. Aborting."
            return 1
        fi
    else
        echo -e "${F_GRAY}    ›› Identity Confirmed: $git_user${F_RESET}"
    fi

    echo -ne "${F_GRAY} :: Testing Uplink Connection... ${F_RESET}"
    
    if git ls-remote --heads origin >/dev/null 2>&1; then
        echo -e "\033[1;32m[CONNECTED]\033[0m"
    else
        echo -e "\033[1;31m[REJECTED]\033[0m"
        echo -e ""
        _bot_say "error" "Uplink Authentication Failed."
        echo -e "${F_SUB}    Possible causes:${F_RESET}"
        echo -e "${F_GRAY}    1. Personal Access Token (PAT) expired.${F_RESET}"
        echo -e "${F_GRAY}    2. 'gh auth login' not configured.${F_RESET}"
        echo -e "${F_GRAY}    3. Network firewall active.${F_RESET}"
        
        if command -v gh &> /dev/null; then
            echo -e ""
            echo -ne "${F_WARN}    ›› Attempt re-login via GH CLI? (y/n): ${F_RESET}"
            read try_login
            if [[ "$try_login" == "y" || "$try_login" == "Y" ]]; then
                gh auth login
                _git_preflight_check
                return $?
            fi
        fi
        
        return 1
    fi
    
    return 0
}

# 神經連結部署協議 - Neural Link Deployment Protocol
function _neural_link_deploy() {
    _git_preflight_check || return 1

    echo -e "${F_MAIN} :: NEURAL LINK DEPLOYMENT PROTOCOL ::${F_RESET}"
    echo -e "${F_GRAY}    Target Repository: Origin/Main${F_RESET}"
    echo -e "${F_GRAY}    Payload          : app.sh${F_RESET}"
    echo -e ""
    echo -e "${F_WARN} :: PRE-FLIGHT CHECKLIST ::${F_RESET}"
    echo -e "${F_SUB}    1. Are all 'fac' changes merged?${F_RESET}"
    echo -e "${F_SUB}    2. Is the formatting integrity verified?${F_RESET}"
    echo -e "${F_SUB}    3. This action pushes code to the global grid.${F_RESET}"
    echo -e ""
    
    echo -ne "${F_ERR} :: TYPE 'CONFIRM' TO ENGAGE UPLINK: ${F_RESET}"
    read confirm
    
    if [ "$confirm" != "CONFIRM" ]; then
        echo -e ""
        echo -e "${F_ERR}    ›› Authorization Failed. Uplink Aborted.${F_RESET}"
        return 1
    fi

    echo -e ""
    _bot_say "system" "Engaging Neural Uplink..."

    echo -e "${F_GRAY}    ›› Staging manifest (app.sh)...${F_RESET}"
    
    cd "$MUX_ROOT" || return 1
    
    git add app.sh
    
    local date_str=$(date '+%Y-%m-%d %H:%M')
    echo -e "${F_GRAY}    ›› Committing neural snapshot...${F_RESET}"
    git commit -m "Neural Link Deploy $date_str"
    
    echo -e "${F_GRAY}    ›› Pushing to Grid...${F_RESET}"
    git push
    
    if [ $? -eq 0 ]; then
        _bot_say "success" "Deployment Successful. Sync Complete."
    else
        _bot_say "error" "Uplink destabilized. Check network."
    fi
}

# 系統完整性掃描器 (System Integrity Scanner)
function _mux_integrity_scan() {
    local targets=("$MUX_ROOT/app.sh" "$MUX_ROOT/system.sh" "$MUX_ROOT/vendor.sh")
    local flaws_detected=0

    for file in "${targets[@]}"; do
        if [ -f "$file" ]; then
            # Check 1: EOF Newline
            if [ -n "$(tail -c 1 "$file")" ]; then
                flaws_detected=1
            fi
            
            # Check 2: Glued Functions
            if grep -q "^}[^[:space:]]" "$file"; then
                flaws_detected=1
            fi

            if grep -E "^function" "$file" | grep -vE "^function [a-zA-Z0-9_]+\(\) \{$" >/dev/null; then
                flaws_detected=1
            fi
        fi
    done

    return $flaws_detected
}

# 主程式啟動體感動畫 - Main Program Startup Animation
function _mux_init() {
    if [ "$MUX_INITIALIZED" = "true" ]; then return; fi
    _system_lock
    _safe_ui_calc
    clear
    _draw_logo "core"
    _system_check
    _show_hud
    export MUX_INITIALIZED="true"
    _system_unlock
    _bot_say "hello"
}

TARGET_MODE=""
if [ -f "$MUX_ROOT/.mux_state" ]; then
    TARGET_MODE=$(cat "$MUX_ROOT/.mux_state")
fi

if [ "$TARGET_MODE" == "factory" ]; then
    if [ -f "$BASE_DIR/factory.sh" ]; then
        source "$BASE_DIR/factory.sh"
    fi

    if command -v _factory_system_boot &> /dev/null; then
        _factory_system_boot
    else
        echo -e "\033[1;31m :: Critical Error: Factory module corrupt. Reverting to Core.\033[0m"
        rm "$MUX_ROOT/.mux_state" 2>/dev/null
        _mux_init
    fi
else
    _mux_init
fi