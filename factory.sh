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
    
    _factory_auto_backup > /dev/null 2>&1

    # 初始化介面
    if command -v _fac_init &> /dev/null; then
        _fac_init
    else
        clear
        _draw_logo "factory"
    fi

    _bot_say "factory_welcome"
}

# 進入兵工廠模式 (Entry Point)
function _enter_factory_mode() {
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

# 彈射序列 (The Ejection)
function _factory_eject_sequence() {
    local reason="$1"
    if [ -f "$MUX_ROOT/app.sh.temp" ]; then rm "$MUX_ROOT/app.sh.temp"; fi
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
    export __MUX_MODE="core"
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
            local target=$(_factory_fzf_menu "Select App to Inspect")
            
            if [ -n "$target" ]; then
                _factory_fzf_detail_view "$target"
            fi
            ;;

        # : Open Category Menu
        "catmenu"|"catm")
            local cat_id=$(_factory_fzf_cat_selector)
    
            if [ -n "$cat_id" ]; then
                local target_cmd=$(_factory_fzf_cmd_in_cat "$cat_id")
        
                if [ -n "$target_cmd" ]; then
                    _factory_fzf_detail_view "$target_cmd"
                fi
            fi
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
        "add"|"new") 
            _fac_wizard_create
            ;;

        # : Edit Neural (Edit Command)
        "edit")
            _fac_wizard_edit "$2"
            ;;

        # : Relocate Unit (Move Command)
        "move")
            _fac_cat_move "$2"
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
        "undo"|"ud")
            _fac_undo
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

