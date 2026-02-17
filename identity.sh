#!/bin/bash
# identity.sh - Mux-OS 身份識別及等級系統模組

export MUX_ROOT="${MUX_ROOT:-$HOME/mux-os}"
export IDENTITY_FILE="$MUX_ROOT/.mux_identity"

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

# 存檔核心 (Identity Save Protocol)
function _save_identity() {
    cat > "$IDENTITY_FILE" <<EOF
MUX_ID="$MUX_ID"
MUX_ROLE="$MUX_ROLE"
MUX_ACCESS_LEVEL="$MUX_ACCESS_LEVEL"
MUX_CREATED_AT="$MUX_CREATED_AT"
MUX_LEVEL="${MUX_LEVEL:-1}"
MUX_XP="${MUX_XP:-0}"
MUX_NEXT_XP="${MUX_NEXT_XP:-2000}"
MUX_BADGES="${MUX_BADGES:-INIT}"
MUX_DATE="${MUX_DATE}"
MUX_LF="${MUX_LF}"
MUX_LB="${MUX_LB}"
HEAP_ALLOCATION_IDX="${HEAP_ALLOCATION_IDX:-0}"
IO_WRITE_CYCLES="${IO_WRITE_CYCLES:-0}"
KERNEL_PANIC_OFFSET="${KERNEL_PANIC_OFFSET:-0}"
UPLINK_LATENCY_MS="${UPLINK_LATENCY_MS:-0}"
ENTROPY_DISCHARGE="${ENTROPY_DISCHARGE:-0}"
NEURAL_SYNAPSE_FIRING="${NEURAL_SYNAPSE_FIRING:-0}"
TEST_LAUNCH_COUNT="${TEST_LAUNCH_COUNT:-0}"
WARP_JUMP_COUNT="${WARP_JUMP_COUNT:-0}"
LOGIN_COUNT="${LOGIN_COUNT:-0}"
EJECTION_COUNT="${EJECTION_COUNT:-0}"
SUDO_ATTEMPT_COUNT="${SUDO_ATTEMPT_COUNT:-0}"
HELP_ACCESS_COUNT="${HELP_ACCESS_COUNT:-0}"
FACTORY_ABUSE_COUNT="${FACTORY_ABUSE_COUNT:-0}"
EOF
}

# 初始化身份文件 (Default to Unknown)
function _init_identity() {
if [ ! -f "$IDENTITY_FILE" ]; then
        # 全新用戶
        MUX_ID="Unknown"
        MUX_ROLE="GUEST"
        MUX_ACCESS_LEVEL="0"
        MUX_CREATED_AT=$(date +%s)
        MUX_LEVEL=1
        MUX_XP=0
        MUX_NEXT_XP=2000
        MUX_BADGES="INIT"
        MUX_DATE=$(date +%s)
        MUX_LF=$MUX_DATE
        MUX_LB=""
        HEAP_ALLOCATION_IDX=0
        IO_WRITE_CYCLES=0
        KERNEL_PANIC_OFFSET=0
        UPLINK_LATENCY_MS=0
        ENTROPY_DISCHARGE=0
        NEURAL_SYNAPSE_FIRING=0
        EJECTION_COUNT=0
        SUDO_ATTEMPT_COUNT=0
        HELP_ACCESS_COUNT=0
        FACTORY_ABUSE_COUNT=0
        TEST_LAUNCH_COUNT=0
        WARP_JUMP_COUNT=0
        LOGIN_COUNT=0
        
        _save_identity
        return
    fi
    
    source "$IDENTITY_FILE"
    
    # 舊用戶遷移
    if [ -z "$MUX_DATE" ]; then
        MUX_DATE=${MUX_DATE:-$(date +%s)}
        MUX_LF=${MUX_LF:-$MUX_DATE}
        MUX_LB=${MUX_LB:-""}
        HEAP_ALLOCATION_IDX=${HEAP_ALLOCATION_IDX:-0}
        IO_WRITE_CYCLES=${IO_WRITE_CYCLES:-0}
        KERNEL_PANIC_OFFSET=${KERNEL_PANIC_OFFSET:-0}
        UPLINK_LATENCY_MS=${UPLINK_LATENCY_MS:-0}
        ENTROPY_DISCHARGE=${ENTROPY_DISCHARGE:-0}
        NEURAL_SYNAPSE_FIRING=${NEURAL_SYNAPSE_FIRING:-0}
        EJECTION_COUNT=${EJECTION_COUNT:-0}
        SUDO_ATTEMPT_COUNT=${SUDO_ATTEMPT_COUNT:-0}
        HELP_ACCESS_COUNT=${HELP_ACCESS_COUNT:-0}
        FACTORY_ABUSE_COUNT=${FACTORY_ABUSE_COUNT:-0}
        TEST_LAUNCH_COUNT=${TEST_LAUNCH_COUNT:-0}
        WARP_JUMP_COUNT=${WARP_JUMP_COUNT:-0}
        LOGIN_COUNT=${LOGIN_COUNT:-0}
        
        save_required=true
    fi
    
    if [ "$save_required" == "true" ]; then
        _save_identity
    fi
}

