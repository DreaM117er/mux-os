#!/bin/bash

# 安全檢測：確保核心模組授權載入
if [ -f "$HOME/mux-os/setup.sh" ] && [ ! -f "$HOME/mux-os/.mux_identity" ]; then
    if [ -z "$__MUX_SETUP_ACTIVE" ]; then
        echo -e "\033[1;31m :: SECURITY ALERT :: System Not Initialized.\033[0m"
        return 1 2>/dev/null || exit 1
    fi
fi

if command -v _init_identity &> /dev/null; then _init_identity; fi

[ ! -d "$HOME/storage" ] && { termux-setup-storage; sleep 1; }

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

# 模組註冊表 (Module Registry)
MODULES=("$BOT_MOD" "$UI_MOD" "$IDENTITY_MOD")
for mod in "${MODULES[@]}"; do
    if [ -f "$mod" ]; then source "$mod"; fi
done

# 顏色定義 (Color Definitions)
export C_RESET="\033[0m"
export C_BLACK="\033[1;30m"
export C_RED="\033[1;31m"
export C_GREEN="\033[1;32m"
export C_YELLOW="\033[1;33m"
export C_BLUE="\033[1;34m"
export C_PURPLE="\033[1;35m"
export C_CYAN="\033[1;36m"
export C_WHITE="\033[1;37m"
export C_ORANGE="\033[1;38;5;208m"

# 主題色彩定義 (Theme Colors)
export THEME_MAIN="$C_CYAN"      # 主色調 (Core:藍 / Fac:橘)
export THEME_SUB="$C_WHITE"      # 次要文字
export THEME_DESC="$C_BLACK"     # 註解/灰色文字
export THEME_WARN="$C_YELLOW"    # 警告
export THEME_ERR="$C_RED"        # 錯誤
export THEME_OK="$C_GREEN"       # 成功
export THEME_TXT="$C_WHITE"      # 一般內文

# 瀏覽器網址搜尋引擎
export SEARCH_GOOGLE="https://www.google.com/search?q="
export SEARCH_BING="https://www.bing.com/search?q="
export SEARCH_DUCK="https://duckduckgo.com/?q="
export SEARCH_YT="https://www.youtube.com/results?search_query="
export SEARCH_GITHUB="https://github.com/search?q="

export __GO_TARGET=""
export __GO_MODE=""

# 系統輸入鎖定與解鎖 (System Input Lock/Unlock)
function _system_lock() {
    if [ -t 0 ]; then stty -echo; fi
}

function _system_unlock() {
    if [ -t 0 ]; then stty echo; fi
}

# 安全介面寬度計算 (Safe UI Width Calculation)
function _safe_ui_calc() {
    local width=$(tput cols)
    content_limit=$(( width > 10 ? width - 10 : 2 ))
}

# 無參數檢測輔助函式 (Require No Args)
function _require_no_args() {
    if [ -n "$1" ]; then
        _bot_say "no_args" "Unexpected input: $*"
        return 1
    fi
    return 0
}

# 雙人共舞 (Voice Dispatcher)
function _voice_dispatch() {
    local mood="$1"
    local detail="$2"
    local force_role="$3"

    # 如果有強制指定角色
    if [ "$force_role" == "bot" ]; then
        _bot_say "$mood" "$detail"
        return
    elif [ "$force_role" == "cmd" ]; then
        if command -v _commander_voice &> /dev/null; then
             _commander_voice "$mood" "$detail"
        else
             _bot_say "$mood" "$detail" # Fallback
        fi
        return
    fi

    # 隨機分配
    if [ $((RANDOM % 2)) -eq 0 ]; then
        _bot_say "$mood" "$detail"
    else
        if command -v _commander_voice &> /dev/null; then
            _commander_voice "$mood" "$detail"
        else
            _bot_say "$mood" "$detail"
        fi
    fi
}

# 啟動序列邏輯 (Boot Sequence)
function _mux_boot_sequence() {
    if [ "$MUX_STATUS" == "LOGIN" ]; then
        return 0
    else
        clear
        _draw_logo "gray"
    fi
}

# 主程式初始化 (Main Initialization)
function _mux_init() {
    _system_lock
    _safe_ui_calc
    clear
    _draw_logo "core"
    
    if command -v _system_check &> /dev/null; then
        _system_check # 這個函式需要改動
    fi
    
    if command -v _show_hud &> /dev/null; then
        _show_hud
    fi
    
    export MUX_INITIALIZED="true"
    _system_unlock
    _bot_say "hello"
}

# 重新載入核心模組
function _mux_reload_kernel() {
    _system_lock
    unset MUX_INITIALIZED
    
    local gate_theme="core"
    if [ "$MUX_STATUS" == "DEFAULT" ]; then
        gate_theme="default"
    fi
    
    if command -v _ui_fake_gate &> /dev/null; then
        _ui_fake_gate "$gate_theme"
    fi
    _system_unlock
    exec bash
}

# 強制同步系統狀態
function _mux_force_reset() {
    _system_lock
    _voice_dispatch "system" "Protocol Override: Force Syncing Timeline..." "cmd"
    echo -e "${C_RED} :: WARNING: Obliterating all local modifications.${C_RESET}"
    echo ""
    _system_unlock
    echo -ne "${C_GREEN} :: Confirm system restore? [Y/n]: ${C_RESET}"
    read choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        _system_lock
        cd "$BASE_DIR" || return
        git fetch --all
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
        git reset --hard "origin/$branch"
        chmod +x "$BASE_DIR/"*.sh
        echo ""
        _bot_say "success" "Timeline restored."
        _system_unlock
        sleep 1
        _mux_reload_kernel
    else
        echo -e "${C_BLACK}    ›› Reset canceled.${C_RESET}"
        _system_unlock
        return 1
    fi
}

