#!/bin/bash

# 基礎路徑與版本定義 - Base Paths and Version Definition
export MUX_REPO="https://github.com/DreaM117er/mux-os"
export MUX_VERSION="4.0.0"
export MUX_ROOT="$HOME/mux-os"
export BASE_DIR="$MUX_ROOT"

# 模組註冊表 - Module Registry
export CORE_MOD="$BASE_DIR/core.sh"
export BOT_MOD="$BASE_DIR/bot.sh"
export UI_MOD="$BASE_DIR/ui.sh"
export SYSTEM_MOD="$BASE_DIR/system.sh"
export VENDOR_MOD="$BASE_DIR/vendor.sh"
export APP_MOD="$BASE_DIR/app.sh"

# 按依賴順序排列：Bot & UI 必須最先載入 - Order by dependency: Bot & UI must load first
MODULES=(
    "$BOT_MOD"
    "$UI_MOD"
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

# 動態Help選單檢測 - Dynamic Help Detection
function _mux_dynamic_help_core() {
    echo -e "\033[1;34m :: Mux-OS Core Protocols :: Target: $MUX_VERSION @ $(hostname)\033[0m"

    awk '
    /function mux\(\) \{/ { inside_mux=1; next }
    
    /^}/ { inside_mux=0 }

    inside_mux {
        if ($0 ~ /^[[:space:]]*# :/) {
            desc = $0;
            sub(/^[[:space:]]*# :[[:space:]]*/, "", desc);
            
            getline;
            if ($0 ~ /"/) {
                split($0, parts, "\"");
                cmd_name = parts[2];
                
                printf "    \033[1;32mmux %-10s\033[0m : %s\n", cmd_name, desc;
            }
        }
    }
    ' "$CORE_MOD"
    echo -e ""
}


# Mux-OS 主指令入口 - Mux-OS Main Command Entry
# === Mux ===

# : Core Command Entry
function mux() {
    local cmd="$1"
    if [ -z "$cmd" ]; then
        _bot_say "hello"
        return
    fi

    case "$cmd" in
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

        "info"|"i")
            _mux_show_info
            ;;

        "link")
            if command -v _mux_uplink_sequence &> /dev/null; then
                _mux_uplink_sequence
            else
                pkg install fzf -y
            fi
            ;;

        "status"|"st"|"v")
            local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "Unknown")
            local last_commit=$(git log -1 --format='%h - %s (%cr)' 2>/dev/null)
            
            echo -e "\033[1;34m :: Mux-OS System Status \033[0m"
            echo -e "\033[1;37m    ›› Core Protocol :\033[0m \033[1;33mv$MUX_VERSION\033[0m"
            echo -e "\033[1;37m    ›› Current Meta  :\033[0m \033[1;35m$current_branch\033[0m"
            echo -e "\033[1;37m    ›› Last Uplink   :\033[0m \033[0;36m$last_commit\033[0m"
            ;;

        "update"|"up")
            _mux_update_system
            ;;

        "setup")
            if [ -f "$MUX_ROOT/setup.sh" ]; then
                bash "$MUX_ROOT/setup.sh"
            else
                _bot_say "error" "Lifecycle module (setup.sh) missing."
                echo -e "\033[1;30m    ›› Please re-download setup.sh from repository.\033[0m"
            fi
            ;;

        "help"|"h")
            _mux_dynamic_help_core
            ;;

        "reload"|"r")
            _mux_reload_kernel
            ;;

        "reset")
            _mux_force_reset
            if [ $? -eq 0 ]; then
                _mux_reload_kernel
            fi
            ;;

        "warpto"|"jumpto")
        echo -e "\033[1;36m :: Scanning Multiverse Coordinates...\033[0m"
        git fetch --all >/dev/null 2>&1

        local target_branch=$(git branch -r | grep -v '\->' | sed 's/origin\///' | fzf --height=10 --layout=reverse --prompt=" :: Select Mobile Suit to Pilot › " --border=none)

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
            echo -e ""
            echo -e "\033[1;33m    ›› Stabilizing Reality Matrix...\033[0m"
            sleep 1.2
            
            echo -e "\033[1;36m    ›› Flushing Quantum Cache...\033[0m"
            sleep 0.8
            
            echo -e "\033[1;35m    ›› Realigning Neural Pathways...\033[0m"
            sleep 1
            
            echo -e "\033[1;32m    ›› System Link Established.\033[0m"
            sleep 0.5

            echo -e "    ›› Reloading System Core..."
            sleep 1.6
            mux reload
        else
            _bot_say "warp" "fail"
        fi
        ;;

        *)
            echo "Unknown command: '$cmd'. Try input 'mux help'."
            ;;
    esac
}

function menu() {
    mux menu
}

function oldmenu() {
    mux oldmenu
}

# 重新載入核心模組 - Reload Core Modules
function _mux_reload_kernel() {
    _system_lock
    clear
    echo -e "\033[1;33m :: System Reload Initiated...\033[0m"
    unset MUX_INITIALIZED
    source "$MUX_ROOT/core.sh"
    _system_unlock
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

# 主程式啟動體感動畫 - Main Program Startup Animation
function _mux_init() {
if [ "$MUX_INITIALIZED" = "true" ]; then return; fi
    _system_lock
    _safe_ui_calc
    clear
    _draw_logo
    _system_check
    _show_hud
    export MUX_INITIALIZED="true"
    _system_unlock
    _bot_say "hello"
}

_mux_init