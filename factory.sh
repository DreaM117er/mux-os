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
        
        echo -ne "${F_GRAY} :: Scanning Combat Equipment... \033[0m"
        sleep 1.2
        
        if ! command -v fzf &> /dev/null; then
            echo -e "${F_ERR}[MISSING]${F_RESET}"
            sleep 0.5
            echo -e ""
            _factory_eject_sequence "Equipment Insufficient. Neural Link (fzf) required."
            return 1
        else
            echo -e "${F_GRE}[ONLINE]${F_RESET}"
            sleep 0.5
        fi

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
        # : Open Neural Forge Menu
        "menu"|"m")
            _factory_fzf_menu
            ;;

        # : Check & Fix Formatting
        "check")
            _fac_maintenance
            ;;

        # : List all links
        "list"|"ls")
            echo -e "${F_MAIN} :: Current Sandbox Links:${F_RESET}"
            grep "^function" "$MUX_ROOT/app.sh.temp" | sed 's/function //' | sed 's/() {//' | column
            echo ""
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
        "add"|"create") 
            _fac_wizard_create
            ;;

        # : Edit Neural (Edit Command)
        "edit")
            _fac_wizard_edit "$2"
            ;;

        # : Load Neural (Test Command)
        "load"|"test") 
            _fac_load
            ;;

        # : Break Neural (Delete Command)
        "del") 
            _fac_del "$2"
            ;;

        # : Edit Category
        "category"|"cat")
            _fac_wizard_category
            ;;

        # : Time Stone Undo (Restored)
        "undo"|"u")
            _fac_undo
            ;;

        # : Show Factory Info
        "info"|"i")
            if command -v _factory_show_info &> /dev/null; then
                _factory_show_info
            fi
            ;;

        # : Reload Factory
        "reload"|"r")
            _fac_init
            _bot_say "factory_welcome"
            ;;
            
        # : Reset Factory Change
        "reset")
            _factory_reset
            ;;

        # : Deploy Changes
        "deploy"|"dep")
            _factory_deploy_sequence
            ;;

        "help"|"h")
                _mux_dynamic_help_factory
            ;;

        *)
            echo -e "${F_SUB} :: Unknown Directive: $cmd${F_RESET}"
            ;;
    esac
}

# 通用模組：智慧指令輸入器 (Smart Command Input)
function _fac_query_command_name() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    local existing_cmds=$(grep "^function" "$temp_file" | sed 's/function //' | sed 's/() {//')
    
    local result=$(echo "$existing_cmds" | fzf \
        --height=30% \
        --layout=reverse \
        --border=bottom \
        --prompt=" :: Input Command › " \
        --header=" :: Type to Search. Enter unique name to Create. ::" \
        --print-query \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240
    )
    
    local query=$(echo "$result" | head -n1)
    
    if [ -z "$query" ]; then
        echo "|EMPTY"
        return
    fi

    if echo "$existing_cmds" | grep -qx "$query"; then
        echo "$query|DUPLICATE"
    else
        echo "$query|NEW"
    fi
}

# 新增模組 - Create Module
function _fac_wizard_create() {
    local options="Normal APP (Launcher)\t_fac_stamp_launcher\nBrowser APP (Search Engine)\t_fac_stamp_browser\nEcosystem Suite (Multi-App)\t_fac_stamp_suite"
    
    local selection=$(echo -e "$options" | fzf \
        --delimiter="\t" \
        --with-nth=1 \
        --height=20% \
        --layout=reverse \
        --border=bottom \
        --prompt=" :: Forge Type › " \
        --header=" :: Select Neural Template ::" \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240
    )

    if [ -z "$selection" ]; then return; fi
    local target_func=$(echo "$selection" | awk -F'\t' '{print $2}')
    $target_func
}

# 鑄造工序：標準啟動器 - Standard Launcher Stamp
function _fac_stamp_launcher() {
    _fac_snapshot
    local mold_file="$MUX_ROOT/plate/template.txt"
    [ ! -f "$mold_file" ] && return 1

    local ui_name="Unknown"
    local pkg_id="com.null.placeholder"
    local pkg_act=""
    local target_cat="Others"
    local func_name=""
    
    local st_req="\033[1;31m[REQUIRED]\033[0m"
    local st_dup="\033[1;33m[DUPLICATE]\033[0m"
    local st_ok="\033[1;36m[CONFIRM]\033[0m"
    
    local func_status="$st_req"
    local insert_line_cache=""

    while true; do
        local menu_display=""
        menu_display="${menu_display}Command  : ${F_MAIN}${func_name:-<Empty>}${F_RESET}  ${func_status}\n"
        menu_display="${menu_display}UI Name  : ${F_SUB}${ui_name}${F_RESET}\n"
        menu_display="${menu_display}Package  : ${F_SUB}${pkg_id}${F_RESET}\n"
        menu_display="${menu_display}Activity : ${F_SUB}${pkg_act:-[Auto]}${F_RESET}\n"
        menu_display="${menu_display}Category : ${F_WARN}${target_cat}${F_RESET}\n"
        menu_display="${menu_display}\n"
        menu_display="${menu_display}apklist  : Open APK Reference List\n"
        menu_display="${menu_display}Confirm  : Forge Neural Link\n"
        menu_display="${menu_display}Cancel   : Abort Operation"

        local selection=$(echo -e "$menu_display" | fzf \
            --ansi \
            --height=40% \
            --layout=reverse \
            --border=bottom \
            --prompt=" :: Launcher Forge › " \
            --header=" :: Select Field to Modify ::" \
            --pointer="››" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240
        )

        if [ -z "$selection" ]; then return; fi

        local key=$(echo "$selection" | awk '{print $1}')
        
        local clean_selection=$(echo "$selection" | sed 's/\x1b\[[0-9;]*m//g')

        case "$key" in
            "Command") 
                local res=$(_fac_query_command_name)
                local val=$(echo "$res" | cut -d'|' -f1)
                local sts=$(echo "$res" | cut -d'|' -f2)
                
                if [ "$sts" == "NEW" ]; then 
                    func_name="$val"
                    func_status="$st_ok"
                elif [ "$sts" == "DUPLICATE" ]; then 
                    func_name="$val"
                    func_status="$st_dup"
                    _bot_say "warn" "Command '$val' already exists."
                    sleep 0.8
                fi
                ;;

            "UI") 
                echo -ne "${F_SUB}    ›› UI Display Name: ${F_RESET}"
                read input_ui
                [ -n "$input_ui" ] && ui_name="$input_ui" 
                ;;

            "Package") 
                echo -ne "${F_SUB}    ›› Package Name: ${F_RESET}"
                read input_pkg
                [ -n "$input_pkg" ] && pkg_id="$input_pkg" 
                ;;

            "Activity") 
                echo -ne "${F_SUB}    ›› Activity (Enter to Auto): ${F_RESET}"
                read input_act
                pkg_act="$input_act" 
                ;;

            "Category") 
                _fac_select_category
                if [ -n "$CATEGORY_NAME" ]; then 
                    target_cat="$CATEGORY_NAME"
                    insert_line_cache="$INSERT_LINE"
                fi 
                ;;

            "apklist") 
                if command -v apklist &> /dev/null; then 
                    apklist
                    echo -ne "\033[1;30m    (Press Enter to return...)\033[0m"
                    read
                else
                    _bot_say "error" "'apklist' module missing."
                    sleep 1
                fi
                ;;

            "Confirm")
                if [ -z "$func_name" ]; then
                    _bot_say "error" "Command Name is required."
                    sleep 0.8
                    continue
                fi
                if [[ "$func_status" == *"[DUPLICATE]"* ]]; then
                    _bot_say "error" "Cannot forge: Command exists."
                    sleep 0.8
                    continue
                fi

                if [ -z "$insert_line_cache" ]; then
                     local header_line=$(grep -n "^# === $target_cat ===" "$MUX_ROOT/app.sh.temp" | head -n 1 | cut -d: -f1)
                     if [ -n "$header_line" ]; then 
                        local next=$(tail -n +$((header_line + 1)) "$MUX_ROOT/app.sh.temp" | grep -n "^# ===" | head -n 1 | cut -d: -f1)
                        if [ -n "$next" ]; then 
                            insert_line_cache=$((header_line + next - 1))
                        else 
                            insert_line_cache=$(wc -l < "$MUX_ROOT/app.sh.temp")
                        fi
                     else 
                        echo -e "\n\n# === Others ===" >> "$MUX_ROOT/app.sh.temp"
                        insert_line_cache=$(wc -l < "$MUX_ROOT/app.sh.temp")
                     fi
                fi

                _bot_say "factory" "Forging link '$func_name'..."
                local temp_block="$MUX_ROOT/plate/block.tmp"
                
                cat "$mold_file" \
                    | sed "s/\[FUNC\]/$func_name/g" \
                    | sed "s/\[NAME\]/$ui_name/g" \
                    | sed "s/\[PKG_ID\]/$pkg_id/g" \
                    | sed "s/\[PKG_ACT\]/$pkg_act/g" \
                    > "$temp_block"
                
                echo "" >> "$temp_block"

                local total_lines=$(wc -l < "$MUX_ROOT/app.sh.temp")
                if [ "$insert_line_cache" -ge "$total_lines" ]; then
                    cat "$temp_block" >> "$MUX_ROOT/app.sh.temp"
                else
                    sed -i "${insert_line_cache}r $temp_block" "$MUX_ROOT/app.sh.temp"
                fi
                
                rm "$temp_block"
                _fac_maintenance
                _bot_say "success" "Module '$func_name' deployed."
                
                echo -ne "${F_WARN}    ›› Hot Reload now? (y/n): ${F_RESET}"
                read r
                [[ "$r" == "y" || "$r" == "Y" ]] && _fac_load
                return
                ;;

            "Cancel") 
                _bot_say "factory" "Operation aborted."
                return 
                ;;
        esac
    done
}

