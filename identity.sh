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
EOF
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
    
    echo -e "\033[1;32m :: Identity Confirmed: $input_id \033[0m"
    sleep 1
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
        _save_identity
    fi
    
    source "$IDENTITY_FILE"
    
    # 舊用戶遷移
    if [ -z "$MUX_LEVEL" ]; then
        MUX_LEVEL=1
        MUX_XP=0
        MUX_NEXT_XP=2000
        MUX_BADGES="INIT"
        _save_identity
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

# XP 以及 Level 升級系統 (Experience and Leveling System)
function _grant_xp() {
    local base_amount=$1
    local source_type=$2
    
    if [ -f "$IDENTITY_FILE" ]; then
        source "$IDENTITY_FILE"
    fi

    _check_active_buffs

    local final_amount=$(awk "BEGIN {print int($base_amount * $MUX_CURRENT_MULT)}")

    # 如果有加成且數值大於 0，顯示加成特效 (可選)
    # if [ "$MUX_CURRENT_MULT" != "1" ] && [ "$final_amount" -gt 0 ]; then
    #    echo -e " \033[1;30m(Buff Applied: x$MUX_CURRENT_MULT)\033[0m"
    # fi
    
    MUX_XP=$((MUX_XP + final_amount))
    
    if [ "$MUX_XP" -ge "$MUX_NEXT_XP" ]; then
        MUX_LEVEL=$((MUX_LEVEL + 1))
        # 混合線性成長公式
        MUX_NEXT_XP=$(awk "BEGIN {print int($MUX_NEXT_XP * 1.5 + 2000)}")
        
        echo ""
        if command -v _bot_say &> /dev/null; then
            _bot_say "system" "LEVEL UP! Clearance Level $MUX_LEVEL Granted."
        else
            echo -e "\033[1;33m :: LEVEL UP! Clearance Level $MUX_LEVEL Granted. ::\033[0m"
        fi

        if [ "$MUX_LEVEL" -eq 8 ]; then
             echo -e "\033[1;35m :: OVERCLOCK PROTOCOL UNLOCKED ::\033[0m"
        fi
    fi
    _save_identity
}

# 獨立執行判斷 (For setup.sh to trigger wizard)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _register_commander_interactive
fi

# 自動執行初始化
_init_identity