# 通用模組：智慧指令輸入器 (Smart Command Input)
function _fac_query_command_name() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    local existing_cmds=$(grep "^function" "$temp_file" | sed 's/function //' | sed 's/() {//')
    
    local result=$(echo "$existing_cmds" | fzf \
        --height=30% \
        --layout=reverse \
        --border=bottom \
        --info=hidden \
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
        --info=hidden \
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
        menu_display="${menu_display} ${F_GRAY}:: Launcher Forge ::${F_RESET}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} Command  : ${F_MAIN}${func_name:-<Empty>}${F_RESET}  ${func_status}\n"
        menu_display="${menu_display} Category : ${F_WARN}${target_cat}${F_RESET}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} UI Name  : ${F_SUB}${ui_name}${F_RESET}\n"
        menu_display="${menu_display} Package  : ${F_SUB}${pkg_id}${F_RESET}\n"
        menu_display="${menu_display} Activity : ${F_SUB}${pkg_act:-[Auto]}${F_RESET}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} apklist  : Open APK Reference List\n"
        menu_display="${menu_display} Confirm  : Forge Neural Link\n"
        menu_display="${menu_display} Cancel   : Abort Operation"

        local selection=$(echo -e "$menu_display" | fzf \
            --ansi \
            --height=50% \
            --layout=reverse \
            --border=bottom \
            --info=hidden \
            --prompt=" :: Launcher Forge › " \
            --pointer="››" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240
        )

        if [ -z "$selection" ]; then return; fi

        local key=$(echo "$selection" | awk '{print $1}')
        
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
                
                echo -ne "${F_WARN}    ›› Hot Reload now? [Y/n]: ${F_RESET}"
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
    _fac_snapshot
    local mold_file="$MUX_ROOT/plate/browser.txt"
    [ ! -f "$mold_file" ] && return 1

    local ui_name="Unknown Browser"
    local pkg_id="com.null.browser"
    local pkg_act=""
    local engine_var="GOOGLE"
    local target_cat="Network & Cloud"
    local func_name=""

    local st_req="\033[1;31m[REQUIRED]\033[0m"
    local st_dup="\033[1;33m[DUPLICATE]\033[0m"
    local st_ok="\033[1;36m[CONFIRM]\033[0m"
    
    local func_status="$st_req"
    local insert_line_cache=""

    while true; do
        local menu_display=""
        menu_display="${menu_display} ${F_GRAY}:: Browser Forge ::${F_RESET}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} Command  : ${F_MAIN}${func_name:-<Empty>}${F_RESET}  ${func_status}\n"
        menu_display="${menu_display} Category : ${F_WARN}${target_cat}${F_RESET}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} UI Name  : ${F_SUB}${ui_name}${F_RESET}\n"
        menu_display="${menu_display} Package  : ${F_SUB}${pkg_id}${F_RESET}\n"
        menu_display="${menu_display} Activity : ${F_SUB}${pkg_act:-[Auto]}${F_RESET}\n"
        menu_display="${menu_display} Engine   : ${F_CYAN}${engine_var}${F_RESET}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} apklist  : Open APK Reference List\n"
        menu_display="${menu_display} Confirm  : Forge Neural Link\n"
        menu_display="${menu_display} Cancel   : Abort Operation"

        local selection=$(echo -e "$menu_display" | fzf \
            --ansi \
            --height=50% \
            --layout=reverse \
            --border=bottom \
            --info=hidden \
            --prompt=" :: Browser Forge › " \
            --pointer="››" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240
        )

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
            "UI") echo -ne "${F_SUB}    ›› UI Display Name: ${F_RESET}"; read input_ui; [ -n "$input_ui" ] && ui_name="$input_ui" ;;
            "Package") echo -ne "${F_SUB}    ›› Package Name: ${F_RESET}"; read input_pkg; [ -n "$input_pkg" ] && pkg_id="$input_pkg" ;;
            "Activity") echo -ne "${F_SUB}    ›› Activity (Enter to Auto): ${F_RESET}"; read input_act; pkg_act="$input_act" ;;
            "Category") _fac_select_category; if [ -n "$CATEGORY_NAME" ]; then target_cat="$CATEGORY_NAME"; insert_line_cache="$INSERT_LINE"; fi ;;
            
            "Engine")
                local eng_sel=$(echo -e "GOOGLE\nBING\nDUCK\nYOUTUBE\nGITHUB" | fzf \
                    --height=20% --layout=reverse --border=bottom \
                    --info=hidden \
                    --prompt=" :: Select Engine › " --pointer="››" \
                    --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                    --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
                [ -n "$eng_sel" ] && engine_var="$eng_sel"
                ;;

            "apklist") command -v apklist &> /dev/null && { apklist; echo -ne "\033[1;30m(Enter)\033[0m"; read; } ;;
            
            "Confirm")
                if [ -z "$func_name" ] || [[ "$func_status" == *"[DUPLICATE]"* ]]; then continue; fi
                
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
        # 套用 Inspector 模板
        menu_display="${menu_display} ${F_GRAY}:: Suite Forge ::${F_RESET}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} Command  : ${F_MAIN}${func_name:-<Empty>}${F_RESET}  ${func_status}\n"
        menu_display="${menu_display} Category : ${F_WARN}${target_cat}${F_RESET}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} Suite    : ${F_SUB}${suite_name}${F_RESET}\n"
        menu_display="${menu_display} Modules  : ${mod_status}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} Confirm  : Forge Neural Link\n"
        menu_display="${menu_display} Cancel   : Abort Operation"

        local selection=$(echo -e "$menu_display" | fzf \
            --ansi --height=50% --layout=reverse --border=bottom \
            --info=hidden \
            --prompt=" :: Suite Forge › " --pointer="››" \
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
                        --info=hidden \
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
        --info=hidden \
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

# 測試發射器 - Test Fire Protocol
function _fac_load() {
    local target="$1"
    local temp_file="$MUX_ROOT/app.sh.temp"

    if [ -z "$target" ]; then
        if ! command -v fzf &> /dev/null; then
            echo -e "${F_ERR} :: Neural Link (fzf) Required.${F_RESET}"
            return 1
        fi

        # 1. 產生列表資料
        local list_data=$(awk '
            BEGIN { 
                current_cat="Uncategorized"
                C_CMD="\x1b[1;37m"
                C_CAT="\x1b[1;30m"
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
                    printf " %s%-14s %s[%s]%s\n", C_CMD, func_name, C_CAT, current_cat, C_RESET;
                }
            }
        ' "$temp_file")

        local selection=$(echo "$list_data" | fzf --ansi \
            --height=60% \
            --layout=reverse \
            --border=bottom \
            --info=hidden \
            --prompt=" :: Test Fire › " \
            --header=" :: Select Target to Execute (Dry Run) ::" \
            --pointer="››" \
            --preview "func=\$(echo {} | awk '{print \$1}'); sed -n \"/^function \$func() {/,/^}/p\" '$temp_file' | head -n 100" \
            --preview-window="right:55%:wrap:border-left" \
            --color=fg:white,bg:-1,hl:208,fg+:white,bg+:235,hl+:208 \
            --color=info:240,prompt:208,pointer:196,marker:208,border:208,header:240 \
            --bind="resize:clear-screen"
        )

        if [ -z "$selection" ]; then return; fi
        target=$(echo "$selection" | awk '{print $1}')
    fi

    echo -e ""
    echo -e "${F_WARN} :: PREPARING TEST FIRE ::${F_RESET}"
    echo -e "${F_GRAY}    Target  : ${F_MAIN}$target${F_RESET}"
    echo -e "${F_GRAY}    Payload : app.sh.temp (Bypassing Safety Interlocks)${F_RESET}"
    echo -e ""
    echo -ne "${F_WARN}    ›› Confirm Launch? [Y/n]: ${F_RESET}"
    read confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${F_GRAY}    ›› Launch aborted.${F_RESET}"
        return
    fi

    echo -e ""
    
    (
        source "$temp_file"
        if ! command -v "$target" &> /dev/null; then
            echo -e "${F_ERR} :: Error: Function '$target' not defined in sandbox.${F_RESET}"
            exit 1
        fi
        "$target"
    )
    
    echo -e "${F_GRAY}    ›› Test sequence complete. Systems normalized.${F_RESET}"
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
                --info=hidden \
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
        menu_display="${menu_display} ${F_GRAY}:: Neural Modifier ::${F_RESET}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} Command  : ${F_MAIN}${func_name}${F_RESET}  ${func_status}\n"
        menu_display="${menu_display} Category : ${F_WARN}${target_cat}${F_RESET}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} UI Name  : ${F_SUB}${ui_name}${F_RESET}\n"
        menu_display="${menu_display} Package  : ${F_SUB}${pkg_id}${F_RESET}\n"
        
        if [ "$app_type" == "BROWSER" ]; then
            menu_display="${menu_display} Engine   : ${F_CYAN}${engine_var}${F_RESET}\n"
        else
            menu_display="${menu_display} Activity : ${F_SUB}${pkg_act:-[Auto]}${F_RESET}\n"
        fi
        
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} Manual   : Edit Source Code (Nano)\n"
        menu_display="${menu_display} Delete   : Terminate Neural Link\n"
        menu_display="${menu_display} Confirm  : Apply Changes\n"
        menu_display="${menu_display} Cancel   : Discard Changes"

        local selection=$(echo -e "$menu_display" | fzf \
            --ansi --height=50% --layout=reverse --border=bottom \
            --info=hidden \
            --prompt=" :: Edit ${app_type} › " --pointer="››" \
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
            "Activity") echo -ne "${F_SUB}    ›› New Activity: ${F_RESET}"; read val; pkg_act="$val" ;; 
            "Engine")
                local eng=$(echo -e "GOOGLE\nBING\nDUCK\nYOUTUBE\nGITHUB" | fzf --height=20% --layout=reverse --border=bottom --info=hidden --prompt=" :: Select Engine › " --pointer="››" --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
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
            --info=hidden \
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

                local sub_sel=$(echo -e "$sub_menu" | fzf --height=40% --layout=reverse --info=hidden --border=bottom --prompt=" :: Module Manager › " --pointer="››" --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
                
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

    if [ -z "$target" ]; then
        if command -v fzf &> /dev/null; then
            target=$(grep "^[[:space:]]*function" "$temp_file" | sed 's/^[[:space:]]*function[[:space:]]\+//' | sed 's/[[:space:]]*() {//' | fzf \
                --height=20% --layout=reverse --border=bottom \
                --info=hidden \
                --prompt=" :: Select Target to Terminate › " \
                --pointer="››" \
                --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
            )
        else
            echo -ne "${F_WARN}    ›› Enter Target Command: ${F_RESET}"
            read target
        fi
    fi

    if [ -z "$target" ]; then return; fi

    local start_line=$(grep -n "^[[:space:]]*function[[:space:]]\+$target[[:space:]]*(" "$temp_file" | head -n1 | cut -d: -f1)
    
    if [ -z "$start_line" ]; then
        _bot_say "error" "Target '$target' not found in Sandbox."
        return 1
    fi

    local header_line=$((start_line - 1))
    local header_content=$(sed "${header_line}q;d" "$temp_file")
    local delete_start=$start_line
    
    if [[ "$header_content" == "# :"* ]]; then
        delete_start=$header_line
    fi

    local relative_end=$(tail -n +$start_line "$temp_file" | grep -n "^}" | head -n1 | cut -d: -f1)
    if [ -z "$relative_end" ]; then return 1; fi

    local delete_end=$((start_line + relative_end - 1))
    local line_count=$((delete_end - delete_start + 1))

    while true; do
        local menu_display=""
        menu_display="${menu_display} ${F_GRAY}:: Destruction Protocol ::${F_RESET}\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} Target   : ${F_ERR}${target}${F_RESET}\n"
        menu_display="${menu_display} Range    : Lines ${delete_start}-${delete_end} (${line_count} lines)\n"
        menu_display="${menu_display} ${F_GRAY}--------------------------------${F_RESET}\n"
        menu_display="${menu_display} Confirm  : Permanently Excise Module\n"
        menu_display="${menu_display} Abort    : Cancel Operation"

        local selection=$(echo -e "$menu_display" | fzf \
            --ansi \
            --height=50% \
            --layout=reverse \
            --border=bottom \
            --info=hidden \
            --prompt=" :: Confirm Kill › " \
            --pointer="››" \
            --preview "sed -n '${delete_start},${delete_end}p' '$temp_file' | nl -v $delete_start -w 3 -s '  '" \
            --preview-window="down:40%:wrap:border-top" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        )

        if [ -z "$selection" ]; then return; fi
        
        if [[ "$selection" == *"Confirm"* ]]; then
            echo -e ""
            echo -ne "${F_ERR} :: Are you sure you want to delete '$target'? [y/N]: ${F_RESET}"
            read final_confirm
            
            if [[ "$final_confirm" == "y" || "$final_confirm" == "Y" ]]; then
                sed -i "${delete_start},${delete_end}d" "$temp_file"
                unset -f "$target" >/dev/null 2>&1
                _fac_maintenance
                _bot_say "success" "Module '$target' terminated."
                return
            else
                _bot_say "factory" "Destruction aborted."
                return
            fi
        elif [[ "$selection" == *"Abort"* ]]; then
            return
        fi
    done
}

# 分類與戰略地圖管理 (Category & Terrain Management)
function _fac_wizard_category() {
    _fac_snapshot
    while true; do
        local menu_display=""
        menu_display="${menu_display}[+] Create Sector  : Add New Category Header\n"
        menu_display="${menu_display}[R] Rename Sector  : Modify Category Label\n"
        menu_display="${menu_display}[M] Move Sector    : Reorder Entire Category Block\n"
        menu_display="${menu_display}[X] Remove Sector  : Delete Header (Merge Apps Up)\n"
        menu_display="${menu_display}\n"
        menu_display="${menu_display}[<] Return to Base"

        local selection=$(echo -e "$menu_display" | fzf \
            --ansi \
            --height=35% \
            --layout=reverse \
            --info=hidden \
            --border=bottom \
            --prompt=" :: Sector Ops › " \
            --header=" :: Manage Neural Partitions ::" \
            --pointer="››" \
            --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        )info

        if [ -z "$selection" ]; then return; fi
        local key=$(echo "$selection" | awk '{print $1}')

        case "$key" in
            "[+]") _fac_cat_add ;;
            "[R]") _fac_cat_rename ;;
            "[M]") _fac_cat_reorder ;; # The Hard Part
            "[X]") _fac_cat_delete ;;
            "[<]") return ;;
        esac
    done
}