# 鑄造工序：瀏覽器應用 (Browser App Stamp)
function _fac_stamp_browser() {
    Commander，收到。

這兩具模具的改造目標非常明確：「儀表板化 (Dashboard-ization)」。 我們要將原本線性的問答流程，轉變為全 FZF 驅動的非線性儀表板，並維持視覺與操作邏輯的高度統一。

以下是 factory.sh 的修正代碼，包含 _fac_stamp_browser (瀏覽器鑄造) 與 _fac_stamp_suite (生態系鑄造) 的完全重構版本。

🛠️ factory.sh - Advanced Stamping Protocols
請將這兩個函式覆蓋原有的版本。

1. _fac_stamp_browser (瀏覽器儀表板)
特點：新增了 Engine 選項，點擊後會彈出 FZF 讓你選擇搜尋引擎 (Google/Bing/Duck...)。

邏輯：繼承了 Launcher 的所有優點，包括重複檢查與 APK 查閱。

Bash

# 鑄造工序：瀏覽器應用 - Browser App Stamp (Dashboard)
function _fac_stamp_browser() {
    _fac_snapshot
    local mold_file="$MUX_ROOT/plate/browser.txt"
    [ ! -f "$mold_file" ] && return 1

    # === 初始化變數 ===
    local ui_name="Unknown Browser"
    local pkg_id="com.null.browser"
    local pkg_act="" # Optional
    local engine_var="GOOGLE"
    local target_cat="Network & Cloud"
    local func_name=""

    # 狀態標記
    local st_req="\033[1;31m[REQUIRED]\033[0m"
    local st_dup="\033[1;33m[DUPLICATE]\033[0m"
    local st_ok="\033[1;36m[CONFIRM]\033[0m"
    
    local func_status="$st_req"
    local insert_line_cache=""

    while true; do
        # === 1. 建構儀表板 ===
        local menu_display=""
        menu_display="${menu_display}Command  : ${F_MAIN}${func_name:-<Empty>}${F_RESET}  ${func_status}\n"
        menu_display="${menu_display}UI Name  : ${F_SUB}${ui_name}${F_RESET}\n"
        menu_display="${menu_display}Package  : ${F_SUB}${pkg_id}${F_RESET}\n"
        menu_display="${menu_display}Activity : ${F_SUB}${pkg_act:-[Auto]}${F_RESET}\n"
        menu_display="${menu_display}Engine   : ${F_CYAN}${engine_var}${F_RESET}\n"
        menu_display="${menu_display}Category : ${F_WARN}${target_cat}${F_RESET}\n"
        menu_display="${menu_display}\n"
        menu_display="${menu_display}apklist  : Open APK Reference List\n"
        menu_display="${menu_display}Confirm  : Forge Neural Link\n"
        menu_display="${menu_display}Cancel   : Abort Operation"

        # === 2. FZF 渲染 ===
        local selection=$(echo -e "$menu_display" | fzf \
            --ansi \
            --height=45% \
            --layout=reverse \
            --border=bottom \
            --prompt=" :: Browser Forge › " \
            --header=" :: Select Field to Modify ::" \
            --pointer="››" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240
        )

        if [ -z "$selection" ]; then return; fi

        # === 3. 邏輯判斷 ===
        local key=$(echo "$selection" | awk '{print $1}')
        
        case "$key" in
            "Command") 
                local res=$(_fac_query_command_name)
                local val=$(echo "$res" | cut -d'|' -f1)
                local sts=$(echo "$res" | cut -d'|' -f2)
                if [ "$sts" == "NEW" ]; then func_name="$val"; func_status="$st_ok";
                elif [ "$sts" == "DUPLICATE" ]; then func_name="$val"; func_status="$st_dup"; _bot_say "warn" "Exists."; sleep 0.8; fi
                ;;
            "UI") echo -ne "${F_SUB}    ›› UI Display Name: ${F_RESET}"; read input_ui; [ -n "$input_ui" ] && ui_name="$input_ui" ;;
            "Package") echo -ne "${F_SUB}    ›› Package Name: ${F_RESET}"; read input_pkg; [ -n "$input_pkg" ] && pkg_id="$input_pkg" ;;
            "Activity") echo -ne "${F_SUB}    ›› Activity (Enter to Auto): ${F_RESET}"; read input_act; pkg_act="$input_act" ;;
            "Category") _fac_select_category; if [ -n "$CATEGORY_NAME" ]; then target_cat="$CATEGORY_NAME"; insert_line_cache="$INSERT_LINE"; fi ;;
            
            "Engine")
                local eng_sel=$(echo -e "GOOGLE\nBING\nDUCK\nYOUTUBE\nGITHUB" | fzf \
                    --height=20% --layout=reverse --border=bottom \
                    --prompt=" :: Select Engine › " --pointer="››" \
                    --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                    --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
                [ -n "$eng_sel" ] && engine_var="$eng_sel"
                ;;

            "apklist") command -v apklist &> /dev/null && { apklist; echo -ne "\033[1;30m(Enter)\033[0m"; read; } ;;
            
            "Confirm")
                if [ -z "$func_name" ] || [[ "$func_status" == *"[DUPLICATE]"* ]]; then continue; fi
                
                # 自動補算分類位置
                if [ -z "$insert_line_cache" ]; then
                     local header_line=$(grep -n "^# === $target_cat ===" "$MUX_ROOT/app.sh.temp" | head -n 1 | cut -d: -f1)
                     if [ -n "$header_line" ]; then 
                        local next=$(tail -n +$((header_line + 1)) "$MUX_ROOT/app.sh.temp" | grep -n "^# ===" | head -n 1 | cut -d: -f1)
                        if [ -n "$next" ]; then insert_line_cache=$((header_line + next - 1)); else insert_line_cache=$(wc -l < "$MUX_ROOT/app.sh.temp"); fi
                     else 
                        echo -e "\n\n# === Others ===" >> "$MUX_ROOT/app.sh.temp"
                        insert_line_cache=$(wc -l < "$MUX_ROOT/app.sh.temp")
                     fi
                fi

                _bot_say "factory" "Forging browser '$func_name'..."
                local temp_block="$MUX_ROOT/plate/block.tmp"
                cat "$mold_file" \
                    | sed "s/\[FUNC\]/$func_name/g" \
                    | sed "s/\[NAME\]/$ui_name/g" \
                    | sed "s/\[PKG_ID\]/$pkg_id/g" \
                    | sed "s/\[PKG_ACT\]/$pkg_act/g" \
                    | sed "s/\[ENGINE_VAR\]/$engine_var/g" \
                    | sed "s/\[ENGINE_NAME\]/$engine_var/g" \
                    > "$temp_block"
                echo "" >> "$temp_block"

                local total_lines=$(wc -l < "$MUX_ROOT/app.sh.temp")
                if [ "$insert_line_cache" -ge "$total_lines" ]; then cat "$temp_block" >> "$MUX_ROOT/app.sh.temp"; else sed -i "${insert_line_cache}r $temp_block" "$MUX_ROOT/app.sh.temp"; fi
                rm "$temp_block"; _fac_maintenance; _bot_say "success" "Deployed."; echo -ne "${F_WARN}Hot Reload? (y/n): ${F_RESET}"; read r; [[ "$r" == "y" || "$r" == "Y" ]] && _fac_load; return
                ;;
            "Cancel") return ;;
        esac
    done
}

