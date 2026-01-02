#!/bin/bash

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

# factory.sh - Mux-OS 兵工廠

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
    
    cp "$MUX_ROOT/app.sh" "$MUX_ROOT/app.sh.temp"
    source "$MUX_ROOT/app.sh.temp"

    _factory_mask_apps

    _factory_auto_backup > /dev/null 2>&1

    if command -v _fac_init &> /dev/null; then
        _fac_init
    else
        clear
        _draw_logo "factory"
    fi
    
    _bot_say "factory_welcome"
}

# 啟動序列 (Boot Sequence)
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
        echo -e "\n\033[1;32m :: ACCESS GRANTED :: \033[0m"
        sleep 1
        echo ""
        echo -e "${F_ERR} :: WARNING: FACTORY PROTOCOL :: ${F_RESET}"
        echo -e "${F_SUB} 1. Modifications here are permanent.${F_RESET}"
        echo -e "${F_SUB} 2. Sandbox Environment Active (.temp).${F_RESET}"
        echo -e "${F_SUB} 3. Core 'mux' commands are ${F_ERR}LOCKED${F_SUB}. Use 'fac'.${F_RESET}"
        echo -e "${F_SUB} 4. App launches are ${F_ERR}LOCKED${F_SUB} (Except: wb, apklist).${F_RESET}"
        echo -e "${F_SUB} 5. You are responsible for system stability.${F_RESET}"
        echo ""
        _system_unlock
        echo -ne "${F_WARN} :: Proceed? [y/n]: ${F_RESET}"
        read choice
        
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            _factory_eject_sequence "User aborted."
            return 1
        fi
        
        _system_lock
        local steps=("Injecting Logic..." "Desynchronizing Core..." "Loading Arsenal..." "Entering Factory...")
        for step in "${steps[@]}"; do
            echo -e "${F_GRAY}    ›› $step${F_RESET}"
            sleep 0.6
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
    if [ -f "$MUX_ROOT/app.sh.temp" ]; then rm "$MUX_ROOT/app.sh.temp"; fi
    export __MUX_MODE="core"
    source "$MUX_ROOT/app.sh"

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
    _bot_say "eject"
    sleep 2.6
    _system_unlock
    clear
    mux reload
}

# 兵工廠重置 (Factory Reset - Phoenix Protocol)
function _factory_reset() {
    echo ""
    echo -e "${F_ERR} :: CRITICAL WARNING :: FACTORY RESET DETECTED ::${F_RESET}"
    echo -e "${F_GRAY}    This will wipe ALL changes (Sandbox & Production) and pull from Origin.${F_RESET}"
    echo -ne "${F_ERR} :: TYPE 'CONFIRM' TO NUKE: ${F_RESET}"
    read confirm

    if [ "$confirm" == "CONFIRM" ]; then
        _bot_say "loading" "Obliterating timeline..."
        
        git fetch --all >/dev/null 2>&1
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
        git reset --hard "origin/$branch" >/dev/null 2>&1
        chmod +x "$MUX_ROOT/"*.sh
        
        cp "$MUX_ROOT/app.sh" "$MUX_ROOT/app.sh.temp"
        source "$MUX_ROOT/app.sh.temp"
        
        _factory_mask_apps
        
        _fac_init
        _bot_say "success" "Factory reset complete. Timeline synchronized."
    else
        echo -e "${F_GRAY}    ›› Reset aborted.${F_RESET}"
    fi
}


# 兵工廠指令入口 - Factory Command Entry
# === Fac ===

# : Factory Command Entry
function fac() {
    local cmd="$1"
    
    if [ "$__MUX_MODE" != "factory" ]; then
        echo -e "\033[1;31m :: Error: Link Offline. Use 'mux fac'.\033[0m"
        return 1
    fi

    if [ -z "$cmd" ]; then
        _bot_say "factory_welcome"
        return
    fi

    case "$cmd" in
        # : Open Neural Forge (FZF)
        "menu"|"m")
            _factory_fzf_menu
            ;;

        # : List all links
        "list"|"l")
            echo -e "${F_MAIN} :: Current Sandbox Links:${F_RESET}"
            grep "^function" "$MUX_ROOT/app.sh.temp" | sed 's/function //' | sed 's/() {//' | column
            echo ""
            ;;

        # : Show Factory Status
        "status"|"st")
            if command -v _factory_show_status &> /dev/null; then
                _factory_show_status
            else
                echo -e "${F_WARN} :: UI Module Link Failed.${F_RESET}"
            fi
            ;;
            
        # : Edit Function
        "edit") 
            echo -e "${F_WARN} :: Neural Editor (Nano) Integration... Pending.${F_RESET}"
            ;;

        # : Load Function
        "load") 
            echo -e "${F_WARN} :: Dry Run Protocol... Pending.${F_RESET}" 
            ;;

        # : Delete Function
        "del") 
            echo -e "${F_WARN} :: Deletion Protocol... Pending.${F_RESET}" 
            ;;

        # : Show Factory Info
        "info"|"i")
            if command -v _factory_show_info &> /dev/null; then
                _factory_show_info
            fi
            ;;

        # : Deploy Changes
        "deploy"|"dep"|"exit")
            _factory_deploy_sequence
            ;;

        # : Reload Factory
        "reload"|"r")
            _fac_init
            _bot_say "factory_welcome"
            ;;
            
        # Reset Factory Change
        "reset")
            _factory_reset
            ;;

        "help"|"h")
                _mux_dynamic_help_factory
            ;;

        *)
            echo -e "${F_SUB} :: Unknown Directive: $cmd${F_RESET}"
            ;;
    esac
}