# 行為記錄器 (Behavior Recorder)
function _record_behavior() {
    local action_type="$1"
    
    # 確保變數已載入
    if [ -z "$HEAP_ALLOCATION_IDX" ]; then source "$IDENTITY_FILE"; fi
    
    case "$action_type" in
        "CMD_EXEC")
            # 執行指令 -> 堆疊分配索引
            HEAP_ALLOCATION_IDX=$((HEAP_ALLOCATION_IDX + 1))
            ;;
        "FAC_CREATE")
            # 新增節點 -> IO寫入循環
            IO_WRITE_CYCLES=$((IO_WRITE_CYCLES + 1))
            ;;
        "FAC_EDIT")
            # 修改參數 -> 核心錯誤偏移
            KERNEL_PANIC_OFFSET=$((KERNEL_PANIC_OFFSET + 1))
            ;;
        "GIT_PUSH")
            # 部署/上傳 -> 上行延遲
            UPLINK_LATENCY_MS=$((UPLINK_LATENCY_MS + 1))
            ;;
        "FAC_DEL")
            # 刪除節點 -> 熵值釋放
            ENTROPY_DISCHARGE=$((ENTROPY_DISCHARGE + 1))
            ;;
        "NEURAL_LINK")
            # 搜尋/連結 -> 神經突觸點火
            NEURAL_SYNAPSE_FIRING=$((NEURAL_SYNAPSE_FIRING + 1))
            ;;
    esac
    
    # 靜默存檔
    _save_identity
}

# 隱藏成就解鎖器 (Hidden Achievement Unlocker)
# 用法: _unlock_badge "TAG_NAME" "Badge Name"
function _unlock_badge() {
    local tag="$1"
    local name="$2"
    
    # 1. 讀取最新狀態
    if [ -f "$IDENTITY_FILE" ]; then source "$IDENTITY_FILE"; fi
    
    # 2. 檢查是否已擁有 (避免重複跳通知)
    if [[ "$MUX_BADGES" == *"$tag"* ]]; then
        return 0
    fi
    
    # 3. 寫入標記
    # 如果是 INIT，直接附加；否則加 | 分隔
    if [ "$MUX_BADGES" == "INIT" ] || [ -z "$MUX_BADGES" ]; then
        MUX_BADGES="$tag"
    else
        MUX_BADGES="${MUX_BADGES}|${tag}"
    fi
    
    # 4. 存檔
    _save_identity
    
    # 5. 視覺通知 (Achievement Unlocked)
    echo ""
    echo -e "\033[1;33m :: HIDDEN ACHIEVEMENT UNLOCKED ::\033[0m"
    echo -e "\033[1;37m    [ $name ]\033[0m"
    echo -e "\033[1;30m    ›› Identity Record Updated.\033[0m"
    echo ""
    
    # 播放音效 (可選)
    if command -v _bot_say &> /dev/null; then
        _bot_say "success" "Achievement Unlocked: $name"
    fi
}