# 鑄造工序：生態系套件 - Ecosystem Suite Stamp
function _fac_stamp_suite() {
    _fac_snapshot
    local mold_file="$MUX_ROOT/plate/suite.txt"
    if [ ! -f "$mold_file" ]; then
        echo -e "# : [SUITE_NAME] Suite\nfunction [FUNC]() {\n    local target=\"\$1\"\n    if [ -z \"\$target\" ]; then\n        if command -v fzf &> /dev/null; then\n            target=\$(echo -e \"[OPTION_LIST]\" | fzf --height=8 --layout=reverse --prompt=\" :: Select [SUITE_NAME] › \" --border=none)\n        else\n            echo \" :: Select Module:\"\n            select t in [OPTION_SELECT]; do target=\$t; break; done\n        fi\n    fi\n\n    case \"\$target\" in\n[CASE_LOGIC]\n        *)\n            [ -n \"\$target\" ] && echo -e \"\\033[1;30m    ›› Operation canceled or unknown module.\\033[0m\"\n            ;;\n    esac\n}" > "$mold_file"
    fi

    local suite_name="Unknown Suite"
    local func_name=""
    local target_cat="Ecosystems"
    
    local sub_keys=()
    local sub_names=()
    local sub_pkgs=()
    local sub_acts=()

    local st_req="\033[1;31m[REQUIRED]\033[0m"
    local st_dup="\033[1;33m[DUPLICATE]\033[0m"
    local st_ok="\033[1;36m[CONFIRM]\033[0m"
    local func_status="$st_req"
    local insert_line_cache=""

    while true; do
        local mod_count=${#sub_keys[@]}
        local mod_status="${F_WARN}[ $mod_count Items ]${F_RESET}"
        if [ "$mod_count" -eq 0 ]; then mod_status="\033[1;31m[ EMPTY ]\033[0m"; fi

        local menu_display=""
        menu_display="${menu_display}Command  : ${F_MAIN}${func_name:-<Empty>}${F_RESET}  ${func_status}\n"
        menu_display="${menu_display}Suite    : ${F_SUB}${suite_name}${F_RESET}\n"
        menu_display="${menu_display}Category : ${F_WARN}${target_cat}${F_RESET}\n"
        menu_display="${menu_display}Modules  : ${mod_status} (Click to Manage)\n"
        menu_display="${menu_display}\n"
        menu_display="${menu_display}Confirm  : Forge Neural Link\n"
        menu_display="${menu_display}Cancel   : Abort Operation"

        local selection=$(echo -e "$menu_display" | fzf \
            --ansi --height=40% --layout=reverse --border=bottom \
            --prompt=" :: Suite Forge › " --header=" :: Configure Ecosystem ::" --pointer="››" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)

        if [ -z "$selection" ]; then return; fi
        local key=$(echo "$selection" | awk '{print $1}')

        case "$key" in
            "Command")
                local res=$(_fac_query_command_name)
                local val=$(echo "$res" | cut -d'|' -f1)
                local sts=$(echo "$res" | cut -d'|' -f2)
                if [ "$sts" == "NEW" ]; then func_name="$val"; func_status="$st_ok";
                elif [ "$sts" == "DUPLICATE" ]; then func_name="$val"; func_status="$st_dup"; _bot_say "warn" "Exists."; sleep 0.8; fi
                ;;
            "Suite") echo -ne "${F_SUB}    ›› Suite Display Name: ${F_RESET}"; read input_s; [ -n "$input_s" ] && suite_name="$input_s" ;;
            "Category") _fac_select_category; if [ -n "$CATEGORY_NAME" ]; then target_cat="$CATEGORY_NAME"; insert_line_cache="$INSERT_LINE"; fi ;;
            
            "Modules")
                while true; do
                    local comp_menu="[+] Add New Module\n[-] Remove Last Module\n[<] Return to Dashboard"
                    local comp_header=" :: Current Modules ::"
                    if [ ${#sub_keys[@]} -gt 0 ]; then
                        for i in "${!sub_keys[@]}"; do
                            comp_header="$comp_header | ${sub_keys[$i]}"
                        done
                    else
                        comp_header="$comp_header (None)"
                    fi

                    local comp_sel=$(echo -e "$comp_menu" | fzf \
                        --height=30% --layout=reverse --border=bottom \
                        --prompt=" :: Module Manager › " --header="$comp_header" --pointer="››" \
                        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
                    
                    if [[ "$comp_sel" == *"[+]"* ]]; then
                        echo -e "\n${F_MAIN} :: Add Sub-Module ::${F_RESET}"
                        echo -ne "${F_SUB}    ›› Trigger Key (e.g. ps): ${F_RESET}"; read k
                        [ -z "$k" ] && continue
                        echo -ne "${F_SUB}    ›› App Name (e.g. Photoshop): ${F_RESET}"; read n
                        [ -z "$n" ] && n="$k"
                        echo -ne "${F_SUB}    ›› Package: ${F_RESET}"; read p
                        [ -z "$p" ] && p="com.null.placeholder"
                        echo -ne "${F_SUB}    ›› Activity: ${F_RESET}"; read a
                        
                        sub_keys+=("$k"); sub_names+=("$n"); sub_pkgs+=("$p"); sub_acts+=("$a")
                    elif [[ "$comp_sel" == *"[-]"* ]]; then
                        if [ ${#sub_keys[@]} -gt 0 ]; then
                            unset 'sub_keys[${#sub_keys[@]}-1]'; unset 'sub_names[${#sub_names[@]}-1]'
                            unset 'sub_pkgs[${#sub_pkgs[@]}-1]'; unset 'sub_acts[${#sub_acts[@]}-1]'
                        fi
                    else
                        break
                    fi
                done
                ;;

            "Confirm")
                if [ -z "$func_name" ] || [[ "$func_status" == *"[DUPLICATE]"* ]]; then continue; fi
                if [ ${#sub_keys[@]} -eq 0 ]; then _bot_say "error" "Suite must have at least one module."; sleep 1; continue; fi

                local option_list_fzf=""
                local option_list_select=""
                local case_logic=""
                
                for i in "${!sub_keys[@]}"; do
                    local k="${sub_keys[$i]}"; local n="${sub_names[$i]}"; local p="${sub_pkgs[$i]}"; local a="${sub_acts[$i]}"
                    
                    if [ -z "$option_list_fzf" ]; then option_list_fzf="$k"; else option_list_fzf="$option_list_fzf\\\\n$k"; fi
                    if [ -z "$option_list_select" ]; then option_list_select="\"$k\""; else option_list_select="$option_list_select \"$k\""; fi
                    
                    local case_block="        \"$k\")\n            _launch_android_app \"$n\" \"$p\" \"$a\"\n            ;;"
                    if [ -z "$case_logic" ]; then case_logic="$case_block"; else case_logic="$case_logic\n$case_block"; fi
                done

                if [ -z "$insert_line_cache" ]; then
                     local header_line=$(grep -n "^# === $target_cat ===" "$MUX_ROOT/app.sh.temp" | head -n 1 | cut -d: -f1)
                     if [ -n "$header_line" ]; then 
                        local next=$(tail -n +$((header_line + 1)) "$MUX_ROOT/app.sh.temp" | grep -n "^# ===" | head -n 1 | cut -d: -f1)
                        if [ -n "$next" ]; then insert_line_cache=$((header_line + next - 1)); else insert_line_cache=$(wc -l < "$MUX_ROOT/app.sh.temp"); fi
                     else 
                        echo -e "\n\n# === Others ===" >> "$MUX_ROOT/app.sh.temp"
                        insert_line_cache=$(wc -l < "$MUX_ROOT/app.sh.temp")
                     fi
                fi

                _bot_say "factory" "Assembling suite '$func_name'..."
                local temp_block="$MUX_ROOT/plate/block.tmp"
                cp "$mold_file" "$temp_block"
                
                sed -i "s|\[SUITE_NAME\]|$suite_name|g" "$temp_block"
                sed -i "s|\[FUNC\]|$func_name|g" "$temp_block"
                sed -i "s|\[OPTION_LIST\]|$option_list_fzf|g" "$temp_block"
                sed -i "s|\[OPTION_SELECT\]|$option_list_select|g" "$temp_block"
                
                awk -v logic="$case_logic" '{ gsub(/\[CASE_LOGIC\]/, logic); print }' "$temp_block" > "${temp_block}.2" && mv "${temp_block}.2" "$temp_block"
                sed -i 's/\\n/\n/g' "$temp_block"
                echo "" >> "$temp_block"

                local total_lines=$(wc -l < "$MUX_ROOT/app.sh.temp")
                if [ "$insert_line_cache" -ge "$total_lines" ]; then cat "$temp_block" >> "$MUX_ROOT/app.sh.temp"; else sed -i "${insert_line_cache}r $temp_block" "$MUX_ROOT/app.sh.temp"; fi
                rm "$temp_block"; _fac_maintenance; _bot_say "success" "Deployed."; echo -ne "${F_WARN}Hot Reload? (y/n): ${F_RESET}"; read r; [[ "$r" == "y" || "$r" == "Y" ]] && _fac_load; return
                ;;
            "Cancel") return ;;
        esac
    done
}

# 分類選擇器 (Category Selector Helper)
function _fac_select_category() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    local cat_list=$(grep "^# ===" "$temp_file" | sed 's/# === //;s/ ===//')
    local menu_items="[+] Create New Sector\n$cat_list"
    
    local selection=$(echo -e "$menu_items" | fzf \
        --height=40% \
        --layout=reverse \
        --border=bottom \
        --prompt=" :: Target Sector › " \
        --header=" :: Select Deployment Zone (ESC = Others) ::" \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        --bind="resize:clear-screen"
    )

    INSERT_LINE=""
    CATEGORY_NAME=""

    if [ -z "$selection" ]; then
        CATEGORY_NAME="Others"
        _bot_say "factory" "No sector selected. Defaulting to '$CATEGORY_NAME'."
    
    elif [ "$selection" == "[+] Create New Sector" ]; then
        echo -ne "${F_WARN}    ›› Enter New Category Name: ${F_RESET}"
        read new_cat
        new_cat=$(echo "$new_cat" | xargs)
        
        if [ -z "$new_cat" ]; then
            new_cat="Others"
            _bot_say "factory" "Name empty. Defaulting to 'Others'."
        fi
        
        CATEGORY_NAME="$new_cat"
    else
        CATEGORY_NAME="$selection"
    fi

    local header_line=$(grep -n "^# === $CATEGORY_NAME ===" "$temp_file" | head -n 1 | cut -d: -f1)
    
    if [ -n "$header_line" ]; then
        local next_header_line=$(tail -n +$((header_line + 1)) "$temp_file" | grep -n "^# ===" | head -n 1 | cut -d: -f1)
        
        if [ -n "$next_header_line" ]; then
            INSERT_LINE=$((header_line + next_header_line - 1))
        else
            INSERT_LINE=$(wc -l < "$temp_file")
        fi
    else
        if [ "$CATEGORY_NAME" != "Others" ]; then
             _bot_say "factory" "Initializing new sector: $CATEGORY_NAME"
        fi
        echo -e "\n\n# === $CATEGORY_NAME ===" >> "$temp_file"
        INSERT_LINE=$(wc -l < "$temp_file")
    fi
}

# 加載模組 - Load Module
function _fac_load() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    
    if [ ! -f "$temp_file" ]; then
        _bot_say "error" "Sandbox file missing."
        return 1
    fi

    _bot_say "loading" "Scanning structural integrity..."
    
    local syntax_error
    syntax_error=$(bash -n "$temp_file" 2>&1)
    
    if [ -n "$syntax_error" ]; then
        echo ""
        _bot_say "error" "Syntax corruption detected. Load aborted."
        echo -e "${F_ERR} :: CRITICAL FAILURE ::${F_RESET}"
        echo -e "${F_GRAY}$syntax_error${F_RESET}"
        echo ""
        return 1
    fi

    source "$temp_file"
    
    sleep 0.5
    _bot_say "success" "Sandbox loaded. Live fire mode active."
    echo -e "${F_GRAY}    ›› Commands are now executable for testing.${F_RESET}"
    echo -e "${F_GRAY}    ›› Type your new command to verify launch vector.${F_RESET}"
}

# 智慧維修精靈 (Smart Edit Dashboard)
function _fac_wizard_edit() {
    _fac_snapshot

    local target="$1"
    local temp_file="$MUX_ROOT/app.sh.temp"

    if [ -z "$target" ]; then
        if command -v fzf &> /dev/null; then
             target=$(grep "^function" "$temp_file" | sed 's/function //' | sed 's/() {//' | fzf \
                --height=10 --layout=reverse --border=bottom \
                --prompt=" :: Select Target to Edit › " \
                --header=" :: Neural Link Diagnostics ::" \
                --pointer="››" \
                --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
        else
            echo -ne "${F_WARN}    ›› Enter Target Command: ${F_RESET}"
            read target
        fi
    fi

    if [ -z "$target" ]; then return; fi

    local start_line=$(grep -n "^function $target() {" "$temp_file" | cut -d: -f1)
    if [ -z "$start_line" ]; then
        _bot_say "error" "Target module '$target' not found."
        return
    fi
    
    local relative_end=$(tail -n +$start_line "$temp_file" | grep -n "^}" | head -n1 | cut -d: -f1)
    local end_line=$((start_line + relative_end - 1))
    local func_body=$(sed -n "${start_line},${end_line}p" "$temp_file")
    
    local app_type="UNKNOWN"
    if echo "$func_body" | grep -q "case \"\$target\" in"; then
        app_type="SUITE"
    elif echo "$func_body" | grep -q "_resolve_smart_url"; then
        app_type="BROWSER"
    else
        app_type="LAUNCHER"
    fi

    local current_cat="Unknown"
    local header_line=$(grep -n "^# ===" "$temp_file" | awk -v sl="$start_line" -F: '$1 < sl {line=$1; content=$0} END {print content}' | sed 's/# === //;s/ ===//')
    [ -n "$header_line" ] && current_cat="$header_line"

    if [ "$app_type" == "SUITE" ]; then
        _fac_edit_dashboard_suite "$target" "$start_line" "$end_line" "$current_cat"
        return
    fi

    local current_name="Unknown"
    local current_pkg="Unknown"
    local current_act=""
    local current_engine="GOOGLE"
    
    if [ "$app_type" == "BROWSER" ]; then
        current_pkg=$(echo "$func_body" | grep "local pkg=" | cut -d'"' -f2)
        current_name=$(echo "$func_body" | grep "_launch_android_app" | head -n1 | cut -d'"' -f2)
        local engine_raw=$(echo "$func_body" | grep "_resolve_smart_url" | cut -d'"' -f2)
        current_engine=$(echo "$engine_raw" | sed 's/\$SEARCH_//')
    else
        local launch_line=$(echo "$func_body" | grep "_launch_android_app" | head -n1)
        current_name=$(echo "$launch_line" | cut -d'"' -f2)
        current_pkg=$(echo "$launch_line" | cut -d'"' -f4)
        current_act=$(echo "$launch_line" | cut -d'"' -f6)
    fi

    local ui_name="$current_name"
    local pkg_id="$current_pkg"
    local pkg_act="$current_act"
    local engine_var="$current_engine"
    local func_name="$target"
    local target_cat="$current_cat"
    
    local st_ok="\033[1;36m[CONFIRM]\033[0m"
    local st_mod="\033[1;33m[MODIFIED]\033[0m"
    local func_status="$st_ok"

    while true; do
        local menu_display=""
        menu_display="${menu_display}Command  : ${F_MAIN}${func_name}${F_RESET}  ${func_status}\n"
        menu_display="${menu_display}UI Name  : ${F_SUB}${ui_name}${F_RESET}\n"
        menu_display="${menu_display}Package  : ${F_SUB}${pkg_id}${F_RESET}\n"
        
        if [ "$app_type" == "BROWSER" ]; then
            menu_display="${menu_display}Engine   : ${F_CYAN}${engine_var}${F_RESET}\n"
        else
            menu_display="${menu_display}Activity : ${F_SUB}${pkg_act:-[Auto]}${F_RESET}\n"
        fi
        
        menu_display="${menu_display}Category : ${F_WARN}${target_cat}${F_RESET}\n"
        menu_display="${menu_display}\n"
        menu_display="${menu_display}Manual   : Edit Source Code (Nano)\n"
        menu_display="${menu_display}Delete   : Terminate Neural Link\n"
        menu_display="${menu_display}Confirm  : Apply Changes\n"
        menu_display="${menu_display}Cancel   : Discard Changes"

        local selection=$(echo -e "$menu_display" | fzf \
            --ansi --height=45% --layout=reverse --border=bottom \
            --prompt=" :: Edit ${app_type} › " --header=" :: Modify Neural Parameters ::" --pointer="››" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)

        if [ -z "$selection" ]; then return; fi
        local key=$(echo "$selection" | awk '{print $1}')

        case "$key" in
            "Command")
                echo -ne "${F_MAIN}    ›› Rename Command (Current: $func_name): ${F_RESET}"
                read new_cmd
                if [ -n "$new_cmd" ] && [ "$new_cmd" != "$func_name" ]; then
                    if grep -q "function $new_cmd() {" "$temp_file"; then
                        _bot_say "error" "Command '$new_cmd' already exists."
                        sleep 1
                    else
                        func_name="$new_cmd"
                        func_status="$st_mod"
                    fi
                fi
                ;;
            "UI") echo -ne "${F_SUB}    ›› New UI Name: ${F_RESET}"; read val; [ -n "$val" ] && ui_name="$val" ;;
            "Package") echo -ne "${F_SUB}    ›› New Package: ${F_RESET}"; read val; [ -n "$val" ] && pkg_id="$val" ;;
            "Activity") echo -ne "${F_SUB}    ›› New Activity: ${F_RESET}"; read val; pkg_act="$val" ;; # Allow empty
            "Engine")
                local eng=$(echo -e "GOOGLE\nBING\nDUCK\nYOUTUBE\nGITHUB" | fzf --height=20% --layout=reverse --border=bottom --prompt=" :: Select Engine › " --pointer="››" --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
                [ -n "$eng" ] && engine_var="$eng"
                ;;
            "Category") _fac_select_category; if [ -n "$CATEGORY_NAME" ]; then target_cat="$CATEGORY_NAME"; fi ;;
            
            "Manual") nano "+$start_line" "$temp_file"; return ;;
            "Delete") _fac_del "$target"; return ;;
            
            "Confirm")
                _bot_say "factory" "Refactoring module '$target'..."
                
                if [ "$func_name" != "$target" ]; then
                    sed -i "${start_line}s/function $target() {/function $func_name() {/" "$temp_file"
                    target="$func_name"
                fi
                
                if [ "$ui_name" != "$current_name" ]; then
                    sed -i "${start_line},${end_line}s/\"$current_name\"/\"$ui_name\"/" "$temp_file"
                fi
                
                if [ "$pkg_id" != "$current_pkg" ]; then
                    if [ "$app_type" == "BROWSER" ]; then
                        sed -i "${start_line},${end_line}s/local pkg=\"$current_pkg\"/local pkg=\"$pkg_id\"/" "$temp_file"
                    else
                        sed -i "${start_line},${end_line}s/\"$current_pkg\"/\"$pkg_id\"/" "$temp_file"
                    fi
                fi
                
                if [ "$app_type" == "LAUNCHER" ] && [ "$pkg_act" != "$current_act" ]; then
                     local new_line="    _launch_android_app \"$ui_name\" \"$pkg_id\" \"$pkg_act\""
                     sed -i "${start_line},${end_line}s|^.*_launch_android_app.*|$new_line|" "$temp_file"
                fi
                
                if [ "$app_type" == "BROWSER" ] && [ "$engine_var" != "$current_engine" ]; then
                     local new_res="    _resolve_smart_url \"\$SEARCH_$engine_var\" \"\$@\""
                     sed -i "${start_line},${end_line}s|^.*_resolve_smart_url.*|$new_res|" "$temp_file"
                fi

                if [ "$target_cat" != "$current_cat" ]; then
                    _fac_cat_move "$target"
                fi
                
                _fac_maintenance
                _bot_say "success" "Modifications applied."
                return
                ;;
                
            "Cancel") return ;;
        esac
    done
}

