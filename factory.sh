#!/bin/bash
# factory.sh - Mux-OS 兵工廠 v5.2.0 (Gray Ghost Protocol)

F_MAIN="\033[1;35m"
F_SUB="\033[1;37m"
F_WARN="\033[1;33m"
F_ERR="\033[1;31m"
F_GRAY="\033[1;30m"
F_RESET="\033[0m"

# 進入兵工廠模式 (Entry Point)
function _enter_factory_mode() {
    _factory_boot_sequence
    
    if [ $? -ne 0 ]; then return; fi

    export __MUX_MODE="factory"
    
    _factory_auto_backup > /dev/null 2>&1
    
    clear
    _draw_logo "factory"
    
    echo -e "${F_MAIN} :: Factory Mode Engaged.${F_RESET}"
    echo -e "${F_SUB} :: Write-Access: ${F_WARN}ENABLED${F_RESET} | Safety: ${F_ERR}OFF${F_RESET}"
    echo ""
    _bot_say "factory_welcome"
    echo ""
}

function _factory_boot_sequence() {
    clear
    _draw_logo "gray"
    
    _system_lock
    echo -e "${F_GRAY} :: SECURITY CHECKPOINT ::${F_RESET}"
    echo -e "${F_GRAY}    Identity Verification Required.${F_RESET}"
    sleep 0.5
    echo ""
    
    local git_user=$(git config user.name 2>/dev/null)
    [ -z "$git_user" ] && git_user="Unknown"
    
    _system_unlock
    echo -ne "\033[1;37m :: Commander ID: \033[0m" 
    read input_id
    
    echo -ne "\033[1;33m :: CONFIRM IDENTITY (Type 'CONFIRM'): \033[0m"
    read confirm
    
    echo ""
    _system_lock
    echo -ne "${F_GRAY} :: Scanning Biometrics... \033[0m"
    sleep 0.8
    echo -ne "\r${F_GRAY} :: Verifying Neural Signature... \033[0m"
    sleep 0.8
    echo ""

    local verify_success=0
    if [ "$confirm" == "CONFIRM" ] && [ -n "$input_id" ]; then
        if [ -f "$MUX_ROOT/.mux_identity" ]; then
            source "$MUX_ROOT/.mux_identity"
            if [ "$input_id" == "$MUX_ID" ]; then
                verify_success=1
            fi
        else
             verify_success=1
        fi
    fi
    
    if [ "$verify_success" -eq 1 ]; then
        echo -e "\n\033[1;32m [ACCESS GRANTED] \033[0m"
        sleep 0.5
        
        clear
        _draw_logo "gray"
        echo -e "${F_ERR} [WARNING: FACTORY PROTOCOL] ${F_RESET}"
        echo -e "${F_SUB} 1. Modifications here are permanent.${F_RESET}"
        echo -e "${F_SUB} 2. Do not delete system kernels.${F_RESET}"
        echo -e "${F_SUB} 3. You are responsible for system stability.${F_RESET}"
        echo ""
        _system_unlock
        echo -ne "${F_WARN} :: Proceed? [y/N]: ${F_RESET}"
        read choice
        
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            _factory_eject_sequence "User aborted."
            return 1
        fi
        
        _system_lock
        echo ""
        local steps=("Injecting Logic..." "Desynchronizing Core..." "Loading Arsenal..." "Entering Factory...")
        for step in "${steps[@]}"; do
            echo -e "${F_MAIN}    ›› $step${F_RESET}"
            sleep 0.4
        done
        sleep 0.5
        _system_unlock
        return 0

    else
        _factory_eject_sequence "Identity Mismatch."
        return 1 
    fi
}

# 彈射序列 (The Ejection)
function _factory_eject_sequence() {
    local reason="$1"
    echo ""
    echo -e "${F_ERR} [ACCESS DENIED] ${reason}${F_RESET}"
    sleep 0.5
    echo -e "${F_ERR} :: Initiating Eviction Protocol...${F_RESET}"
    sleep 0.5
    echo -e "${F_ERR} :: Locking Cockpit...${F_RESET}"
    sleep 0.5
    echo -e "${F_ERR} :: Auto-Eject System Activated.${F_RESET}"
    echo ""
    
    for i in {3..1}; do
        echo -e "${F_ERR} :: Ejection in $i...${F_RESET}"
        sleep 1
    done
    
    echo ""
    _bot_say "factory_reject"
    sleep 2.6
    _system_unlock
    clear
    mux reload
}

# 兵工廠指令入口 - Factory Command Entry
function fac() {
    local cmd="$1"
    if [ "$__MUX_MODE" != "factory" ]; then
        echo -e "\033[1;31m :: Error: Link Offline. Use 'mux fac'.\033[0m"
        return 1
    fi

    case "$cmd" in
        "menu"|"m") _factory_fzf_menu ;;
        "list"|"l") _factory_list_links ;;
        "deploy"|"d"|"exit") _factory_deploy_sequence ;;
        "help"|"h") _factory_help ;;
        *) echo -e "${F_WARN} :: Unknown Directive: $cmd${F_RESET}" ;;
    esac
}

function _factory_auto_backup() {
    local bak_dir="$MUX_ROOT/bak"
    [ ! -d "$bak_dir" ] && mkdir -p "$bak_dir"
    cp "$MUX_ROOT/app.sh" "$bak_dir/app.sh_$(date +%Y%m%d_%H%M%S)"
    ls -t "$bak_dir"/app.sh_* 2>/dev/null | tail -n +4 | xargs rm -- 2>/dev/null
}

function _factory_deploy_sequence() {
    echo ""
    echo -e "${F_MAIN} :: Initiate Deployment Sequence?${F_RESET}"
    echo -ne "${F_WARN} :: Type 'CONFIRM' to save & exit: ${F_RESET}"
    read confirm
    
    if [ "$confirm" == "CONFIRM" ]; then
        echo ""
        _bot_say "success" "Neural map updated."
        local time_str="# :: Last Sync: $(date '+%Y-%m-%d %H:%M:%S') ::"
        if grep -q "Last Sync" "$MUX_ROOT/app.sh"; then
            sed -i "1s|.*Last Sync.*|$time_str|" "$MUX_ROOT/app.sh"
        else
            sed -i "1i $time_str" "$MUX_ROOT/app.sh"
        fi
        export __MUX_MODE="core"
        sleep 1
        clear
        _draw_logo "core"
        echo -e "\033[1;36m :: System control returned to Core.\033[0m"
        echo -e "\033[1;30m    (Please manual 'mux reload')\033[0m"
    else
        echo -e "${F_WARN} :: Deploy canceled.${F_RESET}"
    fi
}

function _factory_list_links() {
    echo -e "\n${F_MAIN} :: Current Neural Links:${F_RESET}"
    grep "^function" "$MUX_ROOT/app.sh" | sed 's/function //' | sed 's/() {//' | column
    echo ""
}

function _factory_help() {
    echo -e "\n${F_MAIN} :: Factory Manual ::${F_RESET}"
    echo "  fac menu   : Open Neural Forge (FZF)"
    echo "  fac list   : List functions"
    echo "  fac deploy : Save changes & Return to Core"
}

function _factory_fzf_menu() {
    echo -e "\n${F_MAIN} :: Neural Forge (FZF) under construction...${F_RESET}"
}