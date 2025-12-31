#!/bin/bash

# factory.sh - Mux-OS 兵工廠 (The Arsenal)

# 定義 Factory 專用顏色 (粉紫系)
F_MAIN="\033[1;35m"  # Pink/Purple
F_SUB="\033[1;37m"   # White
F_WARN="\033[1;33m"  # Yellow
F_ERR="\033[1;31m"   # Red
F_RESET="\033[0m"

# 進入兵工廠模式
function _enter_factory_mode() {
    clear
    _bot_say "system" "Initializing Factory Protocol..."
    sleep 0.5
    
    _factory_auto_backup

    while true; do
        clear
        _draw_logo "factory"
        
        echo -e "${F_MAIN} :: Mux-OS Factory Mode :: ${F_SUB}Target: app.sh${F_RESET}"
        echo -e "${F_MAIN} :: Status: ${F_WARN}UNLOCKED (Write-Access Granted)${F_RESET}"
        echo ""
        echo -e " ${F_SUB}[ COMMANDS ]${F_RESET}"
        echo -e "  ${F_MAIN}fac menu${F_RESET}   : Open Neural Forge (FZF)"
        echo -e "  ${F_MAIN}fac list${F_RESET}   : List current links"
        echo -e "  ${F_MAIN}fac deploy${F_RESET} : Save & Exit (Manual Reload)"
        echo -e "  ${F_MAIN}fac help${F_RESET}   : Show instructions"
        echo ""
        
        read -p " factory › " input
        
        case "$input" in
            "fac menu"|"fac m")
                _factory_fzf_menu
                ;;
            "fac list"|"fac l")
                _factory_list_links
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            "fac deploy"|"fac d"|"exit"|"quit")
                _factory_deploy_sequence
                if [ $? -eq 0 ]; then break; fi
                ;;
            "fac help"|"fac h")
                _factory_help
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            "mux"*)
                echo -e "\n${F_ERR} [SYSTEM LOCK] 'mux' commands are disabled in Factory Mode.${F_RESET}"
                echo -e "${F_WARN} :: Use 'fac' to operate.${F_RESET}"
                _bot_say "error" "Don't cross the streams. Use 'fac'."
                sleep 1.5
                ;;
            "clear")
                clear
                ;;
            "")
                ;;
            *)
                echo -e "\n${F_ERR} :: Unknown directive.${F_RESET}"
                ;;
        esac
    done
    
    clear
    _draw_logo "core"
    echo -e "\033[1;36m :: System control returned to Core.\033[0m"
    echo -e "\033[1;30m    (Type 'mux reload' to apply changes)\033[0m"
}

# 自動備份機制
function _factory_auto_backup() {
    local bak_dir="$MUX_ROOT/bak"
    if [ ! -d "$bak_dir" ]; then mkdir -p "$bak_dir"; fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp "$MUX_ROOT/app.sh" "$bak_dir/app.sh_$timestamp"
    
    ls -t "$bak_dir"/app.sh_* 2>/dev/null | tail -n +4 | xargs rm -- 2>/dev/null
    
    echo -e "${F_WARN} :: Auto-Backup Secure. [Slot 1/3]${F_RESET}"
    sleep 0.5
}

# Factory 部署序列
function _factory_deploy_sequence() {
    echo ""
    echo -e "${F_MAIN} :: Initiate Deployment Sequence?${F_RESET}"
    echo -e "${F_SUB}    This will overwrite neural pathways and exit Factory.${F_RESET}"
    echo ""
    echo -ne "${F_WARN} :: Type 'CONFIRM' to execute: ${F_RESET}"
    read confirm
    
    if [ "$confirm" == "CONFIRM" ]; then
        echo ""
        _bot_say "success" "Changes committed. Neural map updated."
        
        local time_str="# :: Last Sync: $(date '+%Y-%m-%d %H:%M:%S') ::"
        
        if grep -q "Last Sync" "$MUX_ROOT/app.sh"; then
            sed -i "1s|.*Last Sync.*|$time_str|" "$MUX_ROOT/app.sh"
        else
            sed -i "1i $time_str" "$MUX_ROOT/app.sh"
        fi
        
        sleep 1
        return 0
    else
        echo -e "\n${F_ERR} :: Deployment aborted. Returning to Forge.${F_RESET}"
        sleep 1
        return 1
    fi
}

# FZF 鍛造選單 (骨架)
function _factory_fzf_menu() {
    echo -e "\n${F_MAIN} :: Neural Forge (FZF) under construction...${F_RESET}"
    sleep 1
}

function _factory_list_links() {
    echo -e "\n${F_MAIN} :: Current Neural Links:${F_RESET}"
    grep "^function" "$MUX_ROOT/app.sh" | sed 's/function //' | sed 's/() {//' | column
    echo ""
}

function _factory_help() {
    echo -e "\n${F_MAIN} :: Factory Manual ::${F_RESET}"
    echo " 1. Use 'fac menu' to create/edit functions."
    echo " 2. 'mux' commands are locked for safety."
    echo " 3. Always 'fac deploy' to save your work."
}