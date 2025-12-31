#!/bin/bash

# identity.sh - Mux-OS 身份識別矩陣

export IDENTITY_FILE="$MUX_ROOT/.mux_identity"

# 初始化身份 (Bootloader level)
function _init_identity() {
    if [ ! -f "$IDENTITY_FILE" ]; then
        echo "MUX_ID=Unknown" > "$IDENTITY_FILE"
        echo "MUX_ROLE=GUEST" >> "$IDENTITY_FILE"
        echo "MUX_ACCESS_LEVEL=0" >> "$IDENTITY_FILE"
        echo "MUX_CREATED_AT=$(date +%s)" >> "$IDENTITY_FILE"
    fi

    # 載入身份變數
    source "$IDENTITY_FILE"
}

# 身份驗證檢查 (Gatekeeper)
function _verify_access() {
    local required_level="$1"
    
    if [ "$MUX_ACCESS_LEVEL" -ge "$required_level" ]; then
        return 0
    else
        return 1
    fi
}

# 指揮官註冊儀式 (The Ritual)
function _register_commander() {
    _system_lock
    clear
    _draw_logo "factory"

    echo -e "\033[1;33m :: Identity Registration Protocol ::\033[0m"
    echo -e "\033[1;30m    Authentication required for Root Access (Factory).\033[0m"
    echo ""
    
    local git_user=$(git config user.name 2>/dev/null)
    [ -z "$git_user" ] && git_user="Unknown"

    echo -e "    Detected Signal: \033[1;36m$git_user\033[0m"
    echo ""
    echo -ne "\033[1;32m :: Input Commander ID: \033[0m"
    read input_id

    if [ -z "$input_id" ]; then
        _bot_say "error" "Identity cannot be void."
        sleep 1
        _system_unlock
        return 1
    fi

    echo ""
    echo -e "\033[1;31m [WARNING] \033[0m"
    echo -e " This will bind this terminal to \033[1;37m[$input_id]\033[0m."
    echo -e " Write-access to Factory will be granted."
    echo ""
    echo -ne "\033[1;33m :: Type 'CONFIRM' to encode identity: \033[0m"
    read confirm

    if [ "$confirm" == "CONFIRM" ]; then
        echo -e "\n\033[1;35m :: Encoding Identity Matrix...\033[0m"
        sleep 1
        
        echo "MUX_ID=$input_id" > "$IDENTITY_FILE"
        echo "MUX_ROLE=COMMANDER" >> "$IDENTITY_FILE"
        echo "MUX_ACCESS_LEVEL=99" >> "$IDENTITY_FILE"
        echo "MUX_ORIGIN_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)" >> "$IDENTITY_FILE"
        echo "MUX_UPDATED_AT=$(date +%s)" >> "$IDENTITY_FILE"

        source "$IDENTITY_FILE"
        
        echo -e "\033[1;32m :: Identity Verified. Welcome, Commander $MUX_ID.\033[0m"
        sleep 1
        _system_unlock
        return 0
    else
        echo -e "\n\033[1;30m :: Verification failed.\033[0m"
        sleep 1
        _system_unlock
        return 1
    fi
}