# 系統更新檢測與執行
function _mux_update_system() {
    _system_lock
    echo -e "${C_YELLOW} :: Checking for updates...${C_RESET}"
    cd "$BASE_DIR" || return
    git fetch origin
    local LOCAL=$(git rev-parse HEAD)
    local REMOTE=$(git rev-parse @{u} 2>/dev/null)
    if [ -z "$REMOTE" ]; then echo "   ›› Remote branch not found."; _system_unlock; return; fi
    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "    ›› System is up-to-date (v$MUX_VERSION). ✅"
        _system_unlock
    else
        echo -e "${C_YELLOW} :: New version available!${C_RESET}"
        echo ""
        _system_unlock
        echo -ne "${C_GREEN} :: Update Mux-OS now? [Y/n]: ${C_RESET}"
        read choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            _system_lock
            if git pull; then sleep 2.2; _mux_reload_kernel; else _bot_say "error" "Update conflict detected."; _system_unlock; fi
        else
            _system_unlock
        fi
    fi
}

# 系統完整性掃描器
function _mux_integrity_scan() {
    return 0
}

# 神經連結部署協議
function _neural_link_deploy() {
    if [ -z "$(git config user.name)" ]; then
         _bot_say "error" "Identity missing. Run 'git config --global user.name \"YourName\"' first."
         return 1
    fi
    echo -e "${THEME_MAIN} :: NEURAL LINK DEPLOYMENT PROTOCOL ::${C_RESET}"
    echo -ne "${THEME_ERR} :: TYPE 'CONFIRM' TO ENGAGE UPLINK: ${C_RESET}"
    read confirm
    if [ "$confirm" != "CONFIRM" ]; then return 1; fi
    _voice_dispatch "system" "Engaging Neural Uplink..."
    cd "$MUX_ROOT" || return 1
    git add .
    git commit -m "Neural Link Deploy $(date '+%Y-%m-%d %H:%M')"
    git push
    if [ $? -eq 0 ]; then 
        _bot_say "success" "Deployment Successful."
    else 
        _bot_say "error" "Uplink destabilized."
    fi
}

function _mux_uplink_sequence() {
    if command -v fzf &> /dev/null; then
        _bot_say "success" "Neural Link is already active. Signal stable."
        return
    fi

    _bot_say "system" "Initializing Neural Bridge Protocol..."
    sleep 0.5
    echo -e "${C_YELLOW} :: Scanning local synaptic ports...${C_RESET}"
    sleep 0.8
    echo -e "${C_CYAN} :: Constructing interface matrix (fzf)...${C_RESET}"
    sleep 0.5

    pkg install fzf -y > /dev/null 2>&1

    if command -v fzf &> /dev/null; then
        echo -e ""
        echo -e "\033[1;35m :: SYNCHRONIZATION COMPLETE :: ${C_RESET}"
        echo -e ""
        sleep 0.5
        _bot_say "neural" "Welcome to the Grid, Commander."
        
        sleep 1.4
        mux reload
    else
        _bot_say "error" "Link failed. Neural rejection detected."
    fi
}

