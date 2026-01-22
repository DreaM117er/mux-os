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
export MUX_VERSION="7.0.0"
export MUX_ROOT="$HOME/mux-os"
export BASE_DIR="$MUX_ROOT"
export MUX_BAK="$MUX_ROOT/bak"
export __MUX_CORE_ACTIVE=true

# 載入核心模組
export CORE_MOD="$MUX_ROOT/core.sh"
export BOT_MOD="$MUX_ROOT/bot.sh"
export UI_MOD="$MUX_ROOT/ui.sh"
export IDENTITY_MOD="$MUX_ROOT/identity.sh"
export SYSTEM_MOD="$MUX_ROOT/system.csv"
export VENDOR_MOD="$MUX_ROOT/vendor.csv"
export APP_MOD="$MUX_ROOT/app.csv"

# 模組註冊表
MODULES=("$BOT_MOD" "$UI_MOD" "$IDENTITY_MOD")
for mod in "${MODULES[@]}"; do
    if [ -f "$mod" ]; then source "$mod"; fi
done

if command -v _init_identity &> /dev/null; then _init_identity; fi

[ ! -d "$HOME/storage" ] && { termux-setup-storage; sleep 1; }

# 神經資料解析器
function _mux_neural_data() {
    local target_com="$1"
    local target_sub="$2"
    local raw_data=""
    
    local VENDOR_FILE="$MUX_ROOT/vendor.csv"
    if [ ! -f "$VENDOR_FILE" ] && [ -f "$MUX_ROOT/samsung.csv" ]; then
        VENDOR_FILE="$MUX_ROOT/samsung.csv"
    fi

    local neural_banks=("$SYSTEM_MOD" "$VENDOR_FILE" "$APP_MOD")

    for bank in "${neural_banks[@]}"; do
        [ ! -f "$bank" ] && continue
        
        raw_data=$(awk -v FPAT='([^,]*)|("[^"]+")' -v key="$target_com" -v subkey="$target_sub" '
            !/^#/ { 
                row_com = $5; gsub(/^"|"$/, "", row_com); gsub(/\r| /, "", row_com)
                row_com2 = $6; gsub(/^"|"$/, "", row_com2); gsub(/\r| /, "", row_com2)

                if (row_com == key && row_com2 == subkey && subkey != "") {
                    print $0; exit
                }
                
                if (row_com == key && row_com2 == "") {
                    fallback = $0
                }
            }
            END {
                if (fallback != "") print fallback
            }
        ' "$bank")
        
        [ -n "$raw_data" ] && break
    done

    if [ -z "$raw_data" ]; then return 1; fi

    eval $(echo "$raw_data" | awk -v FPAT='([^,]*)|("[^"]+")' '{
        fields[1]="_VAL_CATNO"
        fields[2]="_VAL_COMNO"
        fields[3]="_VAL_CATNAME"
        fields[4]="_VAL_TYPE"
        fields[5]="_VAL_COM"
        fields[6]="_VAL_COM2"
        fields[7]="_VAL_COM3"
        fields[8]="_VAL_HUDNAME"
        fields[9]="_VAL_UINAME"
        fields[10]="_VAL_PKG"
        fields[11]="_VAL_TARGET"
        fields[12]="_VAL_IHEAD"
        fields[13]="_VAL_IBODY"
        fields[14]="_VAL_URI"
        fields[15]="_VAL_MIME"
        fields[16]="_VAL_CATE"
        fields[17]="_VAL_FLAG"
        fields[18]="_VAL_EX"
        fields[19]="_VAL_EXTRA"
        fields[20]="_VAL_ENGINE"

        for (i=1; i<=20; i++) {
            val = $i
            if (val ~ /^".*"$/) { val = substr(val, 2, length(val)-2) }
            gsub(/""/, "\"", val)
            gsub(/'\''/, "'\''\\'\'''\''", val)
            printf "%s='\''%s'\''; ", fields[i], val
        }
    }')
    
    _VAL_ENGINE=${_VAL_ENGINE//$'\r'/}
    return 0
}

# 瀏覽器網址搜尋引擎
export SEARCH_GOOGLE="https://www.google.com/search?q="
export SEARCH_BING="https://www.bing.com/search?q="
export SEARCH_DUCK="https://duckduckgo.com/?q="
export SEARCH_YOUTUBE="https://www.youtube.com/results?search_query="
export SEARCH_GITHUB="https://github.com/search?q="

export __GO_TARGET=""
export __GO_MODE=""

function _resolve_smart_url()
    local engine_url="$1"
    local user_query="$2"

    # 1. 基礎清洗：全形轉半形
    local raw_input=$(echo "$user_query" | sed 'y/。．/../' | sed 's/　/ /g')

    # 2. 安全編碼：空格轉 +
    local safe_query="${raw_input// /+}"

    # 3. 初始化目標
    __GO_TARGET=""
    __GO_MODE="launch"

    # 4. 智慧判斷邏輯 (Smart Detection)
    # Case A: 明確的通訊協定 -> 直接前往
    if [[ "$raw_input" == http* ]]; then
        __GO_TARGET="$raw_input"

    # Case B: 裸網域 -> 自動補上 https://
    elif [[ "$raw_input" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
         echo "$raw_input" | grep -qE "^[a-zA-Z0-9.-]+\.(com|net|org|edu|gov|io|tw|jp|cn|hk|uk|us|xyz|info|biz|me|top)$"; then
        __GO_TARGET="https://$raw_input"

    # Case C: 關鍵字搜尋 -> 使用引擎
    else
        if [ -n "$engine_url" ]; then
            __GO_TARGET="${engine_url}${safe_query}"
            __GO_MODE="neural"
        else
            __GO_TARGET="$safe_query"
            __GO_MODE="direct"
        fi
    fi
}

# 核心指令項
function _launch_android_app() {
    local name="${1:-$_VAL_UINAME}"
    local pkg="${2:-$_VAL_PKG}"
    
    local final_action=""
    if [ -n "$_VAL_IHEAD" ] || [ -n "$_VAL_IBODY" ]; then
        final_action="${_VAL_IHEAD}${_VAL_IBODY}"
    fi

    # -n/-p 優先判定
    local cmd_args=""
    if [ -n "$pkg" ]; then 
        if [ -n "$_VAL_TARGET" ]; then
            cmd_args="$cmd_args -n $pkg/$_VAL_TARGET"
        else
            cmd_args="$cmd_args -p $pkg"
        fi
    fi

    # 純啓動不用-a/-d 參數判定

    # RELOAD
    if [ -n "$_VAL_CATE" ];    then cmd_args="$cmd_args -c \"android.intent.category.$_VAL_CATE\""; fi
    if [ -n "$_VAL_MIME" ];    then cmd_args="$cmd_args -t \"$_VAL_MIME\""; fi
    if [ -n "$_VAL_FLAG" ];    then cmd_args="$cmd_args -f $_VAL_FLAG"; fi
    if [ -n "$_VAL_EX" ];      then cmd_args="$cmd_args $_VAL_EX"; fi
    if [ -n "$_VAL_EXTRA" ];   then cmd_args="$cmd_args $_VAL_EXTRA"; fi

    _bot_say "launch" "Target: '$name'"
    
    # FIRE THE COMMAND
    local output
    output=$(eval "am start --user 0 $cmd_args" 2>&1)

    # 驗證發射結果
    _mux_launch_validator "$output" "$pkg"
}

# 發射結果驗證器 (Launch Result Validator)
function _mux_launch_validator() {
    local output="$1"
    local pkg="$2"

    # 偵測關鍵字：Error, does not exist, unable to resolve
    if [[ "$output" == *"Error"* ]] || [[ "$output" == *"does not exist"* ]] || [[ "$output" == *"unable to resolve"* ]]; then
        _bot_say "error" "Launch Failed: Target package not found or intent unresolved."
        echo -e "    ›› Target: $pkg"
        echo ""
        echo -ne "\033[1;32m :: Install from Google Play? [Y/n]: \033[0m"
        read choice
        
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            _bot_say "loading" "Redirecting to Store..."
            am start -a android.intent.action.VIEW -d "market://details?id=$pkg" >/dev/null 2>&1
        else
            echo -e "\033[1;30m    ›› Canceled.\033[0m"
            return 1
        fi
        return 1
    fi
    return 0
}

# 啟動序列邏輯 (Boot Sequence)
function _mux_boot_sequence() {
    if [ "$MUX_INITIALIZED" = "true" ]; then return; fi
    
    local TARGET_MODE=""
    if [ -f "$MUX_ROOT/.mux_state" ]; then
        TARGET_MODE=$(cat "$MUX_ROOT/.mux_state")
    fi

    if [ "$TARGET_MODE" == "factory" ]; then
        if [ -f "$MUX_ROOT/factory.sh" ]; then
            export __MUX_MODE="factory"
            source "$MUX_ROOT/factory.sh"
            
            if command -v _factory_system_boot &> /dev/null; then
                _factory_system_boot 
            fi
        else
            echo "core" > "$MUX_ROOT/.mux_state"
            _mux_init
        fi
    else
        if [ -f "$MUX_ROOT/.mux_state" ]; then echo "core" > "$MUX_ROOT/.mux_state"; fi
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


# Mux-OS 指令入口 - Core Command Entry
# === Mux ===

# : Core Command Entry
function mux() {
    local cmd="$1"
    if [ "$__MUX_MODE" == "factory" ]; then
        _bot_say "error" "Core commands disabled during Factory session."
        return 1
    fi

    if [ -z "$cmd" ]; then
        _bot_say "hello"
        return
    fi

    case "$cmd" in
        # : Open Command Dashboard
        "menu")
            if command -v fzf &> /dev/null; then
                _mux_fuzzy_menu
            else
                _show_menu_dashboard
            fi
            ;;

        "oldmenu"|"omenu")
            _show_menu_dashboard
            ;;

        # : Infomation
        "info")
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
            echo -e ""
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
        "status"|"sts")
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
        "nldeploy")
            _neural_link_deploy
            ;;

        # : Check for Updates
        "update")
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

        "help")
            _mux_dynamic_help_core
            ;;

        # : Reload System Kernel
        "reload")
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
        "warpto"|"wrp2")
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
                
                if [ -d "$MUX_ROOT" ]; then chmod +x "$MUX_ROOT/"*.sh 2>/dev/null; fi
                
                if [ -f "$MUX_ROOT/gate.sh" ]; then
                    source "$MUX_ROOT/gate.sh" "core"
                elif [ -f "$MUX_ROOT/core.sh" ]; then
                    source "$MUX_ROOT/core.sh"
                else
                    echo ":: Warp incomplete. System files missing."
                fi
            else
                _bot_say "warp" "fail"
            fi
        ;;

        # : Enter the Arsenal (Factory Mode)
        "factory"|"tofac")
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
    local F_ORG="\033[1;38;5;208m"

    clear
    _draw_logo "gray"
    
    _system_lock
    echo -e "${F_ORG} :: SECURITY CHECKPOINT ::${F_RESET}"
    echo -e "${F_GRAY}    ›› Identity Verification Required.${F_RESET}"
    sleep 0.4
    echo ""
    
    _system_unlock
    echo -ne "${F_SUB} :: Commander ID: ${F_RESET}" 
    read input_id

    local identity_valid=0
    if [ -f "$MUX_ROOT/.mux_identity" ]; then
        local REAL_ID=$(grep "MUX_ID=" "$MUX_ROOT/.mux_identity" | cut -d'=' -f2)
        if [ "$input_id" == "$REAL_ID" ] || [ "$REAL_ID" == "Unknown" ]; then
            identity_valid=1
        fi
    else
        identity_valid=1
    fi

    echo -ne "${F_WARN} :: CONFIRM IDENTITY (Type 'CONFIRM'): ${F_RESET}"
    read confirm
    
    if [ "$confirm" != "CONFIRM" ]; then
        _core_eject_sequence "Confirmation Failed."
        return 1
    fi

    if [ "$identity_valid" -ne 1 ]; then
        _core_eject_sequence "Identity Mismatch."
        return 1
    fi

    echo ""
    _system_lock
    echo -e "${F_GRAY} :: Verifying Neural Signature... ${F_RESET}"
    sleep 0.8
    echo ""
    echo -e "${F_GRE} :: ACCESS GRANTED :: ${F_RESET}"
    sleep 0.5
    echo ""
    echo -e "${F_GRAY} :: Scanning Combat Equipment... ${F_RESET}"
    sleep 1
    echo ""
    if ! command -v fzf &> /dev/null; then
        echo -e "\n${F_RED} :: EQUIPMENT MISSING :: ${F_RESET}"
        echo ""
        sleep 0.5
        _core_eject_sequence "Neural Link (fzf) Required."
        return 1
    else
        echo -e "\r${F_GRE} :: EQUIPMENT CONFIRM :: ${F_RESET}"
        sleep 0.5
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
        source "$MUX_ROOT/gate.sh" "factory"
    else
        _bot_say "error" "Gate Mechanism Not Found."
        return 1
    fi
}

