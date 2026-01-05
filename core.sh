#!/bin/bash

# 安全檢測：確保核心模組授權載入
if [ -f "$HOME/mux-os/setup.sh" ] && [ ! -f "$HOME/mux-os/.mux_identity" ]; then
    if [ -z "$__MUX_SETUP_ACTIVE" ]; then
        echo -e "\033[1;31m :: SECURITY ALERT :: System Not Initialized.\033[0m"
        return 1 2>/dev/null || exit 1
    fi
fi

# 基礎路徑與版本定義
export MUX_REPO="https://github.com/DreaM117er/mux-os"
export MUX_VERSION="5.0.1"
export MUX_ROOT="$HOME/mux-os"
export BASE_DIR="$MUX_ROOT"
export __MUX_CORE_ACTIVE=true

# 載入核心模組
export BOT_MOD="$MUX_ROOT/bot.sh"
export UI_MOD="$MUX_ROOT/ui.sh"
export IDENTITY_MOD="$MUX_ROOT/identity.sh"
export SYSTEM_MOD="$MUX_ROOT/system.sh"
export VENDOR_MOD="$MUX_ROOT/vendor.sh"
export APP_MOD="$MUX_ROOT/app.sh"

# 模組註冊表
MODULES=("$BOT_MOD" "$UI_MOD" "$IDENTITY_MOD" "$SYSTEM_MOD" "$VENDOR_MOD" "$APP_MOD")
for mod in "${MODULES[@]}"; do
    if [ -f "$mod" ]; then source "$mod"; fi
done

if command -v _init_identity &> /dev/null; then _init_identity; fi

[ ! -d "$HOME/storage" ] && { termux-setup-storage; sleep 1; }

# 核心指令項
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
        echo -ne "\033[1;32m :: Install from Google Play? (Y/n): \033[0m"
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

# 啟動序列邏輯 (Boot Sequence)
function _mux_boot_sequence() {
    if [ "$MUX_INITIALIZED" = "true" ]; then return; fi
    
    local TARGET_MODE=""
    if [ -f "$MUX_ROOT/.mux_state" ]; then
        TARGET_MODE=$(cat "$MUX_ROOT/.mux_state")
    fi

    if [ "$TARGET_MODE" == "factory" ]; then
        if [ -f "$BASE_DIR/factory.sh" ]; then
            export __MUX_MODE="factory"
            source "$BASE_DIR/factory.sh"
            _factory_system_boot 
        else
            echo "core" > "$MUX_ROOT/.mux_state"
            _mux_init
        fi
    else
        if [ -f "$MUX_ROOT/.mux_state" ]; then rm "$MUX_ROOT/.mux_state"; fi
        _mux_init
    fi
}

# 主程式初始化 (Main Initialization)
function _mux_init() {
    if [ "$MUX_INITIALIZED" = "true" ]; then return; fi
    
    _system_lock
    _safe_ui_calc
    clear
    _draw_logo "core"
    
    if command -v _system_check &> /dev/null; then
        _system_check
    fi
    
    if command -v _show_hud &> /dev/null; then
        _show_hud
    fi
    
    export MUX_INITIALIZED="true"
    _system_unlock
    _bot_say "hello"
}

# 無參數檢測輔助函式
function _require_no_args() {
    if [ -n "$1" ]; then
        _bot_say "no_args" "Unexpected input: $*"
        return 1
    fi
    return 0
}

# 系統輸入鎖定與解鎖
function _system_lock() {
    if [ -t 0 ]; then stty -echo; fi
}

function _system_unlock() {
    if [ -t 0 ]; then stty echo; fi
}

# 安全介面寬度計算
function _safe_ui_calc() {
    local width=$(tput cols)
    content_limit=$(( width > 10 ? width - 10 : 2 ))
}