# 輔助：Suite 編輯儀表板 (Sub-routine)
function _fac_edit_dashboard_suite() {
    local target="$1"
    local start_line="$2"
    local end_line="$3"
    local current_cat="$4"
    local temp_file="$MUX_ROOT/app.sh.temp"

    while true; do
        local sub_count=$(sed -n "${start_line},${end_line}p" "$temp_file" | grep -c "\")")
        local mod_status="${F_WARN}[ $sub_count Items ]${F_RESET}"

        local menu_display=""
        menu_display="${menu_display}Command  : ${F_MAIN}${target}${F_RESET}\n"
        menu_display="${menu_display}Type     : ${F_CYAN}Ecosystem Suite${F_RESET}\n"
        menu_display="${menu_display}Category : ${F_WARN}${current_cat}${F_RESET}\n"
        menu_display="${menu_display}Modules  : ${mod_status} (Click to Manage)\n"
        menu_display="${menu_display}\n"
        menu_display="${menu_display}Manual   : Edit Source Code (Nano)\n"
        menu_display="${menu_display}Delete   : Terminate Suite\n"
        menu_display="${menu_display}Cancel   : Return to Radar"

        local selection=$(echo -e "$menu_display" | fzf \
            --ansi --height=40% --layout=reverse --border=bottom \
            --prompt=" :: Edit Suite › " --header=" :: Ecosystem Diagnostics ::" --pointer="››" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)

        if [ -z "$selection" ]; then return; fi
        local key=$(echo "$selection" | awk '{print $1}')

        case "$key" in
            "Modules")
                local map_file="$MUX_ROOT/.suite_map"
                sed -n "${start_line},${end_line}p" "$temp_file" | grep -n "^[[:space:]]*\".*\")" > "$map_file"
                
                local sub_menu="[+] Add New Module\n"
                local i=1
                local lines=()
                
                while IFS=: read -r rel_line content; do
                    local key_name=$(echo "$content" | cut -d'"' -f2)
                    sub_menu="${sub_menu}[$i] Edit Module: $key_name\n"
                    lines+=("$((start_line + rel_line - 1))")
                    ((i++))
                done < "$map_file"
                rm "$map_file"

                local sub_sel=$(echo -e "$sub_menu" | fzf --height=40% --layout=reverse --border=bottom --prompt=" :: Module Manager › " --pointer="››" --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
                
                if [[ "$sub_sel" == *"[+]"* ]]; then
                    _fac_suite_injector "$target" "$start_line" "$end_line"
                elif [[ "$sub_sel" =~ \[([0-9]+)\] ]]; then
                    local idx=$((${BASH_REMATCH[1]} - 1))
                    local target_line=${lines[$idx]}
                    _bot_say "factory" "Opening maintenance hatch..."
                    nano "+$target_line" "$temp_file"
                fi
                ;;
            
            "Category") _fac_cat_move "$target"; return ;;
            "Manual") nano "+$start_line" "$temp_file"; return ;;
            "Delete") _fac_del "$target"; return ;;
            "Cancel") return ;;
        esac
    done
}

