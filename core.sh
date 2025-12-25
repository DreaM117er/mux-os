#!/bin/bash

# 基礎路徑與版本定義 - Base Paths and Version Definition
export MUX_REPO="https://github.com/DreaM117er/mux-os"
export MUX_VERSION="2.1.0"
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
[ ! -d "$HOME/storage" ] && { echo " > Setup Storage..."; termux-setup-storage; sleep 2; }
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
        "oldmenu"|"om")
            _show_menu_dashboard
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
        sleep 1

        exec bash 
    else
        echo -e "\033[1;30m    ›› Reset canceled.\033[0m"
        _system_unlock
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