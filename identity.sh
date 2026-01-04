#!/bin/bash
# identity.sh - Mux-OS 身份識別矩陣

export MUX_ROOT="${MUX_ROOT:-$HOME/mux-os}"
export IDENTITY_FILE="$MUX_ROOT/.mux_identity"

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

function _register_commander_interactive() {
    echo -e "\033[1;33m :: Mux-OS Identity Registration ::\033[0m"
    echo ""
    
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    
    if [ "$current_branch" == "main" ]; then
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
    sleep 1
    
    echo "MUX_ID=$input_id" > "$IDENTITY_FILE"
    echo "MUX_ROLE=COMMANDER" >> "$IDENTITY_FILE"
    echo "MUX_ACCESS_LEVEL=5" >> "$IDENTITY_FILE"
    echo "MUX_CREATED_AT=$(date +%s)" >> "$IDENTITY_FILE"
    
    echo -e "\033[1;32m :: Identity Confirmed: $input_id \033[0m"
    sleep 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _register_commander_interactive
fi

export IDENTITY_FILE="$MUX_ROOT/.mux_identity"

function _init_identity() {
    if [ ! -f "$IDENTITY_FILE" ]; then
        echo "MUX_ID=Unknown" > "$IDENTITY_FILE"
        echo "MUX_ROLE=GUEST" >> "$IDENTITY_FILE"
        echo "MUX_ACCESS_LEVEL=0" >> "$IDENTITY_FILE"
        echo "MUX_CREATED_AT=$(date +%s)" >> "$IDENTITY_FILE"
    fi
    source "$IDENTITY_FILE"
}

# 掃描前置儀式 (Pre-Auth Ritual)
function _identity_pre_scan() {
    echo ""
    echo -ne "\033[1;30m [SECURITY] Establishing Secure Uplink...\033[0m"
    sleep 0.6
    echo -ne "\r\033[1;30m [SECURITY] Handshaking with Local Host...   \033[0m"
    sleep 0.6
    echo -ne "\r\033[1;36m [SECURITY] Requesting Biometric Signature... \033[0m"
    sleep 0.8
    echo ""
}

# 驗證通過儀式 (Access Granted)
function _identity_access_granted() {
    echo ""
    echo -e "\033[1;32m [ACCESS GRANTED] Identity Confirmed.\033[0m"
    echo -e "\033[1;30m :: Unlocking Neural Pathways...\033[0m"
    sleep 0.5
    echo -e "\033[1;30m :: Disabling Safety Inhibitors...\033[0m"
    sleep 0.5
    echo -e "\033[1;35m :: Welcome to the Forge, Commander $MUX_ID.\033[0m"
    sleep 1
}

# 驗證失敗儀式 (Access Denied)
function _identity_access_denied() {
    echo ""
    _bot_say "error" "Signature Mismatch."
    echo -e "\033[1;31m [ACCESS DENIED] Security Protocol Engaged.\033[0m"
    echo -e "\033[1;30m :: Terminating Connection...\033[0m"
    sleep 1.5
    clear
    _draw_logo "core"
}

# 註冊流程
function _register_commander() {
    _system_lock
    clear
    _draw_logo "factory"
    
    echo -e "\033[1;33m :: Identity Registration Protocol ::\033[0m"
    local git_user=$(git config user.name 2>/dev/null)
    [ -z "$git_user" ] && git_user="Unknown"
    echo -e "    Detected Signal: \033[1;36m$git_user\033[0m"
    echo ""
    
    _system_unlock 
    echo -ne "\033[1;32m :: Input Commander ID: \033[0m"
    read input_id

    [ -z "$input_id" ] && return 1

    echo ""
    echo -e "\033[1;31m [WARNING] \033[0m Bind terminal to \033[1;37m[$input_id]\033[0m?"
    echo ""
    
    _system_unlock
    echo -ne "\033[1;33m :: Type 'CONFIRM': \033[0m"
    read confirm

    if [ "$confirm" == "CONFIRM" ]; then
        echo -e "\n\033[1;35m :: Encoding Identity...\033[0m"
        sleep 1
        echo "MUX_ID=$input_id" > "$IDENTITY_FILE"
        echo "MUX_ROLE=COMMANDER" >> "$IDENTITY_FILE"
        echo "MUX_ACCESS_LEVEL=99" >> "$IDENTITY_FILE"
        source "$IDENTITY_FILE"
        return 0
    else
        return 1
    fi
}

function _verify_identity_for_factory() {
    if [ ! -f "$IDENTITY_FILE" ]; then _init_identity; fi
    source "$IDENTITY_FILE"

    _identity_pre_scan

    if [ "$MUX_ID" == "Unknown" ]; then
        echo -e "\033[1;31m :: Unknown Identity. Registration Required.\033[0m"
        sleep 1
        _register_commander
        if [ $? -ne 0 ]; then 
            _identity_access_denied
            return 1 
        fi
        source "$IDENTITY_FILE"
    fi

    if [ "$MUX_ROLE" == "COMMANDER" ]; then
        echo -e "\033[1;35m :: Factory Gate :: \033[1;37m$MUX_ID\033[0m"
        
        _system_unlock
        echo -ne "\033[1;35m :: Type 'CONFIRM': \033[0m"
        read input
        
        if [ "$input" == "CONFIRM" ]; then
            _identity_access_granted
            return 0
        else
            _identity_access_denied
            return 1
        fi
    fi
    _identity_access_denied
    return 1
}