# 神經資料解析器 (Neural Data Parser)
function _mux_neural_data() {
    unset _VAL_CATNO _VAL_COMNO _VAL_CATNAME _VAL_TYPE _VAL_COM \
          _VAL_COM2 _VAL_COM3 _VAL_HUDNAME _VAL_UINAME _VAL_PKG \
          _VAL_TARGET _VAL_IHEAD _VAL_IBODY _VAL_URI _VAL_MIME \
          _VAL_CATE _VAL_FLAG _VAL_EX _VAL_EXTRA _VAL_ENGINE

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
    
    _VAL_ENGINE=${_VAL_ENGINE//$'\rT'/}
    return 0
}

# 智慧網址解析器 (Smart URL Resolver)
function _resolve_smart_url() {
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
        echo -ne "${C_GREEN} :: Install from Google Play? [Y/n]: ${C_RESET}"
        read choice
        
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            _bot_say "loading" "Redirecting to Store..."
            am start -a android.intent.action.VIEW -d "market://details?id=$pkg" >/dev/null 2>&1
        else
            echo -e "${C_BLACK}    ›› Canceled.${C_RESET}"
            return 1
        fi
        return 1
    fi
    return 0
}

# 安全過濾層 (Security Layer)
function _mux_security_gate() {
    local cmd="$1"
    local all_args="$@"
    
    # 1. 絕對違禁指令 (Root/Filesystem)
    if [[ "$cmd" =~ ^(su|tsu|sudo|mount|umount)$ ]]; then
        _bot_say "error" "Administrator access denied. (Non-Root Protocol Active)"
        return 1
    fi

    # 2. PM (Package Manager) 寫入攔截
    if [[ "$cmd" == "pm" ]]; then
        if [[ "$all_args" =~ (disable|hide|enable|unhide) ]]; then
            _bot_say "error" "Package modification is locked by Manufacturer."
            return 1
        fi
    fi

    # 3. AM (Activity Manager) 軍火管制 (Sanitizer)
    if [[ "$cmd" == "am" ]]; then
        # 定義黑名單：
        local forbidden_sigs="force-stop|kill|kill-all|hang|crash|profile|dumpheap|monitor|instrument|bug-report|track-memory"
        
        if [[ "$all_args" =~ ($forbidden_sigs) ]]; then
            _bot_say "error" "AM Command Restricted: Unstable or Dev-only directive detected."
            # 顯示被攔截的具體關鍵字
            local blocked=$(echo "$all_args" | grep -oE "$forbidden_sigs" | head -n 1)
            echo -e "${C_BLACK}    ›› Blocked payload: '$blocked'${C_RESET}"
            return 1
        fi
    fi

    return 0
}

# 神經火控系統 - Neural Fire Control
function _mux_neural_fire_control() {
    if [ "$MUX_STATUS" != "LOGIN" ]; then
        return 127
    fi

    local input_signal="$1" # COM
    local input_sub="$2" # COM2 (Candidate)
    local input_args="${*:2}" # All args starting from $2

    if [ "$MUX_MODE" == "FAC" ]; then
        if command -v _factory_mask_apps &> /dev/null; then
            _factory_mask_apps "$input_signal" "$input_sub" || return 127
        fi
    fi
   
    if ! _mux_neural_data "$input_signal" "$input_sub"; then
        
        local recovered=0
        if [ -n "$input_sub" ]; then
            if _mux_neural_data "$input_signal" ""; then
                recovered=1
            fi
        fi

        if [ "$recovered" -eq 0 ]; then
            _bot_say "error" "'$input_signal' command not found."
            return 127
        fi
    fi

    integrity_flag=$(echo "$_VAL_COM3" | tr -d ' "')

    if [ "$integrity_flag" == "F" ]; then
        echo ""
        _bot_say "error" "NEURAL LINK SEVERED :: Integrity Failure (Code: F)"
        echo -e "${C_BLACK} ›› Diagnosis: Critical parameter missing or malformed.${C_RESET}"
        echo -e "${C_BLACK} ›› Protocol : Execution blocked by Safety Override.${C_RESET}"
        echo -e "${C_BLACK} ›› Action : Use 'factory' to repair this node.${C_RESET}"
        echo ""
        return 127
    elif [ "$integrity_flag" == "W" ]; then
        echo ""
        _bot_say "warn" "NEURAL LINK UNSTABLE :: Parameter Anomaly (Code: W)"
        echo -e "${C_BLACK} ›› Diagnosis: Non-critical structure mismatch detected.${C_RESET}"
        echo -e "${C_BLACK} ›› Protocol : Bypassing safety lock... Executing with caution.${C_RESET}"
        sleep 0.8
    fi

    local cate_arg=""

    if [ -n "$_VAL_CATE" ]; then
        cate_arg=" -c android.intent.category.$_VAL_CATE"
    fi

    case "$_VAL_TYPE" in
        "NA")
            # 明確指定外部呼叫
            if [ -z "$_VAL_COM2" ]; then
                _require_no_args "$input_args" || return 1
                _launch_android_app
            else
                _require_no_args "${*:3}" || return 1
                _launch_android_app
            fi
            ;;

        "NB")
            # 外部呼叫需要fallback
            local real_args=""
            if [ -n "$_VAL_COM2" ]; then
                real_args="${*:3}"
            else
                real_args="$input_args"
            fi
            
            # 參數檢查：跳出 or 跳轉
            if [ -z "$real_args" ]; then
                if [ -n "$_VAL_PKG" ] && [ -n "$_VAL_TARGET" ]; then
                    _VAL_URI=""
                    _launch_android_app
                    return 0
                fi
                _bot_say "error" "Strict Protocol '$_VAL_COM': Parameter required."
                return 1
            fi
            
            # 安全檢查：Intent 結構
            if [ -z "$_VAL_IHEAD" ] || [ -z "$_VAL_IBODY" ]; then
                _bot_say "error" "System Integrity: Malformed Intent (Missing HEAD/BODY)."
                return 1
            fi
            local final_action="${_VAL_IHEAD}${_VAL_IBODY}"

            # .WEB_SEARCH
            if [[ "$final_action" == *".WEB_SEARCH"* ]]; then
                local raw_input=$(echo "$real_args" | sed 'y/。．/../' | sed 's/　/ /g')
                local safe_query="${raw_input//\"/\\\"}"

                _bot_say "neural" "Payload: Raw Search ›› '$safe_query'"

                local cmd="am start --user 0 -a \"$final_action\""

                if [ -n "$_VAL_PKG" ]; then cmd="$cmd -p \"$_VAL_PKG\""; fi
                if [ -n "$_VAL_FLAG" ]; then cmd="$cmd -f $_VAL_FLAG"; fi
                if [ -n "$_VAL_CATE" ]; then cmd="$cmd -c android.intent.category.$_VAL_CATE"; fi
                
                if [ -n "$_VAL_EX" ]; then
                    local injected_ex="${_VAL_EX//\$query/$safe_query}"
                    cmd="$cmd $injected_ex"
                fi

                if [ -n "$_VAL_EXTRA" ]; then
                    local injected_extra="${_VAL_EXTRA//\$query/$safe_query}"
                    cmd="$cmd $injected_extra"
                fi  

                # FIRE THE COMMAND
                local output=$(eval "$cmd" 2>&1)

                # 不要試圖去更動 system 裡的參數，後果自負
                if [[ "$output" == *"Error"* ]]; then
                    _bot_say "error" "Launch Failed: $output"
                    return 1
                fi
                return 0
            fi
           
            # .VIEW
            local final_uri=""
           
            # 解析 URI 邏輯
            if [[ "$_VAL_URI" == *"\$__GO_TARGET"* ]]; then
                if [ -n "$_VAL_ENGINE" ]; then
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

            # 'p' mode (Package Locked)
            local cmd="am start --user 0 -a \"$final_action\""
            
            if [ -n "$_VAL_PKG" ]; then cmd="$cmd -p \"$_VAL_PKG\""; fi
            
            # 參數注入
            if [ -n "$_VAL_CATE" ]; then cmd="$cmd -c android.intent.category.$_VAL_CATE"; fi
            if [ -n "$_VAL_MIME" ]; then cmd="$cmd -t \"$_VAL_MIME\""; fi
            if [ -n "$final_uri" ]; then cmd="$cmd -d \"$final_uri\""; fi
            if [ -n "$_VAL_FLAG" ]; then cmd="$cmd -f $_VAL_FLAG"; fi
            if [ -n "$_VAL_EX" ]; then cmd="$cmd $_VAL_EX"; fi
            if [ -n "$_VAL_EXTRA" ]; then cmd="$cmd $_VAL_EXTRA"; fi
            
            # FIRST FIRE THE COMMAND
            local output=$(eval "$cmd" 2>&1)
            
            # 檢查結果：如果成功，直接返回
            if [[ "$output" != *"Error"* && "$output" != *"Activity not found"* && "$output" != *"unable to resolve Intent"* ]]; then
                return 0
            fi

            # 'i' mode (Pure Intent / Unlock)
            if [ -n "$final_uri" ]; then
                _bot_say "error" "'p' mode rejected. Try for 'i' mode."

                # 重新拼裝：移除 -p, -n
                local cmd_i="am start --user 0 -a \"$final_action\" -d \"$final_uri\""
                
                # 補回參數
                if [ -n "$_VAL_CATE" ]; then cmd_i="$cmd_i -c android.intent.category.$_VAL_CATE"; fi
                if [ -n "$_VAL_MIME" ]; then cmd_i="$cmd_i -t \"$_VAL_MIME\""; fi
                if [ -n "$_VAL_FLAG" ]; then cmd_i="$cmd_i -f $_VAL_FLAG"; fi
                if [ -n "$_VAL_EX" ]; then cmd_i="$cmd_i $_VAL_EX"; fi
                if [ -n "$_VAL_EXTRA" ]; then cmd_i="$cmd_i $_VAL_EXTRA"; fi

                # SECOND FIRE THE COMMAND
                local output_i=$(eval "$cmd_i" 2>&1)

                if [[ "$output_i" != *"Error"* && "$output_i" != *"Activity not found"* && "$output_i" != *"unable to resolve Intent"* ]]; then
                    _bot_say "launch" "Recovered via 'i' mode: '$real_args'"
                    return 0
                else
                    _bot_say "error" "'i' mode failed. Engaging 'n' mode."
                fi
            else
                _bot_say "error" "'p' mode failed. Engaging 'n' mode."
            fi

            # 'n' mode (Component Locked)
            if [ -n "$_VAL_PKG" ] && [ -n "$_VAL_TARGET" ]; then
                # 重新拼裝
                local cmd_n="am start --user 0 -a \"$final_action\" -n \"$_VAL_PKG/$_VAL_TARGET\""

                if [ -n "$final_uri" ]; then cmd_n="$cmd_n -d \"$final_uri\""; fi
                if [ -n "$_VAL_CATE" ]; then cmd_n="$cmd_n -c android.intent.category.$_VAL_CATE"; fi
                if [ -n "$_VAL_MIME" ]; then cmd_n="$cmd_n -t \"$_VAL_MIME\""; fi
                if [ -n "$_VAL_FLAG" ]; then cmd_n="$cmd_n -f $_VAL_FLAG"; fi
                if [ -n "$_VAL_EX" ]; then cmd_n="$cmd_n $_VAL_EX"; fi
                if [ -n "$_VAL_EXTRA" ]; then cmd_n="$cmd_n $_VAL_EXTRA"; fi

                _bot_say "launch" "Retrying ('n' mode): '$real_args'"
                
                # THIRD FIRE THE COMMAND
                local output_n=$(eval "$cmd_n" 2>&1)
                
                # 最終驗證
                _mux_launch_validator "$output_n" "$_VAL_PKG"
                return 0
            else
                _bot_say "error" "All Protocols Failed: No TARGET for 'n' mode fallback."
                return 1
            fi
            ;;

        "SYS")
            # SYS 單次執行就可
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
            _bot_say "system" "System Call: $_VAL_UINAME"

            # FIRE THE COMMAND (SYS Mode)
            local output_sys
            output_sys=$(eval "$cmd" 2>&1)

            # 驗證結果
            _mux_launch_validator "$output_sys" "Node: ${_VAL_PKG:-$_VAL_UINAME}"
            ;;

        *)
            _bot_say "error" "Unknown Signal Type: '$_VAL_TYPE'"
            return 1
            ;;
    esac
    return 0
}