# Mux-OS 主指令入口
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
            _show_menu_dashboard
            ;;
        # : Infomation
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
            echo -ne "\033[1;32m :: Authorize construction? [Y/n]: \033[0m"
            read choice
            if [[ "$choice" == "y" || "$choice" == "Y" || "$choice" == "" ]]; then
                if command -v _mux_uplink_sequence &> /dev/null; then
                    _mux_uplink_sequence
                else
                    pkg install fzf -y
                fi
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
                _bot_say "error" "Lifecycle module missing."
            fi
            ;;

        "help"|"h")
            _mux_dynamic_help_core
            ;;

        # : Reload System Kernel
        "reload"|"rl")
            _mux_reload_kernel
            ;;

        # : Force System Sync
        "reset"|"rst")
            _mux_force_reset
            if [ $? -eq 0 ]; then
                _mux_reload_kernel
            fi
            ;;
        # : Multiverse Warp Drive
        "warpto"|"jumpto")
            echo -e "\033[1;36m :: Scanning Multiverse Coordinates...\033[0m"
            git fetch --all >/dev/null 2>&1
            local target_branch=$(git branch -r | grep -v '\->' | sed 's/origin\///' | fzf --ansi --height=10 --layout=reverse --border=bottom --prompt=" :: Warp Target › " --pointer="››")
            target_branch="${target_branch// /}"
            if [ -z "$target_branch" ]; then _bot_say "warp" "fail"; return 1; fi
            local warp_type="start_local"
            if [ "$target_branch" == "main" ] || [ "$target_branch" == "master" ]; then warp_type="home"; elif [[ "$target_branch" != *"$(whoami)"* ]]; then warp_type="start_remote"; fi
            _bot_say "warp" "$warp_type" "$target_branch"
            if [ -n "$(git status --porcelain)" ]; then git stash push -m "Auto-stash before warp"; fi
            git checkout "$target_branch" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "\033[1;33m :: Reloading System Core...\033[0m"
                sleep 1.6
                mux reload
            else
                _bot_say "warp" "fail"
            fi
        ;;

        # : Enter the Arsenal (Factory Mode)
        "factory"|"tofac"|"fac")
            _core_pre_factory_auth
            ;;

        *)
            if command -v "$cmd" &> /dev/null; then "$cmd" "${@:2}"; return; fi
            echo -e "\033[1;37m :: Unknown Directive: $cmd\033[0m"
            ;;
    esac
}

# 工廠前置驗證協議 (Pre-Flight Auth)
function _core_pre_factory_auth() {
    local F_GRAY="\033[1;30m"
    local F_RED="\033[1;31m"
    local F_WARN="\033[1;33m"
    local F_RESET="\033[0m"
    local F_GRE="\033[1;32m"
    local F_SUB="\033[1;37m"

    clear
    _draw_logo "gray"
    
    _system_lock
    echo -e "${F_GRAY} :: SECURITY CHECKPOINT ::${F_RESET}"
    echo -e "${F_GRAY}    Identity Verification Required.${F_RESET}"
    sleep 0.5
    echo ""
    
    _system_unlock
    echo -ne "${F_SUB} :: Commander ID: ${F_RESET}" 
    read input_id
    
    local verify_success=0
    if [ -f "$MUX_ROOT/.mux_identity" ]; then
        local REAL_ID=$(grep "MUX_ID=" "$MUX_ROOT/.mux_identity" | cut -d'=' -f2)
        if [ "$input_id" == "$REAL_ID" ] || [ "$REAL_ID" == "Unknown" ]; then
            verify_success=1
        fi
    else
        verify_success=1
    fi

    if [ "$verify_success" -ne 1 ]; then
        _core_eject_sequence "Identity Mismatch."
        return 1
    fi

    echo -ne "${F_WARN} :: CONFIRM IDENTITY (Type 'CONFIRM'): ${F_RESET}"
    read confirm
    
    if [ "$confirm" != "CONFIRM" ]; then
        _core_eject_sequence "Confirmation Failed."
        return 1
    fi

    echo ""
    _system_lock
    echo -ne "${F_GRAY} :: Verifying Neural Signature... ${F_RESET}"
    sleep 0.8
    echo -e "\r${F_GRE} :: ACCESS GRANTED ::                     ${F_RESET}"
    sleep 0.5
    
    echo -ne "${F_GRAY} :: Scanning Combat Equipment... ${F_RESET}"
    sleep 0.5
    if ! command -v fzf &> /dev/null; then
        echo -e "\n${F_RED} :: EQUIPMENT MISSING :: ${F_RESET}"
        sleep 1
        _core_eject_sequence "Neural Link (fzf) Required."
        return 1
    else
        echo -e "\r${F_GRE} :: EQUIPMENT CONFIRM :: ${F_RESET}"
        sleep 0.3
    fi

    echo ""
    echo -e "${F_RED} :: WARNING: FACTORY PROTOCOL :: ${F_RESET}"
    echo -e "${F_GRAY}    1. Modifications are permanent.${F_RESET}"
    echo -e "${F_GRAY}    2. Sandbox Environment Active (.temp).${F_RESET}"
    echo -e "${F_GRAY}    3. Core 'mux' commands are ${F_RED}LOCKED${F_RESET}.${F_RESET}"
    echo -e "${F_GRAY}    4. App launches are ${F_RED}LOCKED${F_RESET}.${F_RESET}"
    echo -e "${F_GRAY}    5. You are responsible for system stability.${F_RESET}"
    echo ""
    
    _system_unlock
    echo -ne "${F_WARN} :: Proceed? [Y/n]: ${F_RESET}"
    read choice
    
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        _core_eject_sequence "User Aborted."
        return 1
    fi
    
    _system_lock
    local steps=("Injecting Logic..." "Desynchronizing Core..." "Loading Arsenal..." "Entering Factory...")
    for step in "${steps[@]}"; do
        echo -e "${F_GRAY}    ›› $step${F_RESET}"
        sleep 0.4
    done
    sleep 0.5
    
    if [ -f "$MUX_ROOT/gate.sh" ]; then
        exec "$MUX_ROOT/gate.sh" "factory"
    else
        echo "factory" > "$MUX_ROOT/.mux_state"
        exec bash
    fi
}