# 彈射序列 (The Ejection - Core Simulation)
function _core_eject_sequence() {
    local reason="$1"
    local F_ERR="\033[1;31m"
    local F_RESET="\033[0m"
    local F_GRAY="\033[1;30m"
    
    _system_lock
    echo ""
    echo -e "${F_ERR} :: ACCESS DENIED :: ${reason}${F_RESET}"
    sleep 0.8
    echo ""
    echo -e "${F_ERR} :: Initiating Eviction Protocol...${F_RESET}"
    sleep 0.4
    echo -e "${F_ERR} :: Locking Cockpit...${F_RESET}"
    sleep 0.6
    echo -e "${F_ERR} :: Auto-Eject System Activated.${F_RESET}"
    sleep 1
    
    for i in {3..1}; do
        echo -e "${F_GRAY}    ›› Ejection in $i...${F_RESET}"
        sleep 0.99
    done

    echo -e ""
    _bot_factory_personality "eject"
    sleep 1.9
    _ui_fake_gate "core"
    _safe_ui_calc
    clear
    _draw_logo "core"
    _system_check
    _show_hud
    _system_unlock
    _bot_say "hello"
}

# 重新載入核心模組
function _mux_reload_kernel() {
    _system_lock
    unset MUX_INITIALIZED
    
    if [ -f "$MUX_ROOT/gate.sh" ]; then
        source "$MUX_ROOT/gate.sh" "core"
    else
        source "$MUX_ROOT/core.sh"
    fi
}