# 生態系套件注入器 - Suite Injector (Optimized)
function _fac_suite_injector() {
    local target="$1"
    local start_line="$2"
    local end_line="$3"
    local temp_file="$MUX_ROOT/app.sh.temp"

    echo -e ""
    echo -e "${F_MAIN} :: Suite Expansion Protocol ::${F_RESET}"
    
    echo -ne "${F_SUB}    ›› New Trigger Key (e.g. ppt): ${F_RESET}"
    read sub_key
    [ -z "$sub_key" ] && return

    echo -ne "${F_SUB}    ›› Display Name (e.g. PowerPoint): ${F_RESET}"
    read sub_name
    [ -z "$sub_name" ] && sub_name="$sub_key"

    echo -ne "${F_SUB}    ›› Package Name: ${F_RESET}"
    read sub_pkg
    [ -z "$sub_pkg" ] && sub_pkg="com.null.placeholder"
    
    echo -ne "${F_SUB}    ›› Activity (Optional): ${F_RESET}"
    read sub_act

    _bot_say "factory" "Injecting module '$sub_key' into suite '$target'..."

    sed -i "${start_line},${end_line}s/\" | fzf/\\\\n$sub_key\" | fzf/" "$temp_file"

    sed -i "${start_line},${end_line}s/; do/ \"$sub_key\"; do/" "$temp_file"

    local rel_esac=$(sed -n "${start_line},${end_line}p" "$temp_file" | grep -n "esac" | tail -n1 | cut -d: -f1)
    
    if [ -n "$rel_esac" ]; then
        local abs_esac=$((start_line + rel_esac - 1))
        local case_block="        \"$sub_key\")\\n            _launch_android_app \"$sub_name\" \"$sub_pkg\" \"$sub_act\"\\n            ;;"
        
        sed -i "${abs_esac}i $case_block" "$temp_file"
        _bot_say "success" "Expansion complete. Module '$sub_key' active."
    else
        _bot_say "error" "Injection failed. Structure mismatch."
    fi
}