# 自動備份 - Auto Backup
function _factory_auto_backup() {
    local bak_dir="$MUX_ROOT/bak"
    [ ! -d "$bak_dir" ] && mkdir -p "$bak_dir"
    cp "$MUX_ROOT/app.sh" "$bak_dir/app.sh_$(date +%Y%m%d_%H%M%S)"
    ls -t "$bak_dir"/app.sh_* 2>/dev/null | tail -n +4 | xargs rm -- 2>/dev/null
}

# 部署序列 (Deploy Sequence)
function _factory_deploy_sequence() {
    echo ""
    echo -ne "${F_GRAY} :: Initiating Deployment Sequence...${F_RESET}"
    sleep 2.6
    
    clear
    _draw_logo "gray"
    
    echo -e "${F_MAIN} :: MANIFEST CHANGES (Sandbox vs Production) ::${F_RESET}"
    echo ""
    
    if command -v diff &> /dev/null; then
        diff -U 0 "$MUX_ROOT/app.sh" "$MUX_ROOT/app.sh.temp" | grep -v "^---" | grep -v "^+++" | grep -v "^@" | head -n 20
    else
        echo -e "${F_WARN}    (Diff module unavailable. Changes hidden.)${F_RESET}"
    fi
    echo ""
    
    _system_unlock
    echo -ne "${F_WARN} :: Modifications verified? [y/n]: ${F_RESET}"
    read choice
    
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        _fac_init
        _bot_say "factory_welcome" "Deployment canceled. Resume editing."
        return
    fi
    
    echo ""
    echo -e "${F_ERR} :: CRITICAL WARNING ::${F_RESET}"
    echo -e "${F_SUB}    Sandbox (.temp) will OVERWRITE Production (app.sh).${F_RESET}"
    echo -e "${F_SUB}    This action is irreversible via undo.${F_RESET}"
    echo ""
    echo -ne "${F_ERR} :: TYPE 'CONFIRM' TO DEPLOY: ${F_RESET}"
    read confirm
    
    if [ "$confirm" != "CONFIRM" ]; then
        _fac_init
        _bot_say "error" "Confirmation failed. Deployment aborted."
        return
    fi

    _bot_say "deploy_start"
    sleep 1.5
    
    local time_str="# :: Last Sync: $(date '+%Y-%m-%d %H:%M:%S') ::"
    local temp_file="$MUX_ROOT/app.sh.temp"
    local prod_file="$MUX_ROOT/app.sh"

    if [ -f "$temp_file" ]; then
         if grep -q "Last Sync" "$temp_file"; then
            sed -i "1s|.*Last Sync.*|$time_str|" "$temp_file"
         else
            sed -i "1i $time_str" "$temp_file"
         fi
         mv "$temp_file" "$prod_file"
    else
         _bot_say "error" "Sandbox integrity failed."
         return 1
    fi
    
    echo ""
    echo -e "${F_MAIN} :: DEPLOYMENT SUCCESSFUL ::${F_RESET}"
    echo -e "${F_SUB}    System requires manual reload to re-align kernel.${F_RESET}"
    echo ""
    echo -e "${F_ERR} [SYSTEM HALTED] Waiting for manual restart...${F_RESET}"
    echo ""
    
    if [ -f "$temp_file" ]; then rm "$temp_file"; fi
    export __MUX_MODE="core"
    
    while true; do
        _system_unlock
        echo -ne "${F_WARN} :: Type 'mux reload' to reboot: ${F_RESET}"
        read reboot_cmd
        
        if [ "$reboot_cmd" == "mux reload" ]; then
            mux reload
            break
        else
            echo -e "${F_ERR} :: Command rejected. System is halted.${F_RESET}"
        fi
    done
}

# 列出所有連結函式 (List All Linked Functions)
function _factory_list_links() {
    echo -e "${F_MAIN} :: Current Neural Links:${F_RESET}"
    grep "^function" "$MUX_ROOT/app.sh" | sed 's/function //' | sed 's/() {//' | column
    echo ""
}

# 神經鍛造 (Neural Forge)
function _factory_fzf_menu() {
    echo -e "${F_MAIN} :: Neural Forge (FZF) under construction...${F_RESET}"
}

# 初始化視覺效果 (Initialize Visuals)
function _fac_init() {
    clear
    _draw_logo "factory"
    _system_check "factory"
    _show_hud "factory"
}

# 函式攔截器 (Function Interceptor)
function _factory_mask_apps() {
    local targets=("$MUX_ROOT/system.sh" "$MUX_ROOT/app.sh.temp" "$MUX_ROOT/vendor.sh")
    
    for file in "${targets[@]}"; do
        if [ -f "$file" ]; then
            local funcs=$(grep "^function" "$file" | sed 's/function //' | sed 's/() {//' | grep -v "^_")
            
            for func_name in $funcs; do
                case "$func_name" in
                    "apklist"|"wb"|"termux") 
                        continue 
                        ;;
                esac

                eval "function $func_name() { _factory_interceptor \"$func_name\" \"\$@\"; }"
            done
        fi
    done
}

# 函式攔截處理 (Interceptor Handler)
function _factory_interceptor() {
    local func_name="$1"
    
    echo -e "${F_ERR} :: WARNING: Target '$func_name' is locked in Modification Mode.${F_RESET}"
    
    _bot_say "error" "Function locked. Use 'fac' commands to modify."
}