# 狀態加成計算核心 (Buff Calculation Engine)
function _check_active_buffs() {
    # 預設：無加成
    export MUX_CURRENT_MULT=1
    export MUX_BUFF_TAG=""
    
    local current_hour=$(date +%H)
    local current_day=$(date +%u) # 1-7 (1=Mon, 7=Sun)
    local current_date=$(date +%m%d)

    # 閏年特別加成 [3x]
    if [ "$current_date" == "0229" ]; then
        if command -v _unlock_badge &> /dev/null; then _unlock_badge "LOST_TIME" "Lost in Time"; fi
        export MUX_CURRENT_MULT=3
        export MUX_BUFF_TAG="\033[1;35;47m[3x:Rift]\033[0m"
        return
    fi

    # 節日慶典 [2x]
    local event_name=""
    
    case "$current_date" in
        "0101") event_name="Init";;    # New Year
        "0314") event_name="Pi";;      # Pi Day
        "0401") event_name="Glitch";;  # April Fools
        "0504") event_name="Force";;   # Star Wars Day
        "0913") event_name="Dev";;     # Programmer Day
        "1031") event_name="Spooky";;  # Halloween
        "1225") event_name="Xmas";;    # Christmas
    esac

    if [ -n "$event_name" ]; then
        export MUX_CURRENT_MULT=2
        export MUX_BUFF_TAG="\033[1;35m[2x:$event_name]\033[0m" 
        return
    fi

    # 懲罰性加成 [-5] - Blue Monday: 週一上午 06:00 - 12:00
    if [ "$current_day" -eq 1 ] && [ "$current_hour" -ge 6 ] && [ "$current_hour" -lt 12 ]; then
        export MUX_CURRENT_MULT=0.5
        export MUX_BUFF_TAG="\033[1;34m[-5:Blue]\033[0m"
        return
    fi

    # 深夜模式: 00:00 - 04:00 (熬夜獎勵)
    # 請不要熬夜玩系統
    if [ "$current_hour" -ge 0 ] && [ "$current_hour" -lt 4 ]; then
        export MUX_CURRENT_MULT=1.5
        export MUX_BUFF_TAG="\033[1;33m[+5:Night]\033[0m" 
        return
    fi

    # 週末戰士: 週日全天 (Sunday)
    if [ "$current_day" -ge 7 ]; then
        export MUX_CURRENT_MULT=1.5
        export MUX_BUFF_TAG="\033[1;36m[+5:Sun]\033[0m" 
        return
    fi
}

# 奇點審判庭 (Singularity Tribunal)
function _check_singularity() {
    local calc_req=2000
    for ((i=1; i<16; i++)); do
        calc_req=$(awk "BEGIN {print int($calc_req * 1.5 + 2000)}")
    done
    local l16_floor=$calc_req
    local l16_ceiling=$(( l16_floor + 5000 )) 

    local strike_reason=""
    local now_ts=$(date +%s)

    if [ "$MUX_XP" -gt "$l16_ceiling" ]; then
        strike_reason="Singularity: Mass Overflow (XP > Theoretical Cap)"
    fi

    if [ "$MUX_LEVEL" -ge 16 ] && [ "$MUX_XP" -lt "$l16_floor" ]; then
        strike_reason="Paradox Detected: False Ascension (Level != XP)"
    fi

    local install_time="${MUX_DATE:-$now_ts}"
    local time_diff=$(( now_ts - install_time ))
    local min_time_required=43200 

    if [ "$MUX_LEVEL" -ge 16 ] && [ "$time_diff" -lt "$min_time_required" ]; then
        strike_reason="Temporal Violation: Speedrun Impossible (${time_diff}s)"
    fi

    if [ -n "$strike_reason" ]; then
        _trigger_dimensional_strike "$strike_reason"
        return 1
    fi
    
    return 0
}