# 新增分類標頭 - Add Category Header
function _fac_cat_add() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    
    echo -e ""
    echo -e "${F_MAIN} :: Create New Sector ::${F_RESET}"
    echo -ne "${F_SUB}    ›› Enter New Category Name: ${F_RESET}"
    read new_name
    [ -z "$new_name" ] && return

    # 選擇插入點
    local cat_list=$(grep "^# ===" "$temp_file" | sed 's/# === //;s/ ===//')
    local target=$(echo -e "Checking End of File (Bottom)\n$cat_list" | fzf \
        --height=40% --layout=reverse --border=bottom \
        --info=hidden \
        --prompt=" :: Insert Before › " \
        --header=" :: Select Position ::" \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
    
    if [ -z "$target" ]; then return; fi

    local insert_str="\n\n# === $new_name ===\n"

    if [[ "$target" == "Checking End of File (Bottom)" ]]; then
        echo -e "$insert_str" >> "$temp_file"
        _bot_say "factory" "Sector '$new_name' appended to map."
    else
        local line=$(grep -n "^# === $target ===" "$temp_file" | cut -d: -f1)
        sed -i "${line}i $insert_str" "$temp_file"
        _bot_say "factory" "Sector '$new_name' inserted before '$target'."
    fi
    _fac_maintenance
}