# 刪除模組 - Delete Module
function _fac_del() {
    _fac_snapshot

    local target="$1"
    local temp_file="$MUX_ROOT/app.sh.temp"

    # 1. 鎖定目標
    if [ -z "$target" ]; then
        echo -e ""
        echo -e "${F_MAIN} :: Neural Link Destruction Protocol ::${F_RESET}"
        echo -ne "${F_WARN}    ›› Enter Target Command to Delete: ${F_RESET}"
        read target
    fi

    if [ -z "$target" ]; then return; fi

    # 2. 計算座標
    local start_line=$(grep -n "^function $target() {" "$temp_file" | cut -d: -f1)
    
    if [ -z "$start_line" ]; then
        _bot_say "error" "Target '$target' not found in Sandbox."
        return 1
    fi

    # 偵測註解
    local header_line=$((start_line - 1))
    local header_content=$(sed "${header_line}q;d" "$temp_file")
    local delete_start=$start_line
    
    if [[ "$header_content" == "# :"* ]]; then
        delete_start=$header_line
    fi

    local relative_end=$(tail -n +$start_line "$temp_file" | grep -n "^[[:space:]]*}" | head -n1 | cut -d: -f1)
    
    # 雙重保險：如果找不到結尾，立即中止
    if [ -z "$relative_end" ]; then
        _bot_say "error" "Structural integrity compromised. Cannot find closing brace."
        return 1
    fi

    local delete_end=$((start_line + relative_end - 1))

    # 3. 毀滅預覽
    clear
    echo -e "${F_ERR} :: DESTRUCTION MANIFEST ::${F_RESET}"
    echo -e "${F_GRAY}    --------------------------------${F_RESET}"
    echo -e "${F_GRAY}    Target  : ${F_WARN}$target${F_RESET}"
    echo -e "${F_GRAY}    Range   : Line $delete_start -> $delete_end${F_RESET}"
    echo -e "${F_GRAY}    Context :${F_RESET}"
    echo -e ""
    
    echo -e "\033[1;31m"
    sed -n "${delete_start},${delete_end}p" "$temp_file"
    echo -e "\033[0m"
    
    echo -e "${F_GRAY}    --------------------------------${F_RESET}"

    # 4. 紅鈕確認
    echo -e "${F_ERR} :: WARNING: This action will permanently excise logic from the matrix.${F_RESET}"
    echo -ne "${F_ERR}    ›› TYPE 'CONFIRM' TO DELETE: ${F_RESET}"
    read choice

    if [[ "$choice" == "CONFIRM" ]]; then
        _bot_say "factory" "Excising module..."
        
        sed -i "${delete_start},${delete_end}d" "$temp_file"
        unset -f "$target"
        
        _fac_maintenance

        _bot_say "success" "Module '$target' has been terminated."
        
        echo -ne "${F_WARN}    ›› Hot Reload now? (y/n): ${F_RESET}"
        read r
        [[ "$r" == "y" || "$r" == "Y" ]] && _fac_load
    else
        echo -e ""
        echo -e "${F_GRAY}    ›› Operation aborted. Target lives another day.${F_RESET}"
    fi
}

# 分類與戰略地圖管理 (Category & Terrain Management)
function _fac_wizard_category() {
    while true; do
        clear
        _draw_logo "factory"
        echo -e "${F_MAIN} :: Terrain & Sector Management ::${F_RESET}"
        echo -e "${F_GRAY}    Re-organize your neural pathways.${F_RESET}"
        echo -e "${F_GRAY}    --------------------------------${F_RESET}"
        
        echo -e "    [1] ${F_SUB}Add New Sector${F_RESET}    (Create Header)"
        echo -e "    [2] ${F_SUB}Rename Sector${F_RESET}     (Modify Header)"
        echo -e "    [3] ${F_SUB}Remove Sector${F_RESET}     (Delete Header Only)"
        echo -e "    [4] ${F_SUB}Relocate Unit${F_RESET}     (Move App to Category)"
        echo -e ""
        echo -e "    [0] Exit"
        echo -e ""
        echo -ne "${F_WARN}    ›› Select Operation: ${F_RESET}"
        read choice
        
        case "$choice" in
            1) _fac_cat_add ;;
            2) _fac_cat_rename ;;
            3) _fac_cat_delete ;;
            4) _fac_cat_move ;;
            0) break ;;
            *) ;;
        esac
    done
}

# 新增分類標頭 - Add Category Header
function _fac_cat_add() {
    _fac_snapshot
    echo -e ""
    echo -e "${F_MAIN} :: Create New Sector ::${F_RESET}"
    echo -ne "${F_SUB}    ›› Enter New Category Name: ${F_RESET}"
    read new_name
    [ -z "$new_name" ] && return

    local temp_file="$MUX_ROOT/app.sh.temp"
    local map_file="$MUX_ROOT/.cat_map"
    
    grep -n "^# ===" "$temp_file" > "$map_file"
    local lines=()
    local names=()
    local i=1
    
    echo -e ""
    echo -e "${F_WARN}    ›› Insert Before Which Sector? (Default: End of File)${F_RESET}"
    
    while IFS=: read -r line_no content; do
        local clean_name=$(echo "$content" | sed 's/# === //;s/ ===//')
        echo -e "    [$i] $clean_name"
        lines+=("$line_no")
        names+=("$clean_name")
        ((i++))
    done < "$map_file"
    rm "$map_file"
    
    echo -ne "${F_WARN}    ›› Select [1-$((i-1))] or Enter for Bottom: ${F_RESET}"
    read pos
    
    local insert_str="\n\n# === $new_name ===\n"
    
    if [[ "$pos" =~ ^[0-9]+$ ]] && [ "$pos" -le "${#lines[@]}" ] && [ "$pos" -gt 0 ]; then
        local idx=$((pos - 1))
        local target_line=${lines[$idx]}
        sed -i "${target_line}i $insert_str" "$temp_file"
        _fac_maintenance
        _bot_say "factory" "Sector '$new_name' inserted before '${names[$idx]}'."
    else
        echo -e "$insert_str" >> "$temp_file"
        _fac_maintenance
        _bot_say "factory" "Sector '$new_name' appended to map."
    fi
}

