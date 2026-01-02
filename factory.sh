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
        echo -e "${F_GRE} :: ACCESS GRANTED :: \033[0m${F_RESET}"
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

        # : Neural Forge (Create Command)
        "add"|"create") 
            _fac_wizard_create
            ;;

        # : Load Neural (Test Command)
        "load") 
            _fac_load
            ;;

        # : Break Neural (Delete Command)
        "del") 
            _fac_del "$2"
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

# 新增模組 - Create Module
function _fac_wizard_create() {
    echo -e "${F_MAIN} :: Neural Link Fabrication Protocol ::${F_RESET}"
    echo -e "${F_MAIN} :: Select Core Type ::${F_RESET}"
    echo -e "${F_SUB}    [1] Normal APP (Standard Launcher)${F_RESET}"
    echo -e "${F_SUB}    [2] Browser APP (Smart Search)${F_RESET}"
    echo -e ""
    echo -ne "${F_WARN} :: Select: ${F_RESET}"
    read type_choice

    case "$type_choice" in
        1) 
            _fac_stamp_launcher 
            ;;
        2) 
            _fac_stamp_browser
            ;;
        *) 
            _bot_say "error" "Invalid type selection."
            ;;
    esac
}

# 鑄造工序：標準啟動器 - Standard Launcher Stamp
function _fac_stamp_launcher() {
    local mold_file="$MUX_ROOT/plate/template.txt"
    
    if [ ! -f "$mold_file" ]; then 
        _bot_say "error" "Launcher mold missing ($mold_file)."
        return 1
    fi

    # Step 1: Pre-flight
    echo -ne "${F_WARN} :: Launch 'apklist' helper? (y/n): ${F_RESET}"
    read launch_apk
    if [[ "$launch_apk" == "y" || "$launch_apk" == "Y" ]]; then
        apklist
    fi

    # Step 2: Data Collection
    # 2.1 UI Display Name
    echo -e ""
    echo -ne "${F_SUB} :: UI Display Name (e.g. YouTube): ${F_RESET}"
    read app_name
    [ -z "$app_name" ] && app_name="Unknown App"

    # 2.2 Package Name
    echo -ne "${F_SUB} :: Package Name (Enter to skip): ${F_RESET}"
    read pkg_id
    
    if [ -z "$pkg_id" ]; then 
        echo -e "${F_WARN}    ›› No Package ID detected. Using placeholder.${F_RESET}"
        pkg_id="com.null.placeholder"
    fi

    # 2.3 Activity Name
    echo -ne "${F_SUB} :: Activity Name (Optional): ${F_RESET}"
    read pkg_act

    # 2.4 Command Name (Auto-Gen Fix)
    echo -e ""
    echo -ne "${F_MAIN} :: Assign Command Name (Enter to auto-gen): ${F_RESET}"
    read input_func
    
    local func_name=""
    if [ -z "$input_func" ]; then
        local clean_name=$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
        func_name="$clean_name"
        echo -e "${F_WARN}    ›› Auto-assigned command: $func_name${F_RESET}"
    else
        func_name="$input_func"
    fi

    if [ -z "$func_name" ]; then
        _bot_say "error" "Command name generation failed."
        return 1
    fi

    # Step 3: Safety Check
    if grep -qE "function[[:space:]]+$func_name[[:space:]]*\(" "$MUX_ROOT/app.sh.temp"; then
        _bot_say "error" "Module '$func_name' already exists."
        return 1
    fi

    # Step 4: Category Selection
    _fac_select_category 
    
    if [ -z "$INSERT_LINE" ]; then
        _bot_say "error" "Placement calculation failed."
        return 1
    fi

    # Step 5: Final Manifest Review
    echo -e ""
    echo -e "${F_MAIN} :: Final Manifest Review ::${F_RESET}"
    echo -e "${F_GRAY}    --------------------------------${F_RESET}"
    echo -e "${F_GRAY}    Sector   : ${F_WARN}$CATEGORY_NAME${F_RESET}"
    echo -e "${F_GRAY}    Command  : ${F_WARN}$func_name${F_RESET}"
    echo -e "${F_GRAY}    Package  : $pkg_id${F_RESET}"
    echo -e "${F_GRAY}    Activity : ${pkg_act:-[Auto]}${F_RESET}"
    echo -e "${F_GRAY}    --------------------------------${F_RESET}"
    
    echo -ne "${F_ERR}    ›› TYPE 'CONFIRM' TO FORGE: ${F_RESET}"
    read confirm_write
    
    if [ "$confirm_write" != "CONFIRM" ]; then
        echo -e ""
        _bot_say "error" "Authentication Failed. Fabrication Aborted."
        echo -e "${F_GRAY}    ›› Material scrapped. All data discarded.${F_RESET}"
        return 1
    fi

    # Step 6: Assembly
    _bot_say "factory" "Stamping module..."

    local temp_block="$MUX_ROOT/plate/block.tmp"
    
    cat "$mold_file" \
        | sed "s/\[FUNC\]/$func_name/g" \
        | sed "s/\[NAME\]/$app_name/g" \
        | sed "s/\[PKG_ID\]/$pkg_id/g" \
        | sed "s/\[PKG_ACT\]/$pkg_act/g" \
        > "$temp_block"
    
    local total_lines=$(wc -l < "$MUX_ROOT/app.sh.temp")
    if [ "$INSERT_LINE" -ge "$total_lines" ]; then
        cat "$temp_block" >> "$MUX_ROOT/app.sh.temp"
    else
        sed -i "${INSERT_LINE}r $temp_block" "$MUX_ROOT/app.sh.temp"
    fi
    rm "$temp_block"
    
    local last_char=$(tail -c 1 "$MUX_ROOT/app.sh.temp")
    if [ "$last_char" != "" ]; then echo "" >> "$MUX_ROOT/app.sh.temp"; fi

    echo -e "${F_GRE} :: Module Installed Successfully ::${F_RESET}"
    echo -e ""
    
    # Step 7: Reload
    echo -ne "${F_WARN} :: Hot Reload now? (y/n): ${F_RESET}"
    read reload_choice
    if [[ "$reload_choice" == "y" || "$reload_choice" == "Y" ]]; then
        _fac_load
    fi
}