# 區塊移動術 - Block Sector Reorder
function _fac_cat_reorder() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    
    local src_cat=$(grep "^# ===" "$temp_file" | sed 's/# === //;s/ ===//' | fzf \
        --height=40% --layout=reverse --border=bottom \
        --info=hidden \
        --prompt=" :: Select Sector to Move › " \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
    
    [ -z "$src_cat" ] && return

    local s_start=$(grep -n "^# === $src_cat ===" "$temp_file" | cut -d: -f1)
    local s_next=$(tail -n +$((s_start + 1)) "$temp_file" | grep -n "^# ===" | head -n1 | cut -d: -f1)
    
    local s_end=""
    if [ -z "$s_next" ]; then
        s_end=$(wc -l < "$temp_file")
    else
        s_end=$((s_start + s_next - 1))
    fi

    local block_tmp="$MUX_ROOT/plate/sector.tmp"
    sed -n "${s_start},${s_end}p" "$temp_file" > "$block_tmp"
    
    _bot_say "factory" "Lifting sector '$src_cat'..."
    sed -i "${s_start},${s_end}d" "$temp_file"

    local cat_list_new=$(grep "^# ===" "$temp_file" | sed 's/# === //;s/ ===//')
    local target=$(echo -e "Checking End of File (Bottom)\n$cat_list_new" | fzf \
        --height=40% --layout=reverse --border=bottom \
        --info=hidden \
        --prompt=" :: Insert Before › " \
        --header=" :: Select New Position ::" \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)

    if [ -z "$target" ]; then
        _bot_say "error" "Operation canceled. Appending block to bottom."
        cat "$block_tmp" >> "$temp_file"
        rm "$block_tmp"
        return
    fi

    if [[ "$target" == "Checking End of File (Bottom)" ]]; then
        echo "" >> "$temp_file"
        cat "$block_tmp" >> "$temp_file"
    else
        local t_line=$(grep -n "^# === $target ===" "$temp_file" | cut -d: -f1)
        
        if [ "$t_line" -eq 1 ]; then
             local temp_whole=$(mktemp)
             cat "$block_tmp" > "$temp_whole"
             echo "" >> "$temp_whole"
             cat "$temp_file" >> "$temp_whole"
             mv "$temp_whole" "$temp_file"
        else
             local insert_pos=$((t_line - 1))
             echo "" >> "$block_tmp"
             sed -i "${insert_pos}r $block_tmp" "$temp_file"
        fi
    fi

    rm "$block_tmp"
    _fac_maintenance
    _bot_say "success" "Sector '$src_cat' relocated."
}