# 重命名分類標頭 - Rename Category Header
function _fac_cat_rename() {
    _fac_snapshot
    local temp_file="$MUX_ROOT/app.sh.temp"
    local target_line=""
    local old_name=""

    if command -v fzf &> /dev/null; then
        local sel=$(grep -n "^# ===" "$temp_file" | fzf \
            --height=10 --layout=reverse --border=bottom \
            --prompt=" :: Rename Sector › " \
            --pointer="››" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        )
    else
        local map_file="$MUX_ROOT/.cat_map"
        grep -n "^# ===" "$temp_file" > "$map_file"
        local lines=()
        local i=1
        while IFS=: read -r ln content; do
            echo "[$i] $content"
            lines+=("$ln")
            ((i++))
        done < "$map_file"
        rm "$map_file"
        echo -ne "Select ID: "
        read choice
        target_line=${lines[$((choice-1))]}
        old_name=$(sed -n "${target_line}p" "$temp_file" | sed 's/# === //;s/ ===//')
    fi

    if [ -z "$target_line" ]; then return; fi

    echo -e "${F_WARN}    ›› Rename '$old_name' to: ${F_RESET}"
    read new_name
    [ -z "$new_name" ] && return

    sed -i "${target_line}s/=== .* ===/=== $new_name ===/" "$temp_file"
    _fac_maintenance
    _bot_say "success" "Sector renamed to '$new_name'."
}

# 刪除分類標頭 - Delete Category Header
function _fac_cat_delete() {
    _fac_snapshot
    local temp_file="$MUX_ROOT/app.sh.temp"
    local target_line=""

    if command -v fzf &> /dev/null; then
        local sel=$(grep -n "^# ===" "$temp_file" | fzf \
            --height=10 --layout=reverse --border=bottom \
            --prompt=" :: Remove Sector › " \
            --pointer="››" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        )
    else
        local map_file="$MUX_ROOT/.cat_map"
        grep -n "^# ===" "$temp_file" > "$map_file"
        local lines=()
        local i=1
        while IFS=: read -r ln content; do
            echo "[$i] $content"
            lines+=("$ln")
            ((i++))
        done < "$map_file"
        rm "$map_file"
        echo -ne "Select ID: "
        read choice
        target_line=${lines[$((choice-1))]}
        echo -ne "${F_ERR}    (Legacy mode: Feature requires FZF for safety in this version)${F_RESET}\n"
        old_name=$(sed -n "${target_line}p" "$temp_file" | sed 's/# === //;s/ ===//')
        return
    fi

    echo -e "${F_ERR} :: WARNING :: This will remove the HEADER only.${F_RESET}"
    echo -e "${F_GRAY}    Apps under this sector will merge into the previous sector.${F_RESET}"
    echo -ne "${F_WARN}    ›› Confirm delete? (y/n): ${F_RESET}"
    read conf
    if [[ "$conf" == "y" || "$conf" == "Y" ]]; then
        sed -i "${target_line}d" "$temp_file"
        _fac_maintenance
        _bot_say "factory" "Sector header removed."
    fi
}

# 單元移動器 - Unit Relocator
function _fac_cat_move() {
    _fac_snapshot
    local temp_file="$MUX_ROOT/app.sh.temp"
    local target_app="$1"

    if [ -z "$target_app" ]; then
        if command -v fzf &> /dev/null; then
            target_app=$(grep "^function" "$temp_file" | sed 's/function //' | sed 's/() {//' | fzf \
                --height=10 --layout=reverse --border=bottom \
                --prompt=" :: Select Unit to Relocate › " \
                --pointer="››" \
                --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
            )
        else
            echo -ne "${F_WARN}    ›› Enter App Name: ${F_RESET}"
            read target_app
        fi
    fi
    
    [ -z "$target_app" ] && return

    local start_line=$(grep -n "^function $target_app() {" "$temp_file" | cut -d: -f1)
    if [ -z "$start_line" ]; then _bot_say "error" "Unit '$target_app' not found."; return; fi

    local header_line=$((start_line - 1))
    local header_content=$(sed "${header_line}q;d" "$temp_file")
    local cut_start=$start_line
    
    if [[ "$header_content" == "# :"* ]]; then
        cut_start=$header_line
    fi

    local relative_end=$(tail -n +$start_line "$temp_file" | grep -n "^}" | head -n1 | cut -d: -f1)
    if [ -z "$relative_end" ]; then _bot_say "error" "Structure corrupted."; return; fi
    
    local cut_end=$((start_line + relative_end - 1))
    
    local move_block="$MUX_ROOT/plate/move.tmp"
    sed -n "${cut_start},${cut_end}p" "$temp_file" > "$move_block"
    echo "" >> "$move_block"

    _bot_say "factory" "Extracting unit '$target_app'..."
    sed -i "${cut_start},${cut_end}d" "$temp_file"

    _fac_select_category
    
    if [ -z "$INSERT_LINE" ]; then
        _bot_say "error" "Destination lost. Restoring unit..."
        cat "$move_block" >> "$temp_file"
        rm "$move_block"
        return
    fi

    _bot_say "factory" "Relocating to $CATEGORY_NAME..."
    
    local total_lines=$(wc -l < "$temp_file")
    if [ "$INSERT_LINE" -ge "$total_lines" ]; then
        cat "$move_block" >> "$temp_file"
    else
        sed -i "${INSERT_LINE}r $move_block" "$temp_file"
    fi
    rm "$move_block"

    _fac_maintenance
    _bot_say "success" "Unit relocated successfully."
}

# 自動備份 - Auto Backup
function _factory_auto_backup() {
    local bak_dir="$MUX_ROOT/bak"
    [ ! -d "$bak_dir" ] && mkdir -p "$bak_dir"
    cp "$MUX_ROOT/app.sh" "$bak_dir/app.sh_$(date +%Y%m%d_%H%M%S)"
    ls -t "$bak_dir"/app.sh_* 2>/dev/null | tail -n +4 | xargs rm -- 2>/dev/null
}

# 快照機制 - Snapshot Protocol (3-Level Rotation)
function _fac_snapshot() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    local undo1="$MUX_ROOT/.app.sh.undo1"
    local undo2="$MUX_ROOT/.app.sh.undo2"
    local undo3="$MUX_ROOT/.app.sh.undo3"

    [ ! -f "$temp_file" ] && return

    [ -f "$undo2" ] && cp "$undo2" "$undo3"
    [ -f "$undo1" ] && cp "$undo1" "$undo2"
    cp "$temp_file" "$undo1"
}

# 回朔指令 - Undo Protocol
function _fac_undo() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    local undo1="$MUX_ROOT/.app.sh.undo1"

    if [ ! -f "$undo1" ]; then
        _bot_say "error" "No temporal snapshot found."
        return
    fi

    echo -e "${F_WARN} :: Time Stone Activated...${F_RESET}"
    echo -e "${F_GRAY}    Reverting to previous timeline state...${F_RESET}"
    
    cp "$undo1" "$temp_file"
    
    _fac_load
    _bot_say "success" "Timeline reverted."
}