# 直接鎖定系統 ROOT 指令
function su()     { _mux_security_gate "su" "$@"; return 1; }
function tsu()    { _mux_security_gate "tsu" "$@"; return 1; }
function sudo()   { _mux_security_gate "sudo" "$@"; return 1; }
function mount()  { _mux_security_gate "mount" "$@"; return 1; }
function umount() { _mux_security_gate "umount" "$@"; return 1; }

# PM 指令過濾器
function pm() {
    ! _mux_security_gate "pm" "$@" && return 1
    command pm "$@"
}

# 機體狀態掃描儀 (System Integrity Scanner)
function _core_system_scan() {
    local mode="${1:-silent}"
    local error_count=0
    local report_lines=""
    
    # 定義掃描目標
    local scan_targets=("$SYSTEM_MOD" "$VENDOR_MOD" "$APP_MOD")
    
    # 開始掃描
    for target in "${scan_targets[@]}"; do
        if [ ! -f "$target" ]; then
            continue
        fi

        local target_name=$(basename "$target")
        
        # 啟動 AWK 邏輯引擎
        local scan_result=$(awk -v FPAT='([^,]*)|("[^"]+")' '
            NR > 1 {
                # 1. 資料清洗
                type = $4;  gsub(/^"|"$/, "", type);  gsub(/^[ \t]+|[ \t]+$/, "", type)
                com  = $5;  gsub(/^"|"$/, "", com);   gsub(/^[ \t]+|[ \t]+$/, "", com)
                pkg  = $10; gsub(/^"|"$/, "", pkg);   gsub(/^[ \t]+|[ \t]+$/, "", pkg)
                tgt  = $11; gsub(/^"|"$/, "", tgt);   gsub(/^[ \t]+|[ \t]+$/, "", tgt)
                ihead= $12; gsub(/^"|"$/, "", ihead); gsub(/^[ \t]+|[ \t]+$/, "", ihead)
                ibody= $13; gsub(/^"|"$/, "", ibody); gsub(/^[ \t]+|[ \t]+$/, "", ibody)
                
                err = ""

                # 2. 邏輯判斷 (Primitive Checks)
                if (type == "NA") {
                    # NA: PKG 與 TARGET 必須存在
                    if (pkg == "" || tgt == "") {
                        err = "Structural Breach (Missing PKG/TARGET)"
                    }
                }
                else if (type == "NB") {
                    # NB: IHEAD 與 IBODY 必須存在
                    if (ihead == "" || ibody == "") {
                        err = "Neural Pathway Broken (Missing INTENT)"
                    } else {
                        # IBODY 必須是大寫 (忽略開頭的點)
                        check_body = ibody
                        sub(/^\./, "", check_body) # 移除開頭的 .
                        if (check_body ~ /[a-z]/) {
                            err = "Protocol Mismatch (IBODY must be UPPERCASE)"
                        }
                    }
                }
                
                # 3. 輸出錯誤 (格式: COM_NAME|ERROR_MSG)
                if (err != "") {
                    print com "_err|" err
                }
            }
        ' "$target")

        # 解析結果
        if [ -n "$scan_result" ]; then
            while IFS='|' read -r node_name error_msg; do
                error_count=$((error_count + 1))
                if [ "$mode" == "manual" ]; then
                    # node_name 現在會顯示為 "edge_err"
                    report_lines+="${THEME_DESC}    [${target_name}] ${THEME_WARN}${node_name}${C_RESET} : ${THEME_ERR}${error_msg}${C_RESET}\n"
                fi
            done <<< "$scan_result"
        fi
    done

    # 結果回饋
    if [ "$error_count" -gt 0 ]; then
        # [異常狀態]
        if [ "$mode" == "manual" ]; then
            echo -e "${THEME_ERR} :: SYSTEM INTEGRITY COMPROMISED ::${C_RESET}"
            echo -e "${THEME_DESC}    Critical Faults: ${THEME_ERR}${error_count}${C_RESET}"
            echo -e ""
            echo -e "${THEME_WARN} :: DAMAGE CONTROL REPORT ::${C_RESET}"
            echo -e "$report_lines"
        else
            # 登入時的語音警告
            _bot_say "warn" "Hull damage detected. ${error_count} micro-fractures found in logic gate."
        fi
        return 1
    else
        # [正常狀態]
        if [ "$mode" == "manual" ]; then
            echo -e "${THEME_OK} :: SYSTEM DIAGNOSTIC COMPLETE ::${C_RESET}"
            echo -e "${THEME_DESC}    Neural Integrity: 100%${C_RESET}"
            echo -e "${THEME_DESC}    Logic Gates: Stable${C_RESET}"
            echo -e ""
            _bot_say "success" "All systems green. Ready for combat."
        fi
        return 0
    fi
}

# 登入系統 - Commander Login
function _mux_pre_login() {
    if [ "$MUX_STATUS" != "DEFAULT" ]; then
        echo -e "${F_BLE} :: System already active, Commander.${C_RESET}"
        return 1
    fi

    clear
    _draw_logo "gray" # 確保Logo在視覺中心

    _system_lock
    echo -e "${THEME_WARN} :: SECURITY CHECKPOINT ::${C_RESET}"
    
    sleep 0.2
    echo -e "${THEME_DESC}    ›› Initializing Biometeric Scan...${C_RESET}"
    sleep 0.6
    _system_unlock

    echo ""
    echo -ne "${THEME_SUB} :: Commander Identity: ${C_RESET}" 
    read input_id

    _system_lock
    echo -e "${THEME_DESC}    ›› Verifying Hash Signature...${C_RESET}"
    sleep 0.6
    
    local identity_valid=0
    if [ -f "$MUX_ROOT/.mux_identity" ]; then
        local REAL_ID=$(grep "MUX_ID=" "$MUX_ROOT/.mux_identity" | cut -d'=' -f2)
        if [ "$input_id" == "$REAL_ID" ]; then
            identity_valid=1
        fi
    else
        identity_valid=1
    fi

    if [ "$identity_valid" -ne 1 ]; then
        sleep 0.5
        echo ""
        echo -e "${THEME_ERR} :: ACCESS DENIED :: Identity Mismatch.${C_RESET}"
        sleep 0.5
        _system_unlock
        return 1
    fi

    sleep 0.4
    echo ""
    echo -e "${THEME_OK} :: IDENTITY CONFIRMED :: ${C_RESET}"
    sleep 0.6
    echo ""
    echo -e "${THEME_WARN} :: UNLOCKING NEURAL INTERFACE... ${C_RESET}"
    sleep 0.8
    echo -e "${THEME_DESC}    ›› Mount Point: /dev/mux_core${C_RESET}"
    sleep 0.2
    echo -e "${THEME_DESC}    ›› Link Status: Stable${C_RESET}"
    sleep 0.5

    _core_system_scan "silent"
    
    # 寫入 LOGIN 狀態
    cat > "$MUX_ROOT/.mux_state" <<EOF
MUX_MODE="MUX"
MUX_STATUS="LOGIN"
EOF

    echo ""
    echo -e "${THEME_OK} :: WELCOME BACK, COMMANDER :: ${C_RESET}"
    sleep 1.2
    
    MUX_STATUS="LOGIN"
    unset MUX_INITIALIZED
    _mux_reload_kernel
}

# 登出系統 - Commander Logout
function _mux_set_logout() {
    echo ""
    echo -e "${THEME_WARN} :: WARNING: NEURAL DISCONNECT SEQUENCE ::${C_RESET}"
    echo -e "${THEME_DESC}    This will terminate your current session and seal the cockpit.${C_RESET}"
    echo ""
    echo -ne "${THEME_ERR} :: TYPE 'CONFIRM' TO DISENGAGE: ${C_RESET}"
    read confirm

    if [ "$confirm" != "CONFIRM" ]; then
        echo ""
        _bot_say "error" "Disconnection aborted. Neural Link stable."
        return 1
    fi

    _system_lock
    echo ""
    _bot_say "success" "Terminating Neural Link..."
    
    # 模擬系統關閉的逐層斷電
    local shutdown_steps=("Disengaging Motor Functions..." "Unmounting Virtual Drives..." "Saving Memory Stack..." "Sealing Cockpit Hatch...")
    
    for step in "${shutdown_steps[@]}"; do
        echo -e "${THEME_DESC}    ›› $step${C_RESET}"
        sleep 0.6
    done
    
    sleep 0.6
    echo ""
    echo -e "${THEME_WARN} :: SYSTEM OFFLINE :: See you space cowboy.${C_RESET}"
    
    cat > "$MUX_ROOT/.mux_state" <<EOF
MUX_MODE="MUX"
MUX_STATUS="DEFAULT"
EOF

    MUX_STATUS="DEFAULT"
    sleep 1.9
    _mux_reload_kernel
}

# 工廠前置驗證協議 (Pre-Flight Auth)
function _core_pre_factory_auth() {
    local origin_status="$MUX_STATUS"
    clear
    _draw_logo "gray"
    
    _system_lock
    echo -e "${C_ORANGE} :: SECURITY CHECKPOINT ::${C_RESET}"
    sleep 0.2
    echo -e "${THEME_DESC}    ›› Identity Verification Required.${C_RESET}"
    sleep 0.4
    echo ""
    
    _system_unlock
    echo -ne "${THEME_SUB} :: Commander ID: ${C_RESET}" 
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

    echo -ne "${THEME_WARN} :: CONFIRM IDENTITY (Type 'CONFIRM'): ${C_RESET}"
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
    echo -e "${THEME_DESC} :: Verifying Neural Signature... ${C_RESET}"
    sleep 0.8
    echo ""
    echo -e "${THEME_OK} :: ACCESS GRANTED :: ${C_RESET}"
    sleep 0.5
    echo ""
    echo -e "${THEME_DESC} :: Scanning Combat Equipment... ${C_RESET}"
    sleep 1
    echo ""
    if ! command -v fzf &> /dev/null; then
        echo -e "\n${THEME_ERR} :: EQUIPMENT MISSING :: ${C_RESET}"
        sleep 0.5
        _core_eject_sequence "Neural Link (fzf) Required."
        return 1
    else
        echo -e "\r${THEME_OK} :: EQUIPMENT CONFIRM :: ${C_RESET}"
        sleep 0.5
    fi

    echo ""
    echo -e "${THEME_ERR} :: WARNING: FACTORY PROTOCOL :: ${C_RESET}"
    echo -e "${THEME_DESC}    1. Modifications are permanent.${C_RESET}"
    echo -e "${THEME_DESC}    2. Sandbox Environment Active (.temp).${C_RESET}"
    echo -e "${THEME_DESC}    3. Core 'mux' commands are ${THEME_ERR}LOCKED${C_RESET}.${C_RESET}"
    echo -e "${THEME_DESC}    4. App launches are ${THEME_ERR}LOCKED${C_RESET}.${C_RESET}"
    echo -e "${THEME_DESC}    5. You are responsible for system stability.${C_RESET}"
    echo ""
    
    _system_unlock
    echo -ne "${THEME_WARN} :: Proceed? [Y/n]: ${C_RESET}"
    read choice
    
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        _core_eject_sequence "User Aborted."
        return 1
    fi
    
    _system_lock
    local steps=("Injecting Logic..." "Desynchronizing Core..." "Loading Arsenal..." "Entering Factory...")
    for step in "${steps[@]}"; do
        echo -e "${THEME_DESC}    ›› $step${C_RESET}"
        sleep 0.2
    done
    sleep 0.5
    
    if command -v _ui_fake_gate &> /dev/null; then
        _ui_fake_gate "factory"
    fi

    local entry_point="HANGAR"
    if [ "$origin_status" == "LOGIN" ]; then
        entry_point="COCKPIT"
    fi

    cat > "$MUX_ROOT/.mux_state" <<EOF
MUX_MODE="FAC"
MUX_STATUS="LOGIN"
MUX_ENTRY_POINT="$entry_point"
EOF

    unset MUX_INITIALIZED
    exec bash
}

# 彈射序列 (The Ejection - Core Simulation)
function _core_eject_sequence() {
    local reason="$1"
   
    _system_lock
    echo ""
    echo -e "${THEME_ERR} :: ACCESS DENIED :: ${reason}${C_RESET}"
    sleep 0.8
    echo ""

    if [ "$current_status" == "LOGIN" ]; then
        # 駕駛艙彈射
        echo -e "${THEME_ERR} :: CRITICAL: Cockpit Security Breach.${C_RESET}"
        sleep 0.4
        echo -e "${THEME_ERR} :: Neural Link Unstable.${C_RESET}"
        sleep 0.6
        echo -e "${THEME_ERR} :: EMERGENCY EJECTION SYSTEM: ARMED.${C_RESET}"
    else
        # 人員驅離
        echo -e "${THEME_ERR} :: SECURITY VIOLATION DETECTED.${C_RESET}"
        sleep 0.4
        echo -e "${THEME_ERR} :: Hangar Defense System Engaged.${C_RESET}"
        sleep 0.6
        echo -e "${THEME_ERR} :: INITIATING FORCIBLE REMOVAL.${C_RESET}"
    fi
    
    sleep 1
    
    for i in {3..1}; do
        echo -e "${THEME_DESC}    ›› Ejection in $i...${C_RESET}"
        sleep 0.99
    done

    echo -e ""
    _bot_factory_personality "eject"
    sleep 1.9

    cat > "$MUX_ROOT/.mux_state" <<EOF
MUX_MODE="MUX"
MUX_STATUS="DEFAULT"
EOF

    if command -v _ui_fake_gate &> /dev/null; then
        _ui_fake_gate "default"
    fi

    _safe_ui_calc
    unset MUX_INITIALIZED
    exec bash
}


# Mux-OS 指令入口 - Core Command Entry
# === Mux ===

# : Core Command Entry
function mux() {
    local cmd="$1"
    if [ "$MUX_MODE" == "FAC" ]; then
        _bot_say "error" "Core commands disabled during Factory session."
        return 1
    fi
    
    if [ -z "$cmd" ]; then
        if [ "$MUX_STATUS" == "LOGIN" ]; then
            _voice_dispatch "hello"
        else
            if [ $((RANDOM % 3)) -eq 0 ]; then
                 if command -v _commander_voice &> /dev/null; then
                    _commander_voice "default_idle"
                 fi
            fi
        fi
        return
    fi

    if [ "$MUX_STATUS" != "LOGIN" ]; then
        case "$cmd" in
            "login"|"setup"|"help"|"status"|"sts"|"info"|"reload"|"reset"|"factory"|"tofac"|"driveto"|"update"|"drive2")
                # 放行
                ;;
            *)
                # 指揮官語音插入
                if [ $((RANDOM % 3)) -eq 0 ]; then
                     if command -v _commander_voice &> /dev/null; then
                        _commander_voice "default_idle"
                     fi
                fi
                return 1
                ;;
        esac
    fi

    case "$cmd" in
        # : Login Sequence
        "login")
            _mux_pre_login
            ;;

        # : Logout Sequence
        "logout")
            _mux_set_logout
            ;;

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
                echo -e "\n${C_GREEN} :: Neural Link (fzf) Status: ${C_WHITE}ONLINE${C_RESET} ✅"
                _bot_say "success" "Link is stable, Commander."
                return
            fi
            echo -e ""
            echo -e "${C_YELLOW} :: Initialize Neural Link Protocol? ${C_RESET}"
            echo -e ""
            echo -ne "${C_GREEN} :: Authorize construction? [Y/n]: ${C_RESET}"
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
                current_branch="Unknown (main)"
            fi
            echo -e "${C_PURPLE} :: Mux-OS System Status ${C_RESET}"
            echo -e "${THEME_SUB}    ›› Core Protocol :${C_RESET} ${THEME_WARN}v$MUX_VERSION${C_RESET}"
            echo -e "${THEME_SUB}    ›› Current Meta  :${C_RESET} ${THEME_OK}$current_branch${C_RESET}"
            echo -e "${THEME_SUB}    ›› Last Uplink   :${C_RESET} ${THEME_DESC}$last_commit${C_RESET}"
            ;;
        
        # : Neural Link Deploy
        "deploy")
            _neural_link_deploy
            ;;

        # : System Integrity Scan
        "check"|"scan")
            _core_system_scan "manual"
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
            _voice_dispatch "system" "Reloading Kernel Sequence..."
            sleep 0.5
            _mux_reload_kernel
            ;;

        # : Force System Sync
        "reset")
            _mux_force_reset
            if [ $? -eq 0 ]; then
                _mux_reload_kernel
            fi
            ;;

        # : Multiverse Suit Drive
        "driveto"|"drive2")
            if [ "$MUX_STATUS" == "LOGIN" ]; then
                 _bot_say "error" "Interlock Active: Cockpit is sealed."
                 echo -e "${C_BLACK}    ›› Protocol Violation: Cannot switch unit while piloted.${C_RESET}"
                 echo -e "${C_BLACK}    ›› Action Required : Execute 'mux logout' to disengage.${C_RESET}"
                 return 1
            fi

            # 2. 掃描機體 (Branch Selection)
            echo -e "${C_BLACK} :: Scanning Multiverse Coordinates (Hangar Walk)...${C_RESET}"
            git fetch --all >/dev/null 2>&1
            
            # FZF 選單
            local target_branch=$(git branch -r | grep -v '\->' | sed 's/origin\///' | fzf --ansi \
                --height=10 \
                --layout=reverse \
                --border=bottom \
                --header=" :: Mobile Suit State ::" \
                --prompt=" :: Select Unit to Drive › " \
                --pointer="››" \
                --info=hidden \
                --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                --color=info:yellow,prompt:gray,pointer:red,marker:green,border:blue,header:240 \
                --bind="resize:clear-screen"
            )
            
            target_branch="${target_branch// /}"
            if [ -z "$target_branch" ]; then _bot_say "warp" "fail"; return 1; fi

            # 語音回饋
            local warp_type="start_local"
            if [ "$target_branch" == "main" ] || [ "$target_branch" == "master" ]; then 
                warp_type="home"
            elif [[ "$target_branch" != *"$(whoami)"* ]]; then 
                warp_type="start_remote"
            fi
            _voice_dispatch "warp_ready" "" "cmd"
            _bot_say "warp" "$warp_type" "$target_branch"
            
            # 3. 執行換乘 (Checkout)
            if [ -n "$(git status --porcelain)" ]; then 
                git stash push -m "Auto-stash before drive sequence"
            fi
            
            git checkout "$target_branch" 2>/dev/null
            
            # 4. 系統重載 (Reload)
            if [ $? -eq 0 ]; then
                echo -e "${C_YELLOW} :: Initializing New Unit Core...${C_RESET}"
                sleep 1.0
                
                # 賦予新機體執行權限
                if [ -d "$MUX_ROOT" ]; then chmod +x "$MUX_ROOT/"*.sh 2>/dev/null; fi
                
                if command -v _mux_reload_kernel &> /dev/null; then
                    _mux_reload_kernel
                else
                    exec bash
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
            echo -e "${C_YELLOW} :: Unknown Directive: '$cmd'.${C_RESET}"
            ;;
    esac
}