# 鑄造工序：瀏覽器應用 (Browser App Stamp)
function _fac_stamp_browser() {
    local mold_file="$MUX_ROOT/plate/browser.txt"
    
    if [ ! -f "$mold_file" ]; then 
        _bot_say "error" "Browser mold missing ($mold_file)."
        return 1
    fi

    # Step 1: Pre-flight (APK Check
    echo -ne "${F_WARN} :: Launch 'apklist' helper? (y/n): ${F_RESET}"
    read launch_apk
    if [[ "$launch_apk" == "y" || "$launch_apk" == "Y" ]]; then
        apklist
    fi

    # Step 2: Data Collection
    # 2.1 UI Display Name
    echo -e ""
    echo -ne "${F_SUB} :: UI Display Name (e.g. Brave): ${F_RESET}"
    read app_name
    [ -z "$app_name" ] && app_name="Unknown Browser"

    # 2.2 Package Name
    echo -ne "${F_SUB} :: Package Name (Enter to skip): ${F_RESET}"
    read pkg_id
    
    if [ -z "$pkg_id" ]; then 
        echo -e "${F_WARN}    ›› No Package ID detected. Using placeholder.${F_RESET}"
        pkg_id="com.null.browser"
    fi

    # 2.3 Activity Name (Optional)
    echo -ne "${F_SUB} :: Activity Name (Optional): ${F_RESET}"
    read pkg_act

    # 2.4 Search Engine Selection (Browser Exclusive)
    echo -e ""
    echo -e "${F_MAIN} :: Select Default Search Engine ::${F_RESET}"
    echo -e "${F_SUB}    [1] Google${F_RESET}"
    echo -e "${F_SUB}    [2] Bing${F_RESET}"
    echo -e "${F_SUB}    [3] DuckDuckGo${F_RESET}"
    echo -e "${F_SUB}    [4] YouTube${F_RESET}"
    echo -e "${F_SUB}    [5] GitHub${F_RESET}"
    echo -ne "${F_WARN}    ›› Select Engine: ${F_RESET}"
    read engine_choice

    local engine_var="GOOGLE" # Default
    case "$engine_choice" in
        1) engine_var="GOOGLE" ;;
        2) engine_var="BING" ;;
        3) engine_var="DUCK" ;;
        4) engine_var="YOUTUBE" ;;
        5) engine_var="GITHUB" ;;
        *) engine_var="GOOGLE" ;;
    esac

    # 2.5 Command Name (Auto-Gen)
    echo -e ""
    echo -ne "${F_MAIN} :: Assign Command Name (Enter to auto-gen): ${F_RESET}"
    read input_func
    
    local func_name=""
    if [ -z "$input_func" ]; then
        local clean_name=$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
        func_name="$clean_name"
        echo -e "${F_WARN}    ›› Auto-assigned command: $func_name${F_RESET}"
    else
        func_name="$input_func"
    fi

    if [ -z "$func_name" ]; then
        _bot_say "error" "Command name generation failed."
        return 1
    fi

    # Step 3: Safety Check
    if grep -qE "function[[:space:]]+$func_name[[:space:]]*\(" "$MUX_ROOT/app.sh.temp"; then
        _bot_say "error" "Module '$func_name' already exists."
        return 1
    fi

    # Step 4: Category Selection
    _fac_select_category 
    
    if [ -z "$INSERT_LINE" ]; then
        _bot_say "error" "Placement calculation failed."
        return 1
    fi

    # Step 5: Final Manifest Review
    echo -e ""
    echo -e "${F_MAIN} :: Final Manifest Review ::${F_RESET}"
    echo -e "${F_GRAY}    --------------------------------${F_RESET}"
    echo -e "${F_GRAY}    Type     : ${F_MAIN}Browser Module${F_RESET}"
    echo -e "${F_GRAY}    Sector   : ${F_WARN}$CATEGORY_NAME${F_RESET}"
    echo -e "${F_GRAY}    Command  : ${F_WARN}$func_name${F_RESET}"
    echo -e "${F_GRAY}    Engine   : ${F_SUB}$engine_var${F_RESET}"
    echo -e "${F_GRAY}    Package  : $pkg_id${F_RESET}"
    echo -e "${F_GRAY}    Activity : ${pkg_act:-[Auto]}${F_RESET}"
    echo -e "${F_GRAY}    --------------------------------${F_RESET}"
    
    echo -ne "${F_ERR}    ›› TYPE 'CONFIRM' TO FORGE: ${F_RESET}"
    read confirm_write
    
    if [ "$confirm_write" != "CONFIRM" ]; then
        echo -e ""
        _bot_say "error" "Authentication Failed. Fabrication Aborted."
        echo -e "${F_GRAY}    ›› Material scrapped. All data discarded.${F_RESET}"
        return 1
    fi

    # Step 6: Assembly
    _bot_say "factory" "Stamping browser module..."

    local temp_block="$MUX_ROOT/plate/block.tmp"
    
    cat "$mold_file" \
        | sed "s/\[FUNC\]/$func_name/g" \
        | sed "s/\[NAME\]/$app_name/g" \
        | sed "s/\[PKG_ID\]/$pkg_id/g" \
        | sed "s/\[PKG_ACT\]/$pkg_act/g" \
        | sed "s/\[ENGINE_VAR\]/$engine_var/g" \
        | sed "s/\[ENGINE_NAME\]/$engine_var/g" \
        > "$temp_block"
    
    local total_lines=$(wc -l < "$MUX_ROOT/app.sh.temp")
    if [ "$INSERT_LINE" -ge "$total_lines" ]; then
        cat "$temp_block" >> "$MUX_ROOT/app.sh.temp"
    else
        sed -i "${INSERT_LINE}r $temp_block" "$MUX_ROOT/app.sh.temp"
    fi
    rm "$temp_block"
    
    local last_char=$(tail -c 1 "$MUX_ROOT/app.sh.temp")
    if [ "$last_char" != "" ]; then echo "" >> "$MUX_ROOT/app.sh.temp"; fi

    echo -e "${F_GRE} :: Browser Module Installed Successfully ::${F_RESET}"
    echo -e ""
    
    # === Step 7: Reload ===
    echo -ne "${F_WARN} :: Hot Reload now? (y/n): ${F_RESET}"
    read reload_choice
    if [[ "$reload_choice" == "y" || "$reload_choice" == "Y" ]]; then
        _fac_load
    fi
}