# 重新命名分類標頭 - Rename Category Header
function _fac_cat_rename() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    
    local old_name=$(grep "^# ===" "$temp_file" | sed 's/# === //;s/ ===//' | fzf \
        --height=40% --layout=reverse --border=bottom \
        --info=hidden \
        --prompt=" :: Select Sector to Rename › " \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
    
    [ -z "$old_name" ] && return

    echo -ne "${F_WARN}    ›› Rename '$old_name' to: ${F_RESET}"
    read new_name
    [ -z "$new_name" ] && return

    sed -i "s/^# === $old_name ===/# === $new_name ===/" "$temp_file"
    _bot_say "success" "Sector renamed to '$new_name'."
}

# 刪除分類標頭 - Delete Category Header
function _fac_cat_delete() {
    local temp_file="$MUX_ROOT/app.sh.temp"
    
    local target=$(grep "^# ===" "$temp_file" | sed 's/# === //;s/ ===//' | fzf \
        --height=40% --layout=reverse --border=bottom \
        --info=hidden \
        --prompt=" :: Select Sector to Remove › " \
        --header=" :: WARNING: Apps will merge to previous sector ::" \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)
    
    [ -z "$target" ] && return

    echo -e "${F_ERR} :: WARNING :: This will remove the HEADER '$target' only.${F_RESET}"
    echo -e "${F_GRAY}    Apps under this sector will merge upwards.${F_RESET}"
    echo -ne "${F_WARN}    ›› Confirm delete? [Y/n]: ${F_RESET}"
    read conf
    if [[ "$conf" == "y" || "$conf" == "Y" ]]; then
        sed -i "/^# === $target ===/d" "$temp_file"
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
                --info=hidden \
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
    local undo2="$MUX_ROOT/.app.sh.undo2"
    local undo3="$MUX_ROOT/.app.sh.undo3"

    if [ ! -f "$undo1" ]; then
        _bot_say "error" "No temporal snapshots found."
        return
    fi

    local list_data=""
    local files=("$undo1" "$undo2" "$undo3")
    local labels=("Undo 1 (Latest)" "Undo 2 (Previous)" "Undo 3 (Oldest)")
    
    for i in {0..2}; do
        if [ -f "${files[$i]}" ]; then
            local ts=""
            if date --version >/dev/null 2>&1; then
                ts=$(date -r "${files[$i]}" "+%H:%M:%S")
            else
                ts=$(date -r "${files[$i]}" "+%H:%M:%S" 2>/dev/null || stat -c %y "${files[$i]}" | cut -d' ' -f2 | cut -d'.' -f1)
            fi
            
            local size=$(du -h "${files[$i]}" | cut -f1)
            list_data="${list_data}[${labels[$i]}] ${ts} (${size})\n"
        fi
    done

    local selection=$(echo -e "$list_data" | fzf \
        --height=20% --layout=reverse --border=bottom \
        --info=hidden \
        --prompt=" :: Time Stone › " \
        --header=" :: Select Timeline to Restore ::" \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
    )

    if [ -z "$selection" ]; then return; fi

    local target_file=""
    if [[ "$selection" == *"[Undo 1]"* ]]; then target_file="$undo1"; fi
    if [[ "$selection" == *"[Undo 2]"* ]]; then target_file="$undo2"; fi
    if [[ "$selection" == *"[Undo 3]"* ]]; then target_file="$undo3"; fi

    if [ -f "$target_file" ]; then
        echo -e ""
        echo -e "\033[1;33m :: WARP WARNING ::\033[0m"
        echo -e "\033[1;37m    Target Snapshot : \033[1;36m$(basename "$target_file")\033[0m"
        echo -e "\033[1;31m    Current Work    : Will be OVERWRITTEN.\033[0m"
        echo -e ""
        
        echo -ne "\033[1;33m :: Confirm Restore? [y/N]: \033[0m"
        read fuse_check
        
        if [[ "$fuse_check" != "y" && "$fuse_check" != "Y" ]]; then
            _bot_say "factory" "Time jump aborted. Current timeline retained."
            return
        fi

        echo -e "\033[1;35m :: Reality shifting...\033[0m"
        cp "$target_file" "$temp_file"
        sleep 0.5
        _fac_maintenance
        _bot_say "success" "Timeline restored."
        
        if command -v _factory_show_status &> /dev/null; then
            echo ""
            _factory_show_status
        fi
    else
        _bot_say "error" "Target snapshot anomaly. File lost."
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
    
    if command -v diff &> /dev/null; then # 資料比對需要修正
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
    
    local time_str="#Last Sync: $(date '+%Y-%m-%d %H:%M:%S') ::"
    local temp_file="$MUX_ROOT/app.csv.temp"
    local prod_file="$MUX_ROOT/app.csv"

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
    local targets=("$MUX_ROOT/app.sh.temp" "$MUX_ROOT/system.sh" "$MUX_ROOT/vendor.sh")
    
    echo -e "${F_MAIN} :: Initiating Mechanism Maintenance...${F_RESET}"
    
    for file in "${targets[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${F_GRAY}    ›› Scanning: $(basename "$file")...${F_RESET}"
            
            if [ -n "$(tail -c 1 "$file")" ]; then
                echo "" >> "$file"
                echo -e "${F_WARN}    ›› Missing EOF newline. ✅${F_RESET}"
            fi
            
            if grep -q "^}[^[:space:]]" "$file"; then
                sed -i 's/^}/}\n/' "$file"
                echo -e "${F_WARN}    ›› Detached glued functions. ✅${F_RESET}"
            fi

            if grep -E "^function" "$file" | grep -vE "^function [a-zA-Z0-9_]+\(\) \{$" >/dev/null; then
                 sed -i -E 's/^function[[:space:]]+([a-zA-Z0-9_]+)/function \1/' "$file"
                 
                 sed -i -E 's/\([[:space:]]*\)[[:space:]]*\{/() {/' "$file"
                 
                 echo -e "${F_WARN}    ›› Normalized function syntax strictness. ✅${F_RESET}"
            fi

            if [[ "$file" == *"app.sh.temp" ]]; then
                if ! grep -q "^# === Others ===" "$file"; then
                    echo -e "\n\n# === Others ===\n" >> "$file"
                    echo -e "${F_WARN}    ›› Restored 'Others' safety net. ✅${F_RESET}"
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
    
    local meta_raw=$(_fac_get_meta "$target")
    IFS='|' read -r m_type m_name m_pkg m_extra <<< "$meta_raw"

    local info_display=""
    
    info_display="${info_display} ${F_GRAY}:: Neural Unit Details ::${F_RESET}\n"
    info_display="${info_display} Sector   : ${F_WARN}${category}${F_RESET}\n"
    info_display="${info_display} ${F_GRAY}--------------------------------${F_RESET}\n"
    info_display="${info_display} Command  : ${F_MAIN}${target}${F_RESET}\n"
    info_display="${info_display} Type     : ${F_CYAN}${m_type}${F_RESET}\n"
    info_display="${info_display} ${F_GRAY}--------------------------------${F_RESET}\n"
    info_display="${info_display} UI Name  : ${F_SUB}${m_name}${F_RESET}\n"
    info_display="${info_display} Package  : ${F_SUB}${m_pkg}${F_RESET}\n"
    
    if [ "$m_type" == "LAUNCHER" ]; then
        info_display="${info_display} Activity : ${F_GRAY}${m_extra:-[Auto]}${F_RESET}\n"
    elif [ "$m_type" == "BROWSER" ]; then
        info_display="${info_display} Engine   : ${F_CYAN}${m_extra}${F_RESET}\n"
    elif [ "$m_type" == "SUITE" ]; then
        info_display="${info_display} Modules  : ${F_WARN}${m_extra} active${F_RESET}\n"
    fi

    echo -e "$info_display" | fzf \
        --ansi \
        --height=40% \
        --layout=reverse \
        --border=bottom \
        --info=hidden \
        --prompt=" :: Neural Unit Details › " \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240
}