# 彈射序列 (The Ejection - Core Simulation)
function _core_eject_sequence() {
    local reason="$1"
    local F_ERR="\033[1;31m"
    local F_RESET="\033[0m"
    
    _system_lock
    echo ""
    echo -e "${F_ERR} :: ACCESS DENIED :: ${reason}${F_RESET}"
    echo ""
    sleep 0.8
    echo -e "${F_ERR} :: Initiating Eviction Protocol...${F_RESET}"
    sleep 0.4
    echo -e "${F_ERR} :: Locking Cockpit...${F_RESET}"
    sleep 0.6
    echo -e "${F_ERR} :: Auto-Eject System Activated.${F_RESET}"
    sleep 1
    
    for i in {3..1}; do
        echo -e "${F_ERR}    ›› Ejection in $i...${F_RESET}"
        sleep 1
    done
    
    echo ""
    if command -v _bot_say &> /dev/null; then
        _bot_say "eject"
    fi
    sleep 2.0
    
    if command -v _ui_fake_gate &> /dev/null; then
        _ui_fake_gate "core"
    else
        clear
    fi
    
    _mux_init
}

# 重新載入核心模組
function _mux_reload_kernel() {
    _system_lock
    unset MUX_INITIALIZED
    
    if [ -f "$MUX_ROOT/gate.sh" ]; then
        exec "$MUX_ROOT/gate.sh" "core"
    else
        exec bash
    fi
}

# 強制同步系統狀態
function _mux_force_reset() {
    _system_lock
    _bot_say "system" "Protocol Override: Force Syncing Timeline..."
    echo -e "\033[1;31m :: WARNING: Obliterating all local modifications.\033[0m"
    echo ""
    _system_unlock
    echo -ne "\033[1;32m :: Confirm system restore? (Y/n): \033[0m"
    read choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        _system_lock
        cd "$BASE_DIR" || return
        git fetch --all
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
        git reset --hard "origin/$branch"
        chmod +x "$BASE_DIR/"*.sh
        _bot_say "success" "Timeline restored."
        _system_unlock
        sleep 1
        return 0
    else
        echo -e "\033[1;30m    ›› Reset canceled.\033[0m"
        _system_unlock
        return 1
    fi
}

# 系統更新檢測與執行
function _mux_update_system() {
    _system_lock
    echo -e "\033[1;33m :: Checking for updates...\033[0m"
    cd "$BASE_DIR" || return
    git fetch origin
    local LOCAL=$(git rev-parse HEAD)
    local REMOTE=$(git rev-parse @{u} 2>/dev/null)
    if [ -z "$REMOTE" ]; then echo "   ›› Remote branch not found."; _system_unlock; return; fi
    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "    ›› System is up-to-date (v$MUX_VERSION). ✅"
        _system_unlock
    else
        echo -e "\033[1;33m :: New version available!\033[0m"
        echo ""
        _system_unlock
        echo -ne "\033[1;32m :: Update Mux-OS now? (Y/n): \033[0m"
        read choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            _system_lock
            if git pull; then sleep 2.2; _mux_reload_kernel; else _bot_say "error" "Update conflict detected."; _system_unlock; fi
        else
            _system_unlock
        fi
    fi
}

# 神經連結部署協議
function _neural_link_deploy() {
    if [ -z "$(git config user.name)" ]; then
         _bot_say "error" "Identity missing. Config git user.name first."
         return 1
    fi
    echo -e "${F_MAIN} :: NEURAL LINK DEPLOYMENT PROTOCOL ::${F_RESET}"
    echo -ne "${F_ERR} :: TYPE 'CONFIRM' TO ENGAGE UPLINK: ${F_RESET}"
    read confirm
    if [ "$confirm" != "CONFIRM" ]; then return 1; fi
    _bot_say "system" "Engaging Neural Uplink..."
    cd "$MUX_ROOT" || return 1
    git add .
    git commit -m "Neural Link Deploy $(date '+%Y-%m-%d %H:%M')"
    git push
    if [ $? -eq 0 ]; then _bot_say "success" "Deployment Successful."; else _bot_say "error" "Uplink destabilized."; fi
}

# 系統完整性掃描器
function _mux_integrity_scan() {
    return 0
}