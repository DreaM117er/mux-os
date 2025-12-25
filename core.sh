#!/bin/bash

# 基礎路徑與版本定義 - Base Paths and Version Definition
export MUX_REPO="https://github.com/DreaM117er/mux-os"
export MUX_VERSION="2.0.0"
export MUX_ROOT="$HOME/mux-os"
export BASE_DIR="$MUX_ROOT"

# 模組註冊表 - Module Registry
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
            "$SYSTEM_MOD") echo -e "\033[1;31m❌ Critical Error: system.sh missing!\033[0m" ;;
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

# 無參數檢測輔助函式 - No-Argument Check Helper Function
function _require_no_args() {
    if [ -n "$1" ]; then
        _bot_say "no_args" "Unexpected input: $*"
        return 1
    fi
    return 0
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

# 重新載入核心模組 - Reload Core Modules
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

# 強制同步系統狀態 - Force Sync System State
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
        sleep 1.2
        _mux_reload_kernel
    else
        echo " > Reset canceled."
    fi
}

# 系統更新檢測與執行 - System Update Check and Execution
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

# 主程式啟動體感動畫 - Main Program Startup Animation
sleep 1.9
clear
_draw_logo
_system_check
_show_hud
sleep 0.4
echo ""
_bot_say "hello"