# 元數據解析器 - Metadata Extraction Engine
function _fac_get_meta() {
    local target="$1"
    local temp_file="$MUX_ROOT/app.sh.temp"
    
    local func_body=$(sed -n "/^function $target() {/,/^}/p" "$temp_file" | head -n 20)
    
    local type="UNKNOWN"
    local name="Unknown"
    local pkg="Unknown"v
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
    _safe_ui_calc
    clear
    _draw_logo "factory"
    _system_check "factory"
    _show_hud "factory"
    _system_unlock
}

# 函式攔截器 (Function Interceptor)
function _factory_mask_apps() {
    local targets=("$MUX_ROOT/system.sh" "$MUX_ROOT/app.sh.temp" "$MUX_ROOT/vendor.sh")
    
    local whitelist="mux|fac|wb|apklist|termux|clear|ls|cat|grep|fzf|awk|sed|git"

    for file in "${targets[@]}"; do
        if [ -f "$file" ]; then
            local funcs=$(awk '
                /^[[:space:]]*function[[:space:]]+[a-zA-Z0-9_]+/ {
                    gsub(/^[[:space:]]*function[[:space:]]+|\(.*/, ""); print
                }
                /^[[:space:]]*[a-zA-Z0-9_]+\(\)[[:space:]]*\{/ {
                    gsub(/\(.*/, ""); print
                }
            ' "$file")
            
            for func_name in $funcs; do
                if [[ "$func_name" == _* ]]; then continue; fi
                
                if [[ "$func_name" =~ ^($whitelist)$ ]]; then continue; fi

                if declare -f "$func_name" > /dev/null; then
                    eval "function $func_name() { _factory_interceptor \"$func_name\" \"\$@\"; }"
                fi
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
