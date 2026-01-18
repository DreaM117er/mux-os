#!/bin/bash

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

# factory.sh - Mux-OS 兵工廠

F_MAIN="\033[1;38;5;208m"
F_SUB="\033[1;37m"
F_WARN="\033[1;33m"
F_ERR="\033[1;31m"
F_GRAY="\033[1;30m"
F_RESET="\033[0m"
F_GRE="\n\033[1;32m"

# 兵工廠系統啟動 (Factory System Boot)
function _factory_system_boot() {
    export __MUX_MODE="factory"

    # 前置作業
    if [ -f "$MUX_ROOT/app.csv" ]; then
        cp "$MUX_ROOT/app.csv" "$MUX_ROOT/app.csv.temp"
    else
        echo '"CATNO","COMNO","CATNAME","TYPE","COM","COM2","COM3","HUDNAME","UINAME","PKG","TARGET","IHEAD","IBODY","URI","MIME","CATE","FLAG","EX","EXTRA","ENGINE"' > "$MUX_ROOT/app.csv.temp"
    fi
    
    # 製作.bak檔案
    local ts=$(date +%Y%m%d%H%M%S)
    local session_bak="$MUX_BAK/app.csv.bak.$ts"
    cp "$MUX_ROOT/app.csv" "$session_bak"

    # 初始化介面
    if command -v _fac_init &> /dev/null; then
        _fac_init
    else
        clear
        _draw_logo "factory"
    fi

    _bot_say "factory_welcome"
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
    if [ "$__MUX_MODE" == "core" ]; then
        _bot_say "fail" "[mux] command not found."
        return 1
    fi

    if [ -z "$cmd" ]; then
        _bot_say "factory_welcome"
        return
    fi

    case "$cmd" in
        # : Open Neural Forge Menu
        "menu"|"commenu"|"comm")
            while true; do
                local target=$(_factory_fzf_menu "Select App to Inspect")
                if [ -z "$target" ]; then break; fi
                _factory_fzf_detail_view "$target"
            done
            ;;

        # : Open Category Menu
        "catmenu"|"catm")
            while true; do
                local cat_id=$(_factory_fzf_cat_selector)
                if [ -z "$cat_id" ]; then break; fi
                while true; do
                    local target_cmd=$(_factory_fzf_cmd_in_cat "$cat_id")
                    if [ -z "$target_cmd" ]; then break; fi
                    _factory_fzf_detail_view "$target_cmd"
                done
            done
            ;;

        # : Check & Fix Formatting
        "check")
            _fac_maintenance
            ;;

        # : List all links
        "list"|"ls")
            _fac_list
            ;;

        # : Show Factory Status
        "status"|"sts")
            if command -v _factory_show_status &> /dev/null; then
                _factory_show_status
            else
                echo -e "${F_WARN} :: UI Module Link Failed.${F_RESET}"
            fi
            ;;

        # : Neural Forge (Create Command)
        "add"|"new") 
            echo -e "${F_SUB} :: Command Need Build${F_RESET}"
            ;;

        # : Edit Neural (Edit Command)
        "edit")
            echo -e "${F_SUB} :: Command Need Build${F_RESET}"
            ;;

        # : Load Neural (Test Command)
        "load"|"test") 
            echo -e "${F_SUB} :: Command Need Build${F_RESET}"
            ;;

        # : Break Neural (Delete Command)
        "del") 
            echo -e "${F_SUB} :: Command Need Build${F_RESET}"
            ;;

        # : Time Stone Undo (Rebak)
        "undo"|"rebak")
            _fac_rebak_wizard
            ;;

        # : Show Factory Info
        "info")
            if command -v _factory_show_info &> /dev/null; then
                _factory_show_info
            fi
            ;;

        # : Reload Factory
        "reload")
            echo -e "\033[1;33m :: Cycling Factory Power... \033[0m"
            sleep 0.5
            if [ -f "$MUX_ROOT/gate.sh" ]; then
                exec "$MUX_ROOT/gate.sh" "factory"
            else
                exec bash
            fi
            ;;
            
        # : Reset Factory Change
        "reset")
            _factory_reset
            ;;

        # : Deploy Changes
        "deploy")
            _factory_deploy_sequence
            ;;

        "help")
            _mux_dynamic_help_factory
            ;;

        *)
            echo -e "${F_SUB} :: Unknown Directive: $cmd${F_RESET}"
            ;;
    esac
}