# 審判執行 (Execute Force)
function _trigger_dimensional_strike() {
    local reason="$1"
    
    echo ""
    echo -e "\033[1;31m :: WARNING: SINGULARITY THRESHOLD EXCEEDED ::\033[0m"
    echo -e "\033[1;30m    ›› Analysis: $reason\033[0m"
    sleep 0.5
    echo -e "\033[1;30m    ›› System Entropy: CRITICAL\033[0m"
    sleep 0.5
    
    if command -v _unlock_badge &> /dev/null; then
        _unlock_badge "DSTRIKE" "Dimensional Strike"
    fi
    
    sleep 1
    echo -e "\033[1;31;5m :: INITIATING DUAL VECTOR FOIL ATTACK :: \033[0m"
    sleep 2
    
    MUX_LEVEL=1
    MUX_XP=0
    MUX_NEXT_XP=2000
    MUX_DATE=$(date +%s)
    MUX_LF=$MUX_DATE
    MUX_LB=""
    
    _save_identity
    
    echo -e "\033[1;36m :: UNIVERSE REBOOTING... :: \033[0m"
    sleep 2
    
    if command -v _mux_reload_kernel &> /dev/null; then
        _mux_reload_kernel
    else
        exec bash
    fi
}

# XP 以及 Level 升級系統 (Experience and Leveling System)
function _grant_xp() {
    local base_amount=$1
    local source_type=$2

    local whitelist=(
                        "mux"
                        "fac"
                        "_mux_pre_login"
                        "_mux_set_logout"
                        "_core_system_scan"
                        "_neural_link_deploy"
                        "_core_pre_factory_auth"
                        "_core_eject_sequence"
                        "_mux_neural_fire_control"
                        "_mux_uplink_sequence"
                        "_fac_edit_router"
                        "_fac_launch_test"
                        "_factory_deploy_sequence"
                        "_fac_safe_edit_protocol"
                        "_fac_generic_edit"
                        "_fac_update_category_name"
                        "_fac_delete_node"
                        "_fac_rebak_wizard"
                    )
    local authorized=false
    local stack_trace="${FUNCNAME[*]}"

    # 豁免條款
    if [ "$source_type" == "SHELL" ]; then
        authorized=true
    else
        for trigger in "${whitelist[@]}"; do
            if [[ "$stack_trace" == *"$trigger"* ]]; then
                authorized=true
                break
            fi
        done
    fi

    # 攔截非法呼叫
    if [ "$authorized" == "false" ]; then
        echo ""
        echo -e "\033[1;31m :: SECURITY ALERT :: Unauthorized XP Injection Detected.\033[0m"
        echo -e "\033[1;30m    ›› Source: Direct Terminal / External Script\033[0m"
        echo -e "\033[1;30m    ›› Action: Request Denied. Incident Logged.\033[0m"
        
        # 懲罰機制：扣除 50 XP (可選)
        # MUX_XP=$((MUX_XP - 50))
        # if [ "$MUX_XP" -lt 0 ]; then MUX_XP=0; fi
        # _save_identity
        
        return 1
    fi

    local now_ts=$(date +%s)
    local install_ts="${MUX_DATE:-$now_ts}"
    local day_diff=$(( (now_ts - install_ts) / 86400 ))
    if [ "$day_diff" -ge 365 ]; then
        _unlock_badge "ANCIENT_ONE" "The Ancient One"
    fi

    if [ "$MUX_LEVEL" -ge 8 ] && [[ "$MUX_BADGES" == *"DSTRIKE"* ]]; then
        _unlock_badge "PHOENIX" "Phoenix"
    fi

    # 確保身份數據已載入
    if [ -f "$IDENTITY_FILE" ]; then
        source "$IDENTITY_FILE"
    fi

    if [ "$MUX_LEVEL" -ge 16 ]; then
        _check_singularity
        return
    fi

    _check_active_buffs

    local final_amount=$(awk "BEGIN {print int($base_amount * $MUX_CURRENT_MULT)}")

    # 如果有加成且數值大於 0，顯示加成特效 (可選)
    # if [ "$MUX_CURRENT_MULT" != "1" ] && [ "$final_amount" -gt 0 ]; then
    #    echo -e " \033[1;30m(Buff Applied: x$MUX_CURRENT_MULT)\033[0m"
    # fi
    
    MUX_XP=$((MUX_XP + final_amount))

    case "$source_type" in
        "CMD_EXEC")    _record_behavior "CMD_EXEC" ;;    # 執行指令
        "FAC_CREATE")  _record_behavior "FAC_CREATE" ;;  # 新增節點
        "FAC_EDIT")    _record_behavior "FAC_EDIT" ;;    # 修改參數
        "FAC_DEL")     _record_behavior "FAC_DEL" ;;     # 刪除節點
        "FAC_DEPLOY")  _record_behavior "GIT_PUSH" ;;    # 工廠部署
        "GIT_PUSH")    _record_behavior "GIT_PUSH" ;;    # 核心部署
        "NEURAL_LINK") _record_behavior "NEURAL_LINK" ;; # 連結/搜尋
        "WARP_JUMP")   _record_behavior "NEURAL_LINK" ;; # 切換分支
        "TEST_OK"|"TEST_FAIL") 
            TEST_LAUNCH_COUNT=$((TEST_LAUNCH_COUNT + 1)) 
            ;;
        "WARP_JUMP") 
            WARP_JUMP_COUNT=$((WARP_JUMP_COUNT + 1)) 
            ;;
        "LOGIN") 
            LOGIN_COUNT=$((LOGIN_COUNT + 1)) 
            ;;
        *) ;;  # 其他行為不記錄
    esac
    
    if [ "$MUX_XP" -ge "$MUX_NEXT_XP" ]; then
        local promote_flag=1
        local deny_reason=""
        
        # 1. 呼叫 UI 進行靜默統計
        if [ -f "$UI_MOD" ]; then
            source "$UI_MOD"
            _show_badges "CALC"
        fi

        # 2. 定義審查標準 (The Gate)
        # L7: 3 Bronze
        if [ "$MUX_LEVEL" -eq 6 ]; then
             if [ "${MEDAL_STATS_S1:-0}" -lt 3 ]; then promote_flag=0; deny_reason="3 Bronze Medals (Current: ${MEDAL_STATS_S1})"; fi
        fi
        # L8: 1 Silver
        if [ "$MUX_LEVEL" -eq 7 ]; then
             if [ "${MEDAL_STATS_S2:-0}" -lt 1 ]; then promote_flag=0; deny_reason="1 Silver Medal (Current: ${MEDAL_STATS_S2})"; fi
        fi
        # L9: 2 Silver
        if [ "$MUX_LEVEL" -eq 8 ]; then
             if [ "${MEDAL_STATS_S2:-0}" -lt 2 ]; then promote_flag=0; deny_reason="2 Silver Medals (Current: ${MEDAL_STATS_S2})"; fi
        fi
        # L10: 4 Silver
        if [ "$MUX_LEVEL" -eq 9 ]; then
             if [ "${MEDAL_STATS_S2:-0}" -lt 4 ]; then promote_flag=0; deny_reason="4 Silver Medals (Current: ${MEDAL_STATS_S2})"; fi
        fi
        # L11: 1 Gold
        if [ "$MUX_LEVEL" -eq 10 ]; then
             if [ "${MEDAL_STATS_S3:-0}" -lt 1 ]; then promote_flag=0; deny_reason="1 Gold Medal (Current: ${MEDAL_STATS_S3})"; fi
        fi
        # L12 (Elite): 2 Gold
        if [ "$MUX_LEVEL" -eq 11 ]; then
             if [ "${MEDAL_STATS_S3:-0}" -lt 2 ]; then promote_flag=0; deny_reason="2 Gold Medals (Current: ${MEDAL_STATS_S3})"; fi
        fi
        # L13: 4 Gold
        if [ "$MUX_LEVEL" -eq 12 ]; then
             if [ "${MEDAL_STATS_S3:-0}" -lt 4 ]; then promote_flag=0; deny_reason="4 Gold Medals (Current: ${MEDAL_STATS_S3})"; fi
        fi
        # L14: 1 Platinum
        if [ "$MUX_LEVEL" -eq 13 ]; then
             if [ "${MEDAL_STATS_S4:-0}" -lt 1 ]; then promote_flag=0; deny_reason="1 Platinum Medal (Current: ${MEDAL_STATS_S4})"; fi
        fi
        # L15: 3 Platinum
        if [ "$MUX_LEVEL" -eq 14 ]; then
             if [ "${MEDAL_STATS_S4:-0}" -lt 3 ]; then promote_flag=0; deny_reason="3 Platinum Medals (Current: ${MEDAL_STATS_S4})"; fi
        fi
        # L16 (Architect): 1 Obsidian
        if [ "$MUX_LEVEL" -eq 15 ]; then
             if [ "${MEDAL_STATS_S5:-0}" -lt 1 ]; then promote_flag=0; deny_reason="1 Obsidian Medal (Current: ${MEDAL_STATS_S5})"; fi
        fi

        # 3. 執行判決
        if [ "$promote_flag" -eq 0 ]; then
            # 鎖死 XP
            MUX_XP=$((MUX_NEXT_XP - 1))
            
            # 隨機顯示阻擋訊息
            if [ $((RANDOM % 3)) -eq 0 ]; then
                echo ""
                echo -e "\033[1;31m :: PROMOTION DENIED :: Clearance Level $MUX_LEVEL Locked.\033[0m"
                echo -e "\033[1;30m    ›› Requirement: $deny_reason\033[0m"
                echo -e "\033[1;30m    ›› Check 'hof' for details.\033[0m"
            fi
            _save_identity
            return
        fi

        MUX_LEVEL=$((MUX_LEVEL + 1))
        # 混合線性成長公式
        MUX_NEXT_XP=$(awk "BEGIN {print int($MUX_NEXT_XP * 1.5 + 2000)}")

        local now_ts=$(date +%s)
        MUX_LB=$now_ts
        # local duration=$(( MUX_LB - MUX_LF )) # 計算該等級滯留時間
        MUX_LF=$MUX_LB
        MUX_LB=""
        
        echo ""
        if command -v _bot_say &> /dev/null; then
            _bot_say "system" "LEVEL UP! Clearance Level $MUX_LEVEL Granted."
        else
            echo -e "\033[1;33m :: LEVEL UP! Clearance Level $MUX_LEVEL Granted. ::\033[0m"
        fi

        if [ "$MUX_LEVEL" -ge 16 ]; then
             echo -e "\033[1;37m :: MAXIMUM CLEARANCE REACHED :: ARCHITECT STATUS ::\033[0m"
             _check_singularity
        fi

        if [ "$MUX_LEVEL" -eq 8 ]; then
             echo -e "\033[1;35m :: OVERCLOCK PROTOCOL UNLOCKED ::\033[0m"
        fi
    fi
    _save_identity
}