# 神經連接執行器
function command_not_found_handle() {
    local cmd="$1"
    shift
    ! _mux_security_gate "$cmd" "$@" && return 0

    if [ "$MUX_STATUS" != "LOGIN" ]; then
        return 127
    fi

    _mux_neural_fire_control "$cmd" "$@" && return 0
    return 127
}

# 讀取門禁卡 (Mux State)
if [ -f "$MUX_ROOT/.mux_state" ]; then
    source "$MUX_ROOT/.mux_state"
else
    MUX_MODE="MUX"
    MUX_STATUS="DEFAULT"
fi

case "$MUX_MODE" in
    "FAC")
        if [ -f "$MUX_ROOT/factory.sh" ]; then
            THEME_MAIN="$C_ORANGE"

            source "$MUX_ROOT/factory.sh"

            if command -v _factory_system_boot &> /dev/null; then
                _factory_system_boot
            elif command -v _fac_init &> /dev/null; then
                _fac_init
            else
                echo -e "${C_RED} :: FATAL :: Factory Core Not Found.${C_RESET}"
            fi

            return 0 2>/dev/null || exit 0
        fi
        ;;
        
    "MUX")
        THEME_MAIN="$C_CYAN"

        if [ "$MUX_STATUS" == "LOGIN" ]; then
            export PS1="\[\033[1;36m\]Mux\[\033[0m\] \w › "
        else
            export PS1="\[\033[1;30m\]Mux\[\033[0m\] \w › "
        fi
        
        export PROMPT_COMMAND="tput sgr0; echo -ne '\033[0m'"
        ;;
        
    *)
        if command -v _ui_fake_gate &> /dev/null; then _ui_fake_gate "core"; fi
        
        cat > "$MUX_ROOT/.mux_state" <<EOF
MUX_MODE="MUX"
MUX_STATUS="LOGIN"
EOF

        exec bash
        ;;
esac

# 啟動系統初始化
if [ -z "$MUX_INITIALIZED" ]; then
    if command -v _mux_boot_sequence &> /dev/null; then
        _mux_boot_sequence
    fi

    if [ "$MUX_STATUS" == "LOGIN" ]; then
        if command -v _mux_init &> /dev/null; then 
            _mux_init
        fi
    fi
fi