# 兵工廠快速列表 - List all commands
function _fac_list() {
    local target_file="$MUX_ROOT/app.csv.temp"
    
    echo -e "${F_WARN} :: Mux-OS Command Registry :: ${F_RESET}"
    
    awk -F, 'NR>1 {
        gsub(/^"|"$/, "", $5); com=$5
        gsub(/^"|"$/, "", $6); sub=$6
        
        if (com != "") {
            if (sub != "") {
                print " " com " " sub
            } else {
                print " " com
            }
        }
    }' "$target_file" | sort
    
    echo -e "${F_GRAY} :: End of List :: ${F_RESET}"
}















# 自動備份 - Auto Backup
function _factory_auto_backup() {
    local ts=$(date +%Y%m%d%H%M%S)
    local atb_file="$MUX_BAK/app.csv.atb.$ts"
    
    cp "$MUX_ROOT/app.csv.temp" "$atb_file"
    
    local count=$(ls -1 "$MUX_BAK"/app.csv.atb.* 2>/dev/null | wc -l)
    
    if [ "$count" -gt 9 ]; then
        local oldest=$(ls -1t "$MUX_BAK"/app.csv.atb.* 2>/dev/null | tail -n 1)
        if [ -n "$oldest" ]; then
            rm "$oldest"
        fi
    fi
}

# 災難復原精靈 - Recovery Wizard
function _fac_rebak_wizard() {
    local bak_dir="$MUX_BAK"
    
    if [ ! -d "$bak_dir" ]; then
        _bot_say "error" "No Backup Repository Found."
        return 1
    fi

    local list=$(find "$bak_dir" -maxdepth 1 -name "app.csv.*" -type f -printf "%T@ %f\n" | sort -rn | awk '{print $2}')
    
    if [ -z "$list" ]; then
        _bot_say "warn" "Backup Repository is Empty."
        return 1
    fi

    local selected=$(echo "$list" | fzf --ansi \
        --height=40% --layout=reverse --border=bottom \
        --prompt=" :: Restore Checkpoint › " \
        --header=" :: Select a backup to restore to Workspace (.temp) :: " \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:208 \
        --preview="head -n 5 $bak_dir/{}" --preview-window=up:30%)

    if [ -n "$selected" ]; then
        echo -e "${F_WARN} :: WARNING: This will overwrite your current workspace!${F_RESET}"
        echo -ne "    ›› Restore [${selected}]? (y/N): "
        read -r confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            cp "$bak_dir/$selected" "$MUX_ROOT/app.csv.temp"
            _bot_say "neural" "Workspace Restored from: $selected"
        else
            _bot_say "neural" "Restore Canceled."
        fi
    fi
}

# 部署序列 (Deploy Sequence)
function _factory_deploy_sequence() {
    echo ""
    echo -ne "${F_WARN} :: Initiating Deployment Sequence...${F_RESET}"
    sleep 1.5
    
    clear
    _draw_logo "gray"
    
    echo -e "${F_MAIN} :: MANIFEST CHANGES (Sandbox vs Production) ::${F_RESET}"
    echo ""
    
    if command -v diff &> /dev/null; then
        diff -U 0 "$MUX_ROOT/app.csv" "$MUX_ROOT/app.csv.temp" | \
        grep -v "^---" | grep -v "^+++" | grep -v "^@" | head -n 20 | \
        awk '
            /^\+/ {print "\033[1;32m" $0 "\033[0m"; next}
            /^-/ {print "\033[1;31m" $0 "\033[0m"; next}
            {print}
        '
    else
        echo -e "${F_WARN}    (Diff module unavailable. Changes hidden.)${F_RESET}"
    fi
    echo ""
    
    _system_unlock
    echo -ne "${F_WARN} :: Modifications verified? [Y/n]: ${F_RESET}"
    read choice
    
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        _fac_init
        echo -e ""
        _bot_say "factory" "Deployment canceled. Sandbox state retained."
        echo -e "${F_GRAY}    ›› To discard changes: type 'fac reset'${F_RESET}"
        echo -e "${F_GRAY}    ›› To resume editing : type 'fac edit'${F_RESET}"
        return
    fi
    
    echo ""
    echo -e "${F_ERR} :: CRITICAL WARNING ::${F_RESET}"
    echo -e "${F_SUB}    Sandbox (.temp) will OVERWRITE Production (app.csv).${F_RESET}"
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
    sleep 1.0
    
    local temp_file="$MUX_ROOT/app.csv.temp"
    local prod_file="$MUX_ROOT/app.csv"

    if [ -f "$temp_file" ]; then
        mv "$temp_file" "$prod_file"
        cp "$prod_file" "$temp_file"
         
        if [ -n "$__MUX_SESSION_BAK" ] && [ -f "$__MUX_SESSION_BAK" ]; then
            rm "$__MUX_SESSION_BAK"
        fi
    else
         _bot_say "error" "Sandbox integrity failed."
         return 1
    fi
    
    echo ""
    echo -e "${F_MAIN} :: DEPLOYMENT SUCCESSFUL ::${F_RESET}"
    sleep 1.9
    
    if [ -f "$MUX_ROOT/gate.sh" ]; then
        exec "$MUX_ROOT/gate.sh" "core"
    else
        echo "core" > "$MUX_ROOT/.mux_state"
        exec bash
    fi
}