# Git/GitHub 連結設定 (Uplink Setup)
function _setup_git_auth() {
    echo ""
    echo -e "\033[1;33m :: Initializing GitHub Neural Uplink... ::\033[0m"
    
    # 1. 解決變更權限後導致 git dirty 的問題
    git config core.fileMode false
    
    # 2. 檢查 Git 身份
    local current_name=$(git config --global user.name)
    local current_email=$(git config --global user.email)
    
    if [ -z "$current_name" ] || [ -z "$current_email" ]; then
        echo -e "\033[1;30m    ›› Git identity not found. Configuring now...\033[0m"
        
        echo -ne "\033[1;36m    ›› Enter GitHub Username: \033[0m"
        read git_user
        echo -ne "\033[1;36m    ›› Enter GitHub Email   : \033[0m"
        read git_email
        
        if [ -n "$git_user" ] && [ -n "$git_email" ]; then
            git config --global user.name "$git_user"
            git config --global user.email "$git_email"
            
            # 儲存憑證 (避免每次 push 都要打密碼)
            git config --global credential.helper store
            
            echo -e "\033[1;32m    ›› Git Identity Configured.\033[0m"
        fi
    else
        echo -e "\033[1;32m    ›› Git Identity Verified: $current_name\033[0m"
    fi

    # 3. GitHub CLI (gh) 授權檢測
    if command -v gh &> /dev/null; then
        echo ""
        echo -e "\033[1;35m :: GitHub CLI (gh) Detected. ::\033[0m"
        
        # 檢查 gh 是否已登入
        if ! gh auth status &> /dev/null; then
            echo -ne "\033[1;33m    ›› Authenticate with GitHub now? [Y/n]: \033[0m"
            read choice
            if [[ "$choice" == "y" || "$choice" == "Y" || -z "$choice" ]]; then
                # 啟動 gh 登入流程
                gh auth login
            fi
        else
             echo -e "\033[1;32m    ›› GitHub Uplink Active.\033[0m"
        fi
    fi
}