# 分類選擇器 (Category Selector Helper)
function _fac_select_category() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    local map_file="$MUX_ROOT/.cat_map"
    
    echo -e ""
    echo -e "${F_MAIN} :: Select Storage Sector (Category) ::${F_RESET}"
    
    grep -n "^# ===" "$temp_file" > "$map_file"
    
    local i=1
    local categories=()
    local lines=()
    
    while IFS=: read -r line_no content; do
        local clean_name=$(echo "$content" | sed 's/# === //;s/ ===//')
        echo -e "${F_SUB}    [$i] $clean_name${F_RESET}"
        categories+=("$clean_name")
        lines+=("$line_no")
        ((i++))
    done < "$map_file"
    
    echo -e "${F_SUB}    [N] Create New Category / Auto-Others${F_RESET}"
    
    echo -e ""
    echo -ne "${F_WARN}    ›› Select Sector: ${F_RESET}"
    read cat_choice
    
    INSERT_LINE=""
    CATEGORY_NAME=""
    
    if [[ "$cat_choice" =~ ^[0-9]+$ ]] && [ "$cat_choice" -le "${#lines[@]}" ] && [ "$cat_choice" -gt 0 ]; then
        local idx=$((cat_choice - 1))
        local selected_line=${lines[$idx]}
        CATEGORY_NAME=${categories[$idx]}
        
        local next_idx=$((idx + 1))
        if [ "$next_idx" -lt "${#lines[@]}" ]; then
            local next_line=${lines[$next_idx]}
            INSERT_LINE=$((next_line - 1))
        else
            INSERT_LINE=$(wc -l < "$temp_file")
        fi
        
    else
        echo -ne "${F_WARN}    ›› Enter New Category Name (Enter for 'Others'): ${F_RESET}"
        read new_cat
        new_cat=$(echo "$new_cat" | xargs)
        [ -z "$new_cat" ] && new_cat="Others"
        
        CATEGORY_NAME="$new_cat"

        local existing_line=$(grep -n "^# === $new_cat ===" "$temp_file" | head -n 1 | cut -d: -f1)
        
        if [ -n "$existing_line" ]; then
            _bot_say "factory" "Sector '$new_cat' detected at line $existing_line. Merging..."
            
            local next_header_line=$(grep -n "^# ===" "$temp_file" | cut -d: -f1 | awk -v curr="$existing_line" '$1 > curr {print $1; exit}')
            
            if [ -n "$next_header_line" ]; then
                INSERT_LINE=$((next_header_line - 1))
            else
                INSERT_LINE=$(wc -l < "$temp_file")
            fi
        else
            _bot_say "factory" "Creating new sector: $CATEGORY_NAME"
            
            echo -e "\n\n# === $CATEGORY_NAME ===\n" >> "$temp_file"
            
            INSERT_LINE=$(wc -l < "$temp_file")
        fi
    fi
    
    rm "$map_file"
}