# 部署序列 (Deploy Sequence)
function _factory_deploy_sequence() {
    echo ""
    echo -ne "${F_WARN} :: Initiating Deployment Sequence...${F_RESET}"
    sleep 2.6
    
    clear
    _draw_logo "gray"
    
    echo -e "${F_MAIN} :: MANIFEST CHANGES (Sandbox vs Production) ::${F_RESET}"
    echo ""
    
    if command -v diff &> /dev/null; then
        diff -U 0 "$MUX_ROOT/app.sh" "$MUX_ROOT/app.sh.temp" | \
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
    echo -ne "${F_WARN} :: Modifications verified? [y/n]: ${F_RESET}"
    read choice
    
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        _fac_init
        echo -e ""
        echo -e "${F_GRAY}    --------------------------------${F_RESET}"
        _bot_say "factory" "Deployment canceled. Sandbox state retained."
        echo -e "${F_GRAY}    ›› To discard changes: type 'fac reset'${F_RESET}"
        echo -e "${F_GRAY}    ›› To resume editing : type 'fac edit'${F_RESET}"
        echo -e "${F_GRAY}    --------------------------------${F_RESET}"
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

# 神經鍛造中樞 (Neural Forge Nexus) - The Radar
function _factory_fzf_menu() {
    local temp_file="$MUX_ROOT/app.sh.temp"

    while true; do
        # 1. 數據解析
        local list_data=$(awk '
            BEGIN { 
                current_cat="Uncategorized"
                C_CMD="\x1b[1;37m"    # White
                C_CAT="\x1b[1;30m"    # Gray (Factory Style)
                C_RESET="\x1b[0m"
            }
            /^# ===/ {
                current_cat=$0;
                gsub(/^# === | ===$/, "", current_cat);
            }
            /^function / {
                match($0, /function ([a-zA-Z0-9_]+)/, arr);
                func_name = arr[1];
                if (substr(func_name, 1, 1) != "_") {
                    # 格式: Command    [Category]
                    printf " %s%-14s %s[%s]%s\n", C_CMD, func_name, C_CAT, current_cat, C_RESET;
                }
            }
        ' "$temp_file")

        if [ -z "$list_data" ]; then
            _bot_say "error" "No neural links found in sandbox."
            return
        fi
        
        local total_cmds=$(echo "$list_data" | wc -l)

        # 2. FZF 渲染 (Factory Orange Theme)
        local selection=$(echo "$list_data" | fzf --ansi \
            --height=10 \
            --layout=reverse \
            --border=bottom \
            --prompt=" :: Neural Search › " \
            --header=" :: Forge Index: [$total_cmds] | ALT-C: Create :: " \
            --info=hidden \
            --pointer="››" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
            --bind="alt-c:execute(_fac_wizard_create)+reload(echo \"$list_data\")" \
            --bind="resize:clear-screen"
        )

        if [ -z "$selection" ]; then
            break
        fi

        local target_func=$(echo "$selection" | awk '{print $1}')
        local target_cat_raw=$(echo "$selection" | awk -F'[][]' '{print $2}')
        
        _fac_inspector "$target_func" "$target_cat_raw"
    done
}

# 機體維護工具 (Mechanism Maintenance)
function _fac_maintenance() {
    local targets=("$MUX_ROOT/app.sh.temp" "$MUX_ROOT/system.sh" "$MUX_ROOT/vendor.sh")
    
    echo -e "${F_MAIN} :: Initiating Mechanism Maintenance...${F_RESET}"
    
    for file in "${targets[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${F_GRAY}    ›› Scanning: $(basename "$file")...${F_RESET}"
            
            if [ -n "$(tail -c 1 "$file")" ]; then
                echo "" >> "$file"
                echo -e "${F_WARN}       [Fixed] Missing EOF newline.${F_RESET}"
            fi
            
            if grep -q "^}[^[:space:]]" "$file"; then
                sed -i 's/^}/}\n/' "$file"
                echo -e "${F_WARN}       [Fixed] Detached glued functions.${F_RESET}"
            fi

            if [[ "$file" == *"app.sh.temp" ]]; then
                if ! grep -q "^# === Others ===" "$file"; then
                    echo -e "\n\n# === Others ===\n" >> "$file"
                    echo -e "${F_WARN}       [Fixed] Restored 'Others' safety net.${F_RESET}"
                fi
            fi
        fi
    done
    sleep 0.5
    echo -e ""
    _bot_say "factory" "Mechanism maintenance complete, Commander."
}

function _fac_inspector() {
    local target="$1"
    local category="$2"
    local temp_file="$MUX_ROOT/app.sh.temp"

    while true; do
        # 1. 獲取元數據 (Metadata)
        # 返回格式: TYPE|NAME|PKG|EXTRA
        local meta_raw=$(_fac_get_meta "$target")
        IFS='|' read -r m_type m_name m_pkg m_extra <<< "$meta_raw"

        # 2. 繪製 HUD
        clear
        _draw_logo "factory"
        
        echo -e "${F_MAIN} :: Neural Unit Inspector ::${F_RESET}"
        echo -e "${F_GRAY}    --------------------------------${F_RESET}"
        echo -e "${F_GRAY}    Command  : ${F_WARN}$target${F_RESET}"
        echo -e "${F_GRAY}    Sector   : ${F_SUB}$category${F_RESET}"
        echo -e "${F_GRAY}    Type     : ${F_CYAN}$m_type${F_RESET}"
        echo -e "${F_GRAY}    --------------------------------${F_RESET}"
        
        echo -e "${F_SUB}    [Identity Matrix]${F_RESET}"
        echo -e "      › UI Name  : \033[1;37m$m_name\033[0m"
        echo -e "      › Package  : \033[1;32m$m_pkg\033[0m"
        
        if [ "$m_type" == "LAUNCHER" ]; then
            echo -e "      › Activity : \033[1;30m${m_extra:-[Auto]}\033[0m"
        elif [ "$m_type" == "BROWSER" ]; then
            echo -e "      › Engine   : \033[1;33m$m_extra\033[0m"
        elif [ "$m_type" == "SUITE" ]; then
            echo -e "      › Modules  : \033[1;35m$m_extra active\033[0m"
        fi
        
        echo -e ""
        echo -e "${F_GRAY}    --------------------------------${F_RESET}"
        echo -e "${F_MAIN}    [Protocol Override]${F_RESET}"
        echo -e "    [t] Test Fire    (Execute)"
        echo -e "    [e] Edit Logic   (Modify)"
        echo -e "    [m] Move Sector  (Relocate)"
        echo -e "    [d] Terminate    (Delete)"
        echo -e ""
        echo -e "    [ESC/0] Return to Radar"
        echo -e ""
        
        echo -ne "${F_WARN}    ›› Awaiting Directive: ${F_RESET}"
        read -n 1 choice
        echo ""

        case "$choice" in
            "t"|"T")
                _bot_say "launch" "Test firing '$target'..."
                eval "$target"
                echo ""
                echo -ne "\033[1;30m    (Press Enter to continue...)\033[0m"
                read
                ;;
            "e"|"E")
                _fac_wizard_edit "$target"
                ;;
            "m"|"M")
                _fac_cat_move "$target"
                return
                ;;
            "d"|"D")
                _fac_del "$target"
                return
                ;;
            "0"|$'\e')
                break
                ;;
        esac
    done
}

# 元數據解析器 - Metadata Extraction Engine
function _fac_get_meta() {
    local target="$1"
    local temp_file="$MUX_ROOT/app.sh.temp"
    
    local func_body=$(sed -n "/^function $target() {/,/^}/p" "$temp_file" | head -n 20)
    
    local type="UNKNOWN"
    local name="Unknown"
    local pkg="Unknown"
    local extra=""

    if echo "$func_body" | grep -q "case \"\$target\" in"; then
        type="SUITE"
    elif echo "$func_body" | grep -q "_resolve_smart_url"; then
        type="BROWSER"
    else
        type="LAUNCHER"
    fi

    if [ "$type" == "SUITE" ]; then
        name="$target (Suite)"
        extra=$(echo "$func_body" | grep -c "\")")
        pkg="Multi-Package"

    elif [ "$type" == "BROWSER" ]; then
        name=$(echo "$func_body" | grep "_launch_android_app" | head -n1 | cut -d'"' -f2)
        pkg=$(echo "$func_body" | grep "local pkg=" | cut -d'"' -f2)
        local engine_raw=$(echo "$func_body" | grep "_resolve_smart_url" | cut -d'"' -f2)
        extra=$(echo "$engine_raw" | sed 's/\$SEARCH_//')

    else
        local launch_line=$(echo "$func_body" | grep "_launch_android_app" | head -n1)
        name=$(echo "$launch_line" | cut -d'"' -f2)
        pkg=$(echo "$launch_line" | cut -d'"' -f4)
        extra=$(echo "$launch_line" | cut -d'"' -f6)
    fi

    echo "$type|$name|$pkg|$extra"
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