# 註冊指揮官身份 (Interactive Mode)
function _register_commander_interactive() {
    echo -e "\033[1;33m :: Mux-OS Identity Registration ::\033[0m"
    echo ""
    
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    
    if [ "false" == "true" ]; then
        echo -e "    Detected Branch: \033[1;31m$current_branch (Public)\033[0m"
        echo -e "    \033[1;33m:: Notice: Identity is locked to 'Unknown' on main branch.\033[0m"
        sleep 1
        
        echo "MUX_ID=Unknown" > "$IDENTITY_FILE"
        echo "MUX_ROLE=GUEST" >> "$IDENTITY_FILE"
        echo "MUX_ACCESS_LEVEL=0" >> "$IDENTITY_FILE"
        echo "MUX_CREATED_AT=$(date +%s)" >> "$IDENTITY_FILE"
        
        echo ""
        echo -e "\033[1;32m :: Identity Set: Unknown (main) \033[0m"
        sleep 1
        return
    fi

    local git_user=$(git config user.name 2>/dev/null)
    [ -z "$git_user" ] && git_user="$current_branch"
    
    echo -e "    Detected Signal: \033[1;36m$git_user\033[0m"
    echo -ne "\033[1;32m :: Input Commander ID: \033[0m"
    read input_id

    if [ -z "$input_id" ]; then
        input_id="$git_user"
    fi

    echo ""
    echo -e "\033[1;35m :: Encoding Identity...\033[0m"
    echo ""
    sleep 1
    
    echo "MUX_ID=$input_id" > "$IDENTITY_FILE"
    echo "MUX_ROLE=COMMANDER" >> "$IDENTITY_FILE"
    echo "MUX_ACCESS_LEVEL=5" >> "$IDENTITY_FILE"
    echo "MUX_CREATED_AT=$(date +%s)" >> "$IDENTITY_FILE"

    _setup_git_auth
    
    echo -e "\033[1;32m :: Identity Confirmed: $input_id \033[0m"
    sleep 1
}

# 獨立執行判斷 (For setup.sh to trigger wizard)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _register_commander_interactive
fi

# 自動執行初始化
_init_identity