# 機體維護工具 (Mechanism Maintenance)
function _fac_maintenance() {
    local targets=("$MUX_ROOT/app.csv.temp" "$MUX_ROOT/system.csv" "$MUX_ROOT/vendor.csv")
    
    echo -e "${F_MAIN} :: Initiating Mechanism Maintenance (Data Integrity)...${F_RESET}"
    
    for file in "${targets[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${F_GRAY}    ›› Scanning: $(basename "$file")...${F_RESET}"
            
            if [ -n "$(tail -c 1 "$file")" ]; then
                echo "" >> "$file"
                echo -e "${F_WARN}    ›› Missing EOF newline. Fixed. ✅${F_RESET}"
            fi
            
            local row_count=$(wc -l < "$file")
            
            if [ "$row_count" -gt 1 ]; then
                local header=$(head -n 1 "$file")
                local body_raw=$(tail -n +2 "$file")
                
                local body_sorted=$(echo "$body_raw" | sort -t',' -k1,1n -k2,2n)
                
                if [ "$body_raw" != "$body_sorted" ]; then
                    echo -e "${F_WARN}    ›› Detected disorder in Index Sequence (CATNO/COMNO).${F_RESET}"
                    echo -ne "${F_WARN}    ›› Re-index structure? [Y/n]: ${F_RESET}"
                    read choice
                    
                    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                        echo "$header" > "$file"
                        echo "$body_sorted" >> "$file"
                        echo -e "${F_WARN}    ›› Sequence Normalized. ✅${F_RESET}"
                    else
                        echo -e "${F_GRAY}    ›› Optimization skipped.${F_RESET}"
                    fi
                else
                    echo -e "    ›› Index Sequence Verified. \033[1;32mOK\033[0m."
                fi
            fi
        fi
    done
    sleep 0.5
    echo -e ""
    _bot_say "factory" "Mechanism maintenance complete, Commander."
}

# 初始化視覺效果 (Initialize Visuals)
function _fac_init() {
    _system_lock
    _safe_ui_calc
    clear
    _draw_logo "factory"
    _system_check "factory"
    _show_hud "factory"
    _system_unlock
}

# 函式攔截器 (Function Interceptor)
function _factory_mask_apps() {
    local target_cmd="$1"
    
    if [[ "$target_cmd" == "wb" || "$target_cmd" == "apklist" ]]; then
        return 0
    fi

    local lock_list=(
        "$MUX_ROOT/app.csv.temp"
        "$MUX_ROOT/system.csv"
        "$MUX_ROOT/vendor.csv"
    )

    for csv_file in "${lock_list[@]}"; do
        if [ -f "$csv_file" ]; then
            local is_masked=$(awk -F, -v q_com="$input_com" -v q_sub="$input_sub" '
                NR>1 {
                    gsub(/^"|"$/, "", $5); c=$5
                    gsub(/^"|"$/, "", $6); s=$6
                    
                    if (c == q_com && s == q_sub) {
                        print "LOCKED"
                        exit
                    }
                }
            ' "$csv_file")

            if [ "$is_masked" == "LOCKED" ]; then
                if [ -n "$input_sub" ]; then
                    _bot_say "warn" "Factory Lock: [$input_com $input_sub] is restricted."
                else
                    _bot_say "warn" "Factory Lock: [$input_com] is restricted."
                fi
                return 1
            fi
        fi
    done

    return 0
}

# 部署模組 - Deployment Module
function _fac_deploy() {
    echo -e "\n\033[1;33m :: Initiating Deployment Sequence... \033[0m"
    
    _mux_integrity_scan
    if [ $? -ne 0 ]; then
        _bot_say "error" "Integrity check failed. Aborting."
        return 1
    fi
    
    mv "$MUX_ROOT/app.sh.temp" "$MUX_ROOT/app.sh"
    _mux_uplink
    echo -e "\033[1;32m :: System Reloading... \033[0m"
    sleep 1
    echo "core" > "$MUX_ROOT/.mux_state"
    unset MUX_INITIALIZED
    unset __MUX_TARGET_MODE
    exec bash
}

# 離開工廠 - Exit Factory
function _fac_exit() {
    if [ -f "$MUX_ROOT/gate.sh" ]; then
        exec "$MUX_ROOT/gate.sh" "core"
    else
        echo "core" > "$MUX_ROOT/.mux_state"
        exec bash
    fi
}