# 強制同步系統狀態
function _mux_force_reset() {
    _system_lock
    _bot_say "system" "Protocol Override: Force Syncing Timeline..."
    echo -e "\033[1;31m :: WARNING: Obliterating all local modifications.\033[0m"
    echo ""
    _system_unlock
    echo -ne "\033[1;32m :: Confirm system restore? [Y/n]: \033[0m"
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
        echo -ne "\033[1;32m :: Update Mux-OS now? [Y/n]: \033[0m"
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

# 安全過濾層 (Security Layer)
function _mux_security_gate() {
    local cmd="$1"
    
    # 定義違禁關鍵字 (Root指令/危險操作)
    if [[ "$cmd" =~ ^(su|tsu|sudo|mount|umount)$ ]]; then
        _bot_say "warn" "Administrator access denied. (Non-Root Protocol Active)"
        return 1
    fi

    # 針對 pm (Package Manager) 的寫入操作進行攔截
    if [[ "$cmd" == "pm" ]]; then
        if [[ "$@" =~ (disable|hide|enable|unhide) ]]; then
            _bot_say "warn" "Package modification is locked by Manufacturer."
            return 1
        fi
    fi

    return 0
}

function _mux_neural_fire_control() {
    local input_signal="$1" # COM
    local input_sub="$2" # COM2 (Candidate)
    local input_args="${*:2}" # All args starting from $2

    if [ "$__MUX_MODE" == "factory" ]; then
        if command -v _factory_mask_apps &> /dev/null; then
            _factory_mask_apps "$input_signal" "$input_sub" || return 127
        fi
    fi
   
    if ! _mux_neural_data "$input_signal" "$input_sub"; then
        _bot_say "error" "'$input_signal' command not found."
        return 127
    fi

    integrity_flag=$(echo "$_VAL_COM3" | tr -d ' "')

    if [ "$integrity_flag" == "F" ]; then
        echo ""
        _bot_say "error" "NEURAL LINK SEVERED :: Integrity Failure (Code: F)"
        echo -e "\033[1;30m ›› Diagnosis: Critical parameter missing or malformed.\033[0m"
        echo -e "\033[1;30m ›› Protocol : Execution blocked by Safety Override.\033[0m"
        echo -e "\033[1;30m ›› Action : Use 'factory' to repair this node.\033[0m"
        echo ""
        return 127
    elif [ "$integrity_flag" == "W" ]; then
        echo ""
        _bot_say "warn" "NEURAL LINK UNSTABLE :: Parameter Anomaly (Code: W)"
        echo -e "\033[1;30m ›› Diagnosis: Non-critical structure mismatch detected.\033[0m"
        echo -e "\033[1;30m ›› Protocol : Bypassing safety lock... Executing with caution.\033[0m"
        sleep 0.8
    fi

    local cate_arg=""

    if [ -n "$_VAL_CATE" ]; then
        cate_arg=" -c android.intent.category.$_VAL_CATE"
    fi

    case "$_VAL_TYPE" in
        "NA")
            if [ -z "$_VAL_COM2" ]; then
                _require_no_args "$input_args" || return 1
                _launch_android_app
            else
                _require_no_args "${*:3}" || return 1
                _launch_android_app
            fi
            ;;

        "NB")
            local real_args=""
            if [ -n "$_VAL_COM2" ]; then
                real_args="${*:3}"
            else
                real_args="$input_args"
            fi
            
            # 安全檢查
            if [ -z "$real_args" ]; then
                if [ -n "$_VAL_PKG" ] && [ -n "$_VAL_TARGET" ]; then
                    _VAL_URI=""
                    _launch_android_app
                    return 0
                fi
                _bot_say "error" "Strict Protocol [$_VAL_COM]: Parameter required."
                return 1
            fi
            
            if [ -z "$_VAL_IHEAD" ] || [ -z "$_VAL_IBODY" ]; then
                _bot_say "error" "System Integrity: Malformed Intent (Missing HEAD/BODY)."
                return 1
            fi
            local final_action="${_VAL_IHEAD}${_VAL_IBODY}"

            # 2. Web Search Intent (.WEB_SEARCH)
            if [[ "$final_action" == *".WEB_SEARCH"* ]]; then
               
                local raw_input=$(echo "$real_args" | sed 'y/。．/../' | sed 's/　/ /g')
                local safe_query="${raw_input//\"/\\\"}"
               
                _bot_say "neural" "Payload: Raw Search ›› '$safe_query'"
               
                local cmd="am start --user 0 -a $final_action$cate_arg -e query \"$safe_query\""
               
                if [ -n "$_VAL_PKG" ]; then
                    cmd="$cmd -p $_VAL_PKG"
                fi
                if [ -n "$_VAL_FLAG" ]; then
                    cmd="$cmd -f $_VAL_FLAG"
                fi
               
                # FIRE THE COMMAND
                local output=$(eval "$cmd" 2>&1)
                if [[ "$output" == *"Error"* ]]; then
                    _bot_say "error" "Launch Failed: $output"
                    return 1
                fi
                return 0
            fi
           
            # 3. View Intent (.VIEW)
            local final_uri=""
           
            if [[ "$_VAL_URI" == *"\$__GO_TARGET"* ]]; then
               
                # ENGINE
                if [ -n "$_VAL_ENGINE" ]; then
                    # ENGINE 套入 $query 轉成 URL
                    local expanded_engine=$(eval echo "$_VAL_ENGINE")
                    
                    _resolve_smart_url "$expanded_engine" "$real_args"
                    final_uri="$__GO_TARGET"
                   
                    if [ "$__GO_MODE" == "neural" ]; then
                         _bot_say "neural" "Searching via Engine: '$real_args'"
                    else
                         _bot_say "launch" "Targeting: '$final_uri'"
                    fi
                else
                    _bot_say "error" "Configuration Error: Missing ENGINE data in CSV."
                    return 1
                fi
            elif [[ "$_VAL_URI" == *"\$query"* ]]; then
                local safe_args="${real_args// /+}"
                final_uri="${_VAL_URI//\$query/$safe_args}"
                _bot_say "neural" "Navigating: '$real_args'"
           
            else
                final_uri="$_VAL_URI"
                _bot_say "launch" "Executing: '$real_args'"
            fi

            local cmd="am start --user 0 -a \"$final_action\""
            
            # 1. -n/-p 角色互換，優先用-p
            if [ -n "$_VAL_PKG" ]; then cmd="$cmd -p \"$_VAL_PKG\""; fi
            
            # 2. -c/-t 從格子注入
            if [ -n "$_VAL_CATE" ]; then cmd="$cmd -c android.intent.category.$_VAL_CATE"; fi
            if [ -n "$_VAL_MIME" ]; then cmd="$cmd -t \"$_VAL_MIME\""; fi

            # 3. 其他旗標
            if [ -n "$final_uri" ]; then cmd="$cmd -d \"$final_uri\""; fi
            if [ -n "$_VAL_FLAG" ]; then cmd="$cmd -f $_VAL_FLAG"; fi
            if [ -n "$_VAL_EX" ]; then cmd="$cmd $_VAL_EX"; fi
            if [ -n "$_VAL_EXTRA" ]; then cmd="$cmd $_VAL_EXTRA"; fi
            
            # FIRE THE COMMAND
            # 第一次發射 ( -p 模式)
            local output=$(eval "$cmd" 2>&1)

            # -p 失敗且有 TARGET，切換 -n 模式重新執行
            if [[ "$output" == *"Error"* || "$output" == *"Activity not found"* || "$output" == *"unable to resolve Intent"* ]]; then
                _bot_say "error" "p mode failed, fallback to n mode..."

                if [ -n "$_VAL_PKG" ] && [ -n "$_VAL_TARGET" ]; then
                    # 重新拼裝
                    local cmd_n="am start --user 0 -a \"$final_action\" -n \"$_VAL_PKG/$_VAL_TARGET\""

                    # 重新導入 URI
                    if [ -n "$final_uri" ]; then cmd_n="$cmd_n -d \"$final_uri\""; fi

                    # 重新加入 -c/-t
                    if [ -n "$_VAL_CATE" ]; then cmd_n="$cmd_n -c android.intent.category.$_VAL_CATE"; fi
                    if [ -n "$_VAL_MIME" ]; then cmd_n="$cmd_n -t \"$_VAL_MIME\""; fi

                    # 重新加入其他旗標
                    if [ -n "$_VAL_FLAG" ]; then cmd_n="$cmd_n -f $_VAL_FLAG"; fi
                    if [ -n "$_VAL_EX" ]; then cmd_n="$cmd_n $_VAL_EX"; fi
                    if [ -n "$_VAL_EXTRA" ]; then cmd_n="$cmd_n $_VAL_EXTRA"; fi

                    _bot_say "launch" "Retrying (n mode): '$real_args'"
                    
                    # FIRE THE COMMAND
                    # 第二次發射 ( -n 模式 )
                    local output_n
                    output_n=$(eval "$cmd_n" 2>&1)
                    
                    # 驗證發射結果
                    _mux_launch_validator "$output_n" "$_VAL_PKG"
                else
                    _bot_say "error" "Fallback failed: No TARGET defined for n mode."
                    return 1
                fi
            fi
            ;;

        "SYS")
            local cmd="am start --user 0"
            
            # 1. 先看 Action (-a) & Data (-d)
            local sys_action="${_VAL_IHEAD}${_VAL_IBODY}"
            if [ -n "$sys_action" ]; then  cmd="$cmd -a \"$sys_action\""; fi
            if [ -n "$_VAL_URI" ]; then cmd="$cmd -d \"$_VAL_URI\""; fi

            # 2. 再看 Category (-c)
            if [ -n "$_VAL_CATE" ]; then cmd="$cmd -c android.intent.category.$_VAL_CATE"; fi

            # 3. 再看 Mime Type (-t)
            if [ -n "$_VAL_MIME" ]; then cmd="$cmd -t \"$_VAL_MIME\""; fi

            # 4. 先後看 Component (-n)，再看 Package (-p)
            if [ -n "$_VAL_PKG" ] && [ -n "$_VAL_TARGET" ]; then
                cmd="$cmd -n \"$_VAL_PKG/$_VAL_TARGET\""
            elif [ -n "$_VAL_PKG" ]; then
                cmd="$cmd -p \"$_VAL_PKG\""
            fi

            # 5. 再看 ex & extra (擴充參數)
            if [ -n "$_VAL_EX" ]; then cmd="$cmd $_VAL_EX"; fi
            if [ -n "$_VAL_EXTRA" ]; then cmd="$cmd $_VAL_EXTRA"; fi

            # 6. 最後看 Flags (-f)
            if [ -n "$_VAL_FLAG" ]; then cmd="$cmd -f $_VAL_FLAG"; fi

            # 執行回報
            _bot_say "system" "System Call: ${sys_action:-Custom}"
            if [ -n "$_VAL_UINAME" ]; then
                 echo -e "\033[1;30m    ›› Node: $_VAL_UINAME\033[0m"
            fi

            # FIRE THE COMMAND (SYS Mode)
            local output_sys
            output_sys=$(eval "$cmd" 2>&1)

            # 驗證結果
            _mux_launch_validator "$output_sys" "${_VAL_PKG:-$_VAL_UINAME}"
            ;;

        *)
            _bot_say "error" "Unknown Signal Type: '$_VAL_TYPE'"
            return 1
            ;;
    esac
    return 0
}

# 神經連接執行器
function command_not_found_handle() {
    local cmd="$1"
    shift
    local args="$@"

    # 第一關：安全檢查 (Security Gate)
    ! _mux_security_gate "$cmd" "$args" && return 0

    # 第二關：Mux-OS 核心執行 (Neural Fire Control)
    _mux_neural_fire_control "$cmd" "$args" && return 0

    # 第三關：真正的未知指令 (The Void)
    _bot_say "error" "Command signature '$cmd' not found in Neural Network."
    
    return 127
}

export PS1="\[\033[1;36m\]Mux\[\033[0m\] \w › "
export PROMPT_COMMAND="tput sgr0; echo -ne '\033[0m'"

# 啟動系統初始化
if [ -z "$MUX_INITIALIZED" ]; then
    if command -v _mux_boot_sequence &> /dev/null; then
        _mux_boot_sequence
    else
        _mux_init
    fi
fi