# 修復模組 - Fix Module
function _fac_wizard_fix() {
    local target="$1"
    local temp_file="$MUX_ROOT/app.sh.temp"

    local line_num=$(grep -n "^function $target() {" "$temp_file" | cut -d: -f1)

    if [ -n "$line_num" ]; then
        _bot_say "factory" "Opening maintenance hatch for: $target"
        sleep 0.5
        nano "+$line_num" "$temp_file"
    else
        _bot_say "error" "Target not found."
    fi
}

# 加載模組 - Load Module
function _fac_load() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    
    if [ ! -f "$temp_file" ]; then
        _bot_say "error" "Sandbox file missing."
        return 1
    fi

    _bot_say "loading" "Compiling sandbox logic..."
    source "$temp_file"
    _factory_mask_apps
    sleep 0.5
    _bot_say "success" "Sandbox reloaded. Logic active."
}

# 刪除模組 - Delete Module
function _fac_del() {
    local target="$1"
    local temp_file="$MUX_ROOT/app.sh.temp"

    if [ -z "$target" ]; then
        _bot_say "error" "Target required."
        return 1
    fi

    local start_line=$(grep -n "^function $target() {" "$temp_file" | cut -d: -f1)
    
    if [ -z "$start_line" ]; then
        _bot_say "error" "Target '$target' not found."
        return 1
    fi

    local header_line=$((start_line - 1))
    local header_content=$(sed "${header_line}q;d" "$temp_file")
    
    local delete_start=$start_line
    if [[ "$header_content" == "# :"* ]]; then
        delete_start=$header_line
        echo -e "${F_WARN}    ›› Detected Header: \033[1;30m$header_content\033[0m"
    fi

    local relative_end=$(tail -n +$start_line "$temp_file" | grep -n "^}" | head -n1 | cut -d: -f1)
    local delete_end=$((start_line + relative_end - 1))

    echo -e "${F_ERR} :: DESTRUCTION MANIFEST ::${F_RESET}"
    echo -e "${F_SUB}    Target  : \033[1;37m$target\033[0m"
    echo -e "${F_SUB}    Range   : Line $delete_start -> $delete_end"
    
    echo -e "${F_GRAY}----------------------------------------${F_RESET}"
    sed -n "${delete_start},${delete_end}p" "$temp_file"
    echo -e "${F_GRAY}----------------------------------------${F_RESET}"

    echo -ne "${F_ERR} :: Confirm deletion? (y/n): ${F_RESET}"
    read choice

    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        sed -i "${delete_start},${delete_end}d" "$temp_file"
        _bot_say "success" "Module '$target' excised."
    else
        echo -e "${F_GRAY}    ›› Operation aborted.${F_RESET}"
    fi
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
    
    local time_str="#Last Sync: $(date '+%Y-%m-%d %H:%M:%S') ::"
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
    echo -e "${F_ERR} :: Waiting for manual restart...${F_RESET}"
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
    _system_lock
    echo -e "\033[1;33m :: System Reload Initiated...\033[0m"
    sleep 1.6
    clear
    _draw_logo "factory"
    _system_check "factory"
    _show_hud "factory"
    _system_unlock
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