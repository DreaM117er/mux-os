#!/bin/bash

if [ -z "$MUX_ROOT" ]; then export MUX_ROOT="$HOME/mux-os"; fi
if [ -z "$MUX_BAK" ]; then export MUX_BAK="$MUX_ROOT/bak"; fi

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    if [ -f "$MUX_ROOT/core.sh" ]; then
        export __MUX_NO_AUTOBOOT="true"
        source "$MUX_ROOT/core.sh"
        unset __MUX_NO_AUTOBOOT
    else
        echo -e "\033[1;31m :: FATAL :: Core Uplink Failed. Variables missing.\033[0m"
        return 1 2>/dev/null
    fi
fi

# factory.sh - Mux-OS 兵工廠

F_MAIN="\033[1;38;5;208m"
F_SUB="\033[1;37m"
F_WARN="\033[1;33m"
F_ERR="\033[1;31m"
F_GRAY="\033[1;30m"
F_RESET="\033[0m"
F_GRE="\033[1;32m"

# 神經資料讀取器 - Neural Data Reader
# 用法: _fac_neural_read "chrome" 或 _fac_neural_read "chrome 'incognito'"
function _fac_neural_read() {
    local target_key="$1"
    local target_file="${2:-$MUX_ROOT/app.csv.temp}"

    local t_com=$(echo "$target_key" | awk '{print $1}')
    local t_sub=""
    if [[ "$target_key" == *"'"* ]]; then
        t_sub=$(echo "$target_key" | awk -F"'" '{print $2}')
    fi

    local raw_data=$(awk -v FPAT='([^,]*)|("[^"]+")' \
                         -v key="$t_com" \
                         -v subkey="$t_sub" '
        !/^#/ { 
            row_com = $5; gsub(/^"|"$/, "", row_com); gsub(/\r| /, "", row_com)
            row_com2 = $6; gsub(/^"|"$/, "", row_com2); gsub(/\r| /, "", row_com2)

            if (row_com == key && row_com2 == subkey && subkey != "") {
                print $0; exit
            }
            
            if (row_com == key && row_com2 == "") {
                fallback = $0
            }
        }
        END {
            if (fallback != "") print fallback
        }
    ' "$target_file")

    if [ -z "$raw_data" ]; then return 1; fi

    eval $(echo "$raw_data" | awk -v FPAT='([^,]*)|("[^"]+")' '{
        fields[1]="_VAL_CATNO"
        fields[2]="_VAL_COMNO"
        fields[3]="_VAL_CATNAME"
        fields[4]="_VAL_TYPE"
        fields[5]="_VAL_COM"
        fields[6]="_VAL_COM2"
        fields[7]="_VAL_COM3"
        fields[8]="_VAL_HUDNAME"
        fields[9]="_VAL_UINAME"
        fields[10]="_VAL_PKG"
        fields[11]="_VAL_TARGET"
        fields[12]="_VAL_IHEAD"
        fields[13]="_VAL_IBODY"
        fields[14]="_VAL_URI"
        fields[15]="_VAL_MIME"
        fields[16]="_VAL_CATE"
        fields[17]="_VAL_FLAG"
        fields[18]="_VAL_EX"
        fields[19]="_VAL_EXTRA"
        fields[20]="_VAL_ENGINE"

        for (i=1; i<=20; i++) {
            val = $i
            if (val ~ /^".*"$/) { val = substr(val, 2, length(val)-2) }
            gsub(/""/, "\"", val)
            gsub(/'\''/, "'\''\\'\'''\''", val)
            printf "%s='\''%s'\''; ", fields[i], val
        }
    }')
    
    # 清洗特殊字元 (微調)
    _VAL_ENGINE=${_VAL_ENGINE//$'\r'/}
    return 0
}

# 神經資料寫入器 - Neural Data Writer (Atomic)
# 用法: _fac_neural_write "chrome" 10 "com.android.chrome"
function _fac_neural_write() {
    local target_key="$1"
    local col_idx="$2"
    local new_val="$3"
    local target_file="${4:-$MUX_ROOT/app.csv.temp}"

    local t_com=$(echo "$target_key" | awk '{print $1}')
    local t_sub=""
    if [[ "$target_key" == *"'"* ]]; then
        t_com=$(echo "$target_key" | awk -F"'" '{print $1}' | sed 's/[ \t]*$//')
        t_sub=$(echo "$target_key" | awk -F"'" '{print $2}')
    fi

    local safe_val="${new_val//\"/\"\"}"
    safe_val="\"$safe_val\""

    awk -v FPAT='([^,]*)|("[^"]+")' -v OFS="," \
        -v tc="$t_com" -v ts="$t_sub" \
        -v col="$col_idx" -v val="$safe_val" '
    {
        c=$5; gsub(/^"|"$/, "", c); gsub(/\r| /, "", c)
        s=$6; gsub(/^"|"$/, "", s); gsub(/\r| /, "", s)

        match_found = 0
        if (c == tc) {
            if (ts == "" && s == "") match_found = 1
            if (ts != "" && s == ts) match_found = 1
        }

        if (match_found) {
            $col = val
            
            # new_c = $5; gsub(/^"|"$/, "", new_c)
            # new_s = $6; gsub(/^"|"$/, "", new_s)
            # if (new_s != "") print "UPDATE_KEY:" new_c " \047" new_s "\047" > "/dev/stderr"
            # else print "UPDATE_KEY:" new_c > "/dev/stderr"
        }
        
        print $0
    }
    ' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
}

# 兵工廠系統啟動 (Factory System Boot)
function _factory_system_boot() {
    export __MUX_MODE="factory"

    local bak_dir="${MUX_BAK:-$MUX_ROOT/bak}"
    if [ ! -d "$bak_dir" ]; then mkdir -p "$bak_dir"; fi

    local ts=$(date +%Y%m%d%H%M%S)

    # 前置作業
    if [ -f "$MUX_ROOT/app.csv" ]; then
        cp "$MUX_ROOT/app.csv" "$MUX_ROOT/app.csv.temp"
    else
        echo '"CATNO","COMNO","CATNAME","TYPE","COM","COM2","COM3","HUDNAME","UINAME","PKG","TARGET","IHEAD","IBODY","URI","MIME","CATE","FLAG","EX","EXTRA","ENGINE"' > "$MUX_ROOT/app.csv.temp"
    fi

    export PS1="\[\033[1;38;5;208m\]Fac\[\033[0m\] \w › "
    export PROMPT_COMMAND="tput sgr0; echo -ne '\033[0m'"
    
    # 製作.bak檔案
    rm -f "$bak_dir"/app.csv.*.bak 2>/dev/null
    cp "$MUX_ROOT/app.csv" "$bak_dir/app.csv.$ts.bak"

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
    local bak_dir="${MUX_BAK:-$MUX_ROOT/bak}"
    local target_bak=$(ls -t "$bak_dir"/app.csv.*.bak 2>/dev/null | head -n 1)

    echo ""
    echo -e "${F_ERR} :: CRITICAL WARNING :: FACTORY RESET DETECTED ::${F_RESET}"
    echo -e "${F_GRAY}    This will wipe ALL changes (Sandbox & Production) and pull from Origin.${F_RESET}"
    echo ""
    echo -ne "${F_ERR} :: TYPE 'CONFIRM' TO NUKE: ${F_RESET}"
    read confirm
    echo ""

    if [ "$confirm" == "CONFIRM" ]; then
        _bot_say "loading" "Reversing time flow..."
        
        if [ -n "$target_bak" ] && [ -f "$target_bak" ]; then
            cp "$target_bak" "$MUX_ROOT/app.csv.temp"
            
            if command -v _factory_auto_backup &> /dev/null; then
                _factory_auto_backup
            fi
            
            _fac_init
            _bot_say "success" "Timeline restored to Session Start."
        else
            _bot_say "error" "Session Backup missing. Fallback to Production."
            if [ -f "$MUX_ROOT/app.csv" ]; then
                cp "$MUX_ROOT/app.csv" "$MUX_ROOT/app.csv.temp"
                _fac_init
                _bot_say "success" "Restored from Production (app.csv)."
            else
                _bot_say "error" "Critical Failure: No source available."
            fi
        fi
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
        _bot_say "fail" "Factory commands disabled during Core session."
        return 1
    fi

    if [ -z "$cmd" ]; then
        _bot_say "factory_welcome"
        return
    fi

    case "$cmd" in
        # : Open Neural Forge Menu
        "menu"|"commenu"|"comm")
            local view_state="VIEW"

            while true; do
                local raw_target=$(_factory_fzf_menu "Select App to Inspect")
                if [ -z "$raw_target" ]; then break; fi
                
                local clean_target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                if [ "$view_state" == "VIEW" ]; then
                    _factory_fzf_detail_view "$clean_target" "VIEW" > /dev/null
                fi
            done
            ;;

        # : Open Category Menu
        "catmenu"|"catm")
            local view_state="VIEW"

            while true; do
                local raw_cat=$(_factory_fzf_cat_selector)
                if [ -z "$raw_cat" ]; then break; fi
                
                local temp_id=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')

                local db_name=$(awk -F, -v tid="$temp_id" '
                    NR>1 {
                        cid=$1; gsub(/^"|"$/, "", cid)
                        if (cid == tid) {
                            name=$3; gsub(/^"|"$/, "", name)
                            print name
                            exit
                        }
                    }
                ' "$MUX_ROOT/app.csv.temp")

                if [ -z "$db_name" ]; then 
                    db_name=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{$1=""; print $0}' | sed 's/^[ \t]*//')
                fi

                while true; do
                    local raw_cmd=$(_factory_fzf_cmd_in_cat "$db_name")
                    if [ -z "$raw_cmd" ]; then break; fi
                    
                    local clean_cmd=$(echo "$raw_cmd" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')

                    if [ "$view_state" == "VIEW" ]; then
                        _factory_fzf_detail_view "$clean_cmd" "VIEW" > /dev/null
                    fi
                done
            done
            ;;

        # : Check & Fix Formatting
        "check")
            _fac_maintenance
            _fac_sort_optimization
            _fac_matrix_defrag
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
            local type_sel=$(_factory_fzf_add_type_menu)
            
            if [[ -z "$type_sel" || "$type_sel" == "Cancel" || "$type_sel" == *"------"* ]]; then
                return
            fi

            if command -v _factory_auto_backup &> /dev/null; then
                _fac_maintenance
                _factory_auto_backup
            fi

            local next_comno=$(awk -F, '$1==999 {gsub(/^"|"$/, "", $2); if(($2+0) > max) max=$2} END {print max+1}' "$MUX_ROOT/app.csv.temp")
            
            if [ -z "$next_comno" ] || [ "$next_comno" -eq 1 ]; then next_comno=1; fi
            if ! [[ "$next_comno" =~ ^[0-9]+$ ]]; then next_comno=999; fi

            local ts=$(date +%s)
            local temp_cmd_name="ND${ts}"

            local target_cat="999"
            local target_catname="\"Others\""
            local com3_flag="N"
            local new_row=""
            
            case "$type_sel" in
                "Command NA")
                    # NA 模板
                    new_row="${target_cat},${next_comno},${target_catname},\"NA\",\"${temp_cmd_name}\",,\"${com3_flag}\",,,,,,,,,,,,,"
                    ;;
                "Command NB")
                    # NB 模板
                    new_row="${target_cat},${next_comno},${target_catname},\"NB\",\"${temp_cmd_name}\",,\"${com3_flag}\",,,,,,,,\"$(echo '$__GO_TARGET')\",,,,,,\"$(echo '$SEARCH_GOOGLE')\""
                    ;;
                *) 
                    return ;;
            esac

            if [ -n "$new_row" ]; then
                echo "$new_row" >> "$MUX_ROOT/app.csv.temp"
                
                _bot_say "action" "Initializing Construction Sequence..."
                
                _fac_safe_edit_protocol "${temp_cmd_name}"
                
                if ! _fac_neural_read "${temp_cmd_name}" >/dev/null 2>&1; then
                    : 
                else
                    _bot_say "action" "Creation Aborted. Cleaning up..."
                    _fac_delete_node "${temp_cmd_name}"
                fi
            fi
            ;;

        # : Edit Neural (Edit Command)
        "edit"|"comedit"|"comm")
            local view_state="EDIT"

            if [ -n "$clean_target" ]; then
                _fac_safe_edit_protocol "$clean_target"
                return
            fi

            while true; do
                local raw_target=$(_factory_fzf_menu "Select App to EDIT" "EDIT")
                if [ -z "$raw_target" ]; then break; fi
                local clean_target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')

                _fac_safe_edit_protocol "$clean_target"
            done
            ;;

        # : Edit Category
        "catedit"|"cate")
            local view_state="EDIT"

            while true; do
                local raw_cat=$(_factory_fzf_cat_selector)
                if [ -z "$raw_cat" ]; then break; fi
                
                local temp_id=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')

                local db_data=$(awk -F, -v tid="$temp_id" 'NR>1 {gsub(/^"|"$/, "", $1); if($1==tid){gsub(/^"|"$/, "", $3); print $1 "|" $3; exit}}' "$MUX_ROOT/app.csv.temp")
                local cat_id=$(echo "$db_data" | awk -F'|' '{print $1}')
                local cat_name=$(echo "$db_data" | awk -F'|' '{print $2}')
                if [ -z "$cat_id" ]; then cat_id="XX"; cat_name="Unknown"; fi

                while true; do
                    local action=$(_factory_fzf_catedit_submenu "$cat_id" "$cat_name" "EDIT")
                    if [ -z "$action" ]; then break; fi

                    if echo "$action" | grep -q "Edit Name" ; then
                        _bot_say "action" "Rename Category [$cat_name]:"
                        read -e -p "    › " -i "$cat_name" new_cat_name
                        
                        if [ -n "$new_cat_name" ] && [ "$new_cat_name" != "$cat_name" ]; then
                            _fac_update_category_name "$cat_id" "$new_cat_name"
                            cat_name="$new_cat_name"
                        fi
                        
                    elif echo "$action" | grep -q "Edit Command in" ; then
                        while true; do
                            local raw_cmd=$(_factory_fzf_cmd_in_cat "$cat_name")
                            if [ -z "$raw_cmd" ]; then break; fi
                            local clean_target=$(echo "$raw_cmd" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                            _fac_safe_edit_protocol "$clean_target"
                        done
                    fi
                done
            done
            ;;

        # : Break Neural (Delete Command)
        "del"|"comd"|"delcom")
            local view_state="DEL"

            while true; do
                local raw_target=$(_factory_fzf_menu "Select Target to DESTROY" "DEL")
                if [ -z "$raw_target" ]; then break; fi

                local clean_target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                _fac_neural_read "$clean_target"
                local del_pkg="${_VAL_PKG:-N/A}"
                local del_desc="${_VAL_HUDNAME:-N/A}"

                echo -e ""
                echo -e "${F_WARN} :: WARNING :: NEUTRALIZING TARGET NODE ::${F_RESET}"
                echo -e "${F_WARN}    Target Identifier : [${clean_target}]${F_RESET}"
                echo -e "${F_GRAY}    Package Binding   : ${del_pkg}${F_RESET}"
                echo -e "${F_GRAY}    Description       : ${del_desc}${F_RESET}"
                echo -e ""
                echo -ne "${F_ERR}    ›› TYPE 'y' TO CONFIRM DESTRUCTION: ${F_RESET}"
                
                read -n 1 -r conf
                echo -e "" 
                
                if [[ "$conf" =~ ^[Yy]$ ]]; then
                    _bot_say "action" "Executing Deletion..."

                    _fac_delete_node "$clean_target"
                    
                    sleep 0.2
                    echo -e "${F_GRAY}    ›› Target neutralized.${F_RESET}"
                    
                    _fac_sort_optimization
                    _fac_matrix_defrag
                    
                    sleep 0.5
                else
                    echo -e "${F_GRAY}    ›› Operation Aborted.${F_RESET}"
                    sleep 0.5
                fi
            done
            ;;
        
        # : Delete Command via Category (Filter Search)
        "catd"|"catdel")
            local view_state="DEL"

            while true; do
                local raw_cat=$(_factory_fzf_cat_selector "DEL")
                if [ -z "$raw_cat" ]; then break; fi
                
                local temp_id=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
                local db_name=$(awk -F, -v tid="$temp_id" 'NR>1 {cid=$1; gsub(/^"|"$/, "", cid); if(cid==tid){name=$3; gsub(/^"|"$/, "", name); print name; exit}}' "$MUX_ROOT/app.csv.temp")
                if [ -z "$db_name" ]; then db_name="Unknown"; fi

                local action=$(_factory_fzf_catedit_submenu "$temp_id" "$db_name" "DEL")
                
                if [ -z "$action" ]; then continue; fi

                # Branch A: 解散分類 (Delete Category)
                if [[ "$action" == *"Delete Category"* ]]; then
                    echo -e "\033[1;31m :: CRITICAL: Dissolving Category [$db_name] [$temp_id] \033[0m"
                    echo -e "\033[1;30m    All assets will be transferred to [Others] [999].\033[0m"
                    
                    if [ "$temp_id" == "999" ]; then
                         _bot_say "error" "Cannot dissolve the [Others] singularity."
                         continue
                    fi

                    echo -ne "\033[1;33m    ›› TYPE 'CONFIRM' TO DEPLOY: \033[0m"
                    read -r confirm
                    if [ "$confirm" == "CONFIRM" ]; then
                        if command -v _factory_auto_backup &> /dev/null; then _factory_auto_backup; fi
                        _fac_safe_merge "999" "$temp_id"
                         awk -F, -v tid="$temp_id" -v OFS=, '$1 != tid {print $0}' "$MUX_ROOT/app.csv.temp" > "$MUX_ROOT/app.csv.temp.tmp" && mv "$MUX_ROOT/app.csv.temp.tmp" "$MUX_ROOT/app.csv.temp"
                        
                        _bot_say "success" "Category Dissolved."

                        _fac_sort_optimization
                        _fac_matrix_defrag
                        break
                    else
                        echo -e "${F_GRAY}    ›› Operation Aborted.${F_RESET}"
                    fi

                # Branch B: 肅清指令 (Delete Command in...)
                elif [[ "$action" == *"Delete Command"* ]]; then
                    while true; do
                        local raw_cmd=$(_factory_fzf_cmd_in_cat "$db_name" "DEL")
                        if [ -z "$raw_cmd" ]; then break; fi
                        
                        local clean_target=$(echo "$raw_cmd" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                         
                        _fac_neural_read "$clean_target"
                        local del_pkg="${_VAL_PKG:-N/A}"

                        echo -e "\033[1;31m :: WARNING :: NEUTRALIZING TARGET NODE ::\033[0m"
                        echo -e "\033[1;31m    Deleting Node [$clean_target] ($del_pkg)\033[0m"
                        echo -ne "\033[1;33m    ›› Confirm destruction? [Y/n]: \033[0m"
                        read -r choice
                        
                        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                            if command -v _factory_auto_backup &> /dev/null; then _factory_auto_backup; fi
                            _fac_delete_node "$clean_target"
                            
                            _bot_say "success" "Target neutralized."

                            _fac_sort_optimization
                            _fac_matrix_defrag
                        fi
                    done
                fi
            done
            ;;

        # : Time Stone Undo (Rebak)
        "undo"|"rebak")
            _fac_rebak_wizard
            ;;

        # : Load Neural (Test Command)
        "load"|"test") 
            echo -e "${F_SUB} :: Command Need Build${F_RESET}"
            ;;

        # : Show Factory Info
        "info")
            if command -v _factory_show_info &> /dev/null; then
                _factory_show_info
            fi
            ;;

        # : Reload Factory
        "reload")
            sleep 0.1
            if [ -f "$MUX_ROOT/gate.sh" ]; then
                source "$MUX_ROOT/gate.sh" "factory"
            else
                source "$MUX_ROOT/factory.sh"
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
            echo -e "${F_WARN} :: Unknown Directive: '$cmd'.${F_RESET}"
            ;;
    esac
}

# 兵工廠快速列表 - List all commands
function _fac_list() {
    local target_file="$MUX_ROOT/app.csv.temp"
    local width=$(tput cols)
    
    echo -e "${F_WARN} :: Mux-OS Command Registry :: ${F_RESET}"
    
    awk -v FPAT='([^,]*)|("[^"]+")' 'NR>1 {
        raw_com = $5
        gsub(/^"|"$/, "", raw_com)
        
        raw_sub = $6
        gsub(/^"|"$/, "", raw_sub)
        
        if (raw_com != "") {
            if (raw_sub != "") {
                print raw_com " " raw_sub
            } else {
                print raw_com
            }
        }
    }' "$target_file" | sort | pr -t -3 -w "$width"
    
    echo -e "${F_GRAY} :: End of List :: ${F_RESET}"
}

# 自動備份 - Auto Backup
function _factory_auto_backup() {
    local bak_dir="${MUX_BAK:-$MUX_ROOT/bak}"
    local ts=$(date +%Y%m%d%H%M%S)
    
    cp "$MUX_ROOT/app.csv.temp" "$bak_dir/app.csv.$ts.atb"
    
    local count=$(ls -1 "$MUX_BAK"/app.csv.atb.* 2>/dev/null | wc -l)
    
    ls -t "$bak_dir"/app.csv.*.atb 2>/dev/null | tail -n +11 | xargs -r rm
}

# 災難復原精靈 - Recovery Wizard
function _fac_rebak_wizard() {
    local bak_dir="${MUX_BAK:-$MUX_ROOT/bak}"
    
    if [ ! -d "$bak_dir" ]; then
        _bot_say "error" "No Backup Repository Found."
        return 1
    fi

    local menu_list=$(
        cd "$bak_dir" && ls -t app.csv.* 2>/dev/null | while read -r fname; do
            local raw_ts=$(echo "$fname" | awk -F'.' '{print $3}')
            local ext=$(echo "$fname" | awk -F'.' '{print $4}')
            
            if [[ ${#raw_ts} -eq 14 ]]; then
                local fmt_ts="${raw_ts:0:4}-${raw_ts:4:2}-${raw_ts:6:2} ${raw_ts:8:2}:${raw_ts:10:2}:${raw_ts:12:2}"
            else
                local fmt_ts="Unknown-Timestamp"
            fi

            local tag=""
            if [ "$ext" == "bak" ]; then
                tag="\033[1;36m[Session]\033[0m"
            else
                tag="\033[1;38;5;208m[AutoSave]\033[0m"
            fi

            printf "%-20s %-20b %s\n" "$fmt_ts" "$tag" "$fname"
        done
    )
    
    if [ -z "$menu_list" ]; then
        _bot_say "error" "Backup Repository is Empty."
        return 1
    fi

    local selected_line=$(echo "$menu_list" | fzf --ansi \
        --height=12 \
        --layout=reverse \
        --border=bottom \
        --info=hidden \
        --prompt=" :: Restore Point › " \
        --header=" :: Select Timeline to Restore :: " \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        --bind="resize:clear-screen"
        )

    if [ -z "$selected_line" ]; then return; fi

    local target_file=$(echo "$selected_line" | awk '{print $NF}')

    if [ -n "$target_file" ] && [ -f "$bak_dir/$target_file" ]; then
        echo ""
        echo -e "${F_ERR} :: WARNING: This will overwrite your current workspace!${F_RESET}"
        echo -e "${F_GRAY}    Source: $target_file${F_RESET}"
        echo -ne "${F_WARN} :: Confirm? [Y/n]: ${F_RESET}"
        read -r confirm

        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            cp "$bak_dir/$target_file" "$MUX_ROOT/app.csv.temp"
            echo -e "${F_WARN} :: Workspace Restored from: $target_file${F_RESET}"
            sleep 0.3
            echo -e "${F_GRAY}    ›› Verified. ✅.${F_RESET}"
            sleep 1.6
            _fac_init
        else
            echo -e "${F_GRAY}    ›› Restore Canceled.${F_RESET}"
        fi
    else
         _bot_say "error" "Target file not found (Extraction Error)."
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
    echo ""
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        _fac_init
        echo -e ""
        _bot_say "factory" "Deployment canceled. Sandbox state retained."
        echo -e "${F_GRAY}    ›› To discard changes: type 'fac reset'${F_RESET}"
        echo -e "${F_GRAY}    ›› To resume editing : type 'fac edit'${F_RESET}"
        return
    fi
    
    echo -e "${F_ERR} :: CRITICAL WARNING ::${F_RESET}"
    echo -e "${F_SUB}    Sandbox (.temp) will OVERWRITE Production (app.csv).${F_RESET}"
    echo -e "${F_SUB}    This action is irreversible via undo.${F_RESET}"
    echo ""
    echo -ne "${F_ERR} :: TYPE 'CONFIRM' TO DEPLOY: ${F_RESET}"
    read confirm
    echo ""
    if [ "$confirm" != "CONFIRM" ]; then
        _fac_init
        _bot_say "error" "Confirmation failed. Deployment aborted."
        return
    fi

    sleep 1.0
    
    local temp_file="$MUX_ROOT/app.csv.temp"
    local prod_file="$MUX_ROOT/app.csv"

    if [ -f "$temp_file" ]; then
        mv "$temp_file" "$prod_file"
        
        if [ -f "$temp_file" ]; then
            rm -f "$temp_file"
        fi
    else
         _bot_say "error" "Sandbox integrity failed."
         sleep 1.9
         return 1
    fi
    
    echo -e "${F_GRE} :: DEPLOYMENT SUCCESSFUL ::${F_RESET}"
    sleep 1.9
    
    if [ -f "$MUX_ROOT/gate.sh" ]; then
        source "$MUX_ROOT/gate.sh" "core"
    else
        echo "core" > "$MUX_ROOT/.mux_state"
        source "$MUX_ROOT/core.sh"
    fi
}

# 機體維護工具 (Mechanism Maintenance)
function _fac_maintenance() {
    echo -e "${F_GRAY} :: Scanning Neural Integrity...${F_RESET}"
    
    local target_file="$MUX_ROOT/app.csv.temp"
    local temp_file="${target_file}.chk"

    if [ ! -f "$target_file" ]; then return; fi

    awk -F, -v OFS=, '
        NR==1 { print; next }
        
        {
            catname=$3;   gsub(/^"|"$/, "", catname)
            type=$4;   gsub(/^"|"$/, "", type)
            pkg=$10;   gsub(/^"|"$/, "", pkg)
            tgt=$11;   gsub(/^"|"$/, "", tgt)
            ihead=$12; gsub(/^"|"$/, "", ihead)
            ibody=$13; gsub(/^"|"$/, "", ibody)
            uri=$14;   gsub(/^"|"$/, "", uri)
            
            valid = 0
            
            if (type == "NA") {
                if (pkg != "" && tgt != "") {
                    valid = 1
                }
            }
            else if (type == "NB") {
                if (ihead != "" && ibody != "") {
                    valid = 1
                }
                else if (pkg != "") {
                    valid = 1
                }
                else if (uri != "") {
                    valid = 1
                }
            }
            else if (type == "SYS" || type == "SSL") {
                # [預留] 系統指令暫時放行，或定義更嚴格規則
                valid = 1
            }
            
            if (valid == 0) {
                $1 = ""
                $2 = ""
                $3 = "\"\""
                $7 = "\"F\""
            }
            
            print $0
        }
    ' "$target_file" > "$temp_file"

    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$target_file"
        echo -e "${F_GRE}    ›› Neural Nodes Verified.${F_RESET}"
    else
        rm "$temp_file"
        echo -e "${F_ERR}    ›› Maintenance Failed: Output empty.${F_RESET}"
    fi
}

# 系統序列重整與優化 - System Sort Optimization
function _fac_sort_optimization() {
    echo -e "${F_GRAY} :: Optimizing Neural Sequence...${F_RESET}"

    local target_file="$MUX_ROOT/app.csv.temp"
    local temp_file="${target_file}.sorted"

    if [ ! -f "$target_file" ]; then
        echo -e "${F_ERR} :: Target Neural Map not found.${F_RESET}"
        return 1
    fi

    head -n 1 "$target_file" > "$temp_file"

    tail -n +2 "$target_file" | sort -t',' -k1,1n -k2,2n >> "$temp_file"

    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$target_file"
        echo -e "${F_GRE}    ›› Sequence Optimized. Nodes Realigned.${F_RESET}"
    else
        rm "$temp_file"
        echo -e "${F_ERR}    ›› Optimization Failed: Empty Output.${F_RESET}"
    fi
}

# 安全合併與繼承系統 - Safe Merge & Inheritance Protocol
function _fac_safe_merge() {
    local target_id="$1"
    local source_id="$2"
    local target_file="$MUX_ROOT/app.csv.temp"
    local temp_file="${target_file}.merge"

    if [ -z "$target_id" ] || [ -z "$source_id" ]; then
        echo -e "${F_ERR} :: Merge Protocol Error: Missing coordinates.${F_RESET}"
        return 1
    fi

    echo -e "${F_GRAY} :: Migrating Node Matrix: [${source_id}] ›› [${target_id}]...${F_RESET}"

    eval $(awk -F, -v tid="$target_id" '
        BEGIN { max=0; name="Unknown" }
        {
            id=$1; gsub(/^"|"$/, "", id)
            cno=$2; gsub(/^"|"$/, "", cno)
            nm=$3; gsub(/^"|"$/, "", nm)
            
            if (id == tid) {
                name = nm
                if ((cno+0) > max) max = cno+0
            }
        }
        END {
            printf "local TARGET_NAME=\"%s\"\n", name
            printf "local START_SEQ=%d\n", max
        }
    ' "$target_file")

    if [ "$target_id" == "999" ] && [ "$TARGET_NAME" == "Unknown" ]; then
        TARGET_NAME="Others"
    fi

    awk -F, -v sid="$source_id" \
            -v tid="$target_id" \
            -v tname="$TARGET_NAME" \
            -v seq="$START_SEQ" '
        BEGIN { OFS="," }
        
        NR==1 { print; next }
        
        {
            cid=$1; gsub(/^"|"$/, "", cid)
            
            if (cid == sid) {
                seq++
                $1 = tid
                $2 = seq
                $3 = "\"" tname "\""
                
                print $0
            } else {
                print $0
            }
        }
    ' "$target_file" > "$temp_file"

    # Phase 3: 部署 (Deploy)
    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$target_file"
        echo -e "${F_GRE}    ›› Matrix Merged. Assets Transferred.${F_RESET}"
        
        _fac_sort_optimization
        _fac_matrix_defrag
    else
        rm "$temp_file"
        echo -e "${F_ERR}    ›› Merge Failed: Output stream broken.${F_RESET}"
    fi
}

# 矩陣重組與格式化 - Matrix Defragmentation & Sanitizer
function _fac_matrix_defrag() {
    local target_file="$MUX_ROOT/app.csv.temp"
    local temp_file="${target_file}.defrag"

    if [ ! -f "$target_file" ]; then return; fi

    _fac_sort_optimization > /dev/null

    echo -e "${F_GRAY} :: Defragmenting Matrix (Smart Indexing)...${F_RESET}"

    awk -F, -v OFS=, '
        NR==1 { print; next }

        {
            curr_cat_orig = $1; gsub(/^"|"$/, "", curr_cat_orig)
            curr_name = $3; gsub(/^"|"$/, "", curr_name)

            if (curr_name != prev_name) {
                com_seq = 1
                
                if (curr_name == "Others" || curr_cat_orig == 999) {
                    current_cat_id = 999
                } else {
                    cat_seq++
                    current_cat_id = cat_seq
                }
                
                prev_name = curr_name
            } else {
                com_seq++
            }

            $1 = current_cat_id
            $2 = com_seq

            # $3 = "\"" curr_name "\""

            print $0
        }
    ' "$target_file" > "$temp_file"

    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$target_file"
        echo -e "${F_GRE}    ›› Matrix Defragmented. Categories Shifted.${F_RESET}"
    else
        rm "$temp_file"
        echo -e "${F_ERR}    ›› Defrag Failed.${F_RESET}"
    fi
}

# 安全沙盒編輯協議 - Safe Edit Protocol
function _fac_safe_edit_protocol() {
    local original_key="$1"
    local target_file="$MUX_ROOT/app.csv.temp"

    if ! _fac_neural_read "$original_key"; then
        _bot_say "error" "Source Node Not Found."
        return 1
    fi

    local orig_com="$_VAL_COM"
    local orig_sub="$_VAL_COM2"
    
    local draft_com="${orig_com}_DRAFT"
    local draft_key="${draft_com}"
    if [ -n "$orig_sub" ]; then
        draft_key="${draft_com} '${orig_sub}'"
    fi

    _bot_say "action" "Initializing Draft Sandbox..."

    local draft_row="999,999,\"DRAFT MODE\",\"$_VAL_TYPE\",\"$draft_com\",\"$orig_sub\",\"EDITING\",\"$_VAL_HUDNAME\",\"$_VAL_UINAME\",\"$_VAL_PKG\",\"$_VAL_TARGET\",\"$_VAL_IHEAD\",\"$_VAL_IBODY\",\"$_VAL_URI\",\"$_VAL_MIME\",\"$_VAL_CATE\",\"$_VAL_FLAG\",\"$_VAL_EX\",\"$_VAL_EXTRA\",\"$_VAL_ENGINE\""
    
    echo "$draft_row" >> "$target_file"

    local loop_status="EDIT"
    local current_draft_key="$draft_key"

    while true; do
        local selection=$(_factory_fzf_detail_view "$current_draft_key" "EDIT")
        
        if [ -z "$selection" ]; then
            loop_status="CANCEL"
            break
        fi

        local router_out
        router_out=$(_fac_edit_router "$selection" "$current_draft_key" "EDIT")
        local router_code=$?
        
        echo "$router_out" | grep -v "UPDATE_KEY"

        if [ $router_code -eq 1 ]; then
            loop_status="CONFIRM"
            break
        elif [ $router_code -eq 2 ]; then

            local new_k=$(echo "$router_out" | awk -F: '{print $2}')
            if [ -n "$new_k" ]; then current_draft_key="$new_k"; fi
        fi
    done

    if [ "$loop_status" == "CONFIRM" ]; then
        _bot_say "neural" "Committing Changes..."

        _fac_delete_node "$original_key"
        
        _fac_neural_read "$current_draft_key"
        local final_com_raw="$_VAL_COM"
        
        local final_real_com=${final_com_raw%_DRAFT}
        
        _fac_neural_write "$current_draft_key" 7 ""
        _fac_neural_write "$current_draft_key" 5 "$final_real_com"
        
        _fac_sort_optimization
        _fac_matrix_defrag
        
        _bot_say "success" "Node Updated & Re-indexed."
        
    else
        _bot_say "action" "Discarding Draft..."
        _fac_delete_node "$current_draft_key"
    fi
}

# 原子寫入函數 - Atomic Node Updater
function _fac_update_node() {
    # 用法: _fac_update_node "TARGET_KEY" "COL_INDEX" "NEW_VALUE"
    local target_key="$1"
    local col_idx="$2"
    local new_val="$3"
    local target_file="$MUX_ROOT/app.csv.temp"

    local t_com=$(echo "$target_key" | awk '{print $1}')
    local t_sub=""
    if [[ "$target_key" == *"'"* ]]; then
        t_com=$(echo "$target_key" | awk -F"'" '{print $1}' | sed 's/[ \t]*$//')
        t_sub=$(echo "$target_key" | awk -F"'" '{print $2}')
    fi

    awk -F, -v OFS=, -v tc="$t_com" -v ts="$t_sub" \
        -v col="$col_idx" -v val="$new_val" '
    {
        gsub(/^"|"$/, "", $5); c=$5
        gsub(/^"|"$/, "", $6); s=$6
        
        match_found = 0
        if (c == tc) {
            if (ts == "" && s == "") match_found = 1
            if (ts != "" && s == ts) match_found = 1
        }

        if (match_found) {
            $col = "\"" val "\""
            
            new_c = $5; gsub(/^"|"$/, "", new_c)
            new_s = $6; gsub(/^"|"$/, "", new_s)
            
            if (new_s != "") {
                print new_c " \047" new_s "\047" > "/dev/stderr" # 輸出到 stderr 讓 Shell 捕捉
            } else {
                print new_c > "/dev/stderr"
            }
        }
        print $0
    }' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
}

# 原子刪除函數 - Atomic Node Deleter
function _fac_delete_node() {
    local target_key="$1"
    local target_file="$MUX_ROOT/app.csv.temp"

    local t_com=$(echo "$target_key" | awk '{print $1}')
    local t_sub=""
    if [[ "$target_key" == *"'"* ]]; then
        t_com=$(echo "$target_key" | awk -F"'" '{print $1}' | sed 's/[ \t]*$//')
        t_sub=$(echo "$target_key" | awk -F"'" '{print $2}')
    fi

    awk -v FPAT='([^,]*)|("[^"]+")' \
        -v tc="$t_com" -v ts="$t_sub" '
    {
        raw = $0
        
        c=$5; gsub(/^"|"$/, "", c); gsub(/\r| /, "", c)
        s=$6; gsub(/^"|"$/, "", s); gsub(/\r| /, "", s)
        
        match_found = 0
        if (c == tc) {
            if (ts == "" && s == "") match_found = 1
            if (ts != "" && s == ts) match_found = 1
        }

        if (match_found) {
            print "Deleted Node: [" c " " s "]" > "/dev/stderr"
            next
        }
        
        print raw
    }' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
}

# 房間引導手冊 - Room Context Guide
function _fac_room_guide() {
    # 用法: _fac_room_guide "ROOM_ID"
    local room_id="$1"
    local guide_text=""
    local example_text=""

    case "$room_id" in
        "ROOM_CMD")
            guide_text="Enter the CLI trigger command."
            example_text="Example: 'chrome', 'music', 'sys_info' (No spaces)"
            ;;
        "ROOM_HUD")
            guide_text="Enter the Description shown in the menu."
            example_text="Example: 'Google Chrome Browser'"
            ;;
        "ROOM_UI")
            guide_text="Specify UI rendering mode."
            example_text="Options: [Empty]=Default, 'fzf', 'cli', 'silent'"
            ;;
        "ROOM_PKG")
            guide_text="Target Android Package Name."
            example_text="Example: 'com.android.chrome'"
            ;;
        "ROOM_ACT")
            guide_text="Target Activity Class (Optional)."
            example_text="Example: 'com.google.android.apps.chrome.Main'"
            ;;
        "ROOM_FLAG")
            guide_text="Execution Flags."
            example_text="Options: '--user 0', '--grant-read-uri-permission'"
            ;;
        "ROOM_INTENT")
            guide_text="Intent Action Head & Body."
            example_text="Format: 'android.intent.action.VIEW'"
            ;;
        "ROOM_URI")
            guide_text="Target URI or Engine Variable."
            example_text="Example: 'https://google.com' OR '\$SEARCH_ENGINE'"
            ;;
        *)
            guide_text="Edit value for this field."
            ;;
    esac

    echo -e "${F_GRAY}    :: Guide   : ${guide_text}${F_RESET}"
    if [ -n "$example_text" ]; then
        echo -e "${F_GRAY}    :: Format  : ${example_text}${F_RESET}"
    fi
    echo -e ""
}

# 通用單欄位編輯器 - Generic Editor
function _fac_generic_edit() {
    local target_key="$1"
    local col_idx="$2"
    local prompt_text="$3"
    
    # 1. 讀取最新狀態
    _fac_neural_read "$target_key"
    
    # 2. 映射欄位索引到變數 (為了顯示 Default Value)
    local current_val=""
    case "$col_idx" in
        8) current_val="$_VAL_HUDNAME" ;;
        9) current_val="$_VAL_UINAME" ;;
        10) current_val="$_VAL_PKG" ;;
        11) current_val="$_VAL_TARGET" ;;
        12) current_val="$_VAL_IHEAD" ;;
        13) current_val="$_VAL_IBODY" ;;
        14) current_val="$_VAL_URI" ;;
        15) current_val="$_VAL_MIME" ;;
        16) current_val="$_VAL_CATE" ;;
        17) current_val="$_VAL_FLAG" ;;
        18) current_val="$_VAL_EX" ;;
        19) current_val="$_VAL_EXTRA" ;;
        20) current_val="$_VAL_ENGINE" ;;
        *) current_val="" ;;
    esac
    
    _bot_say "action" "$prompt_text"
    if command -v _fac_room_guide &> /dev/null; then
        # 自動偵測 Room ID 太複雜，這裡暫時跳過，或你可以傳入 Room ID
        echo -e "${F_GRAY}    Current: [ ${current_val:-Empty} ]${F_RESET}"
    else
        echo -e "${F_GRAY}    Current: [ ${current_val:-Empty} ]${F_RESET}"
    fi
    
    read -e -p "    › " -i "$current_val" input_val
    
    # 4. 原子寫入
    _fac_neural_write "$target_key" "$col_idx" "$input_val"
    _bot_say "success" "Parameter Updated."
}

# 分類名稱批量更新器 - Batch Category Renamer
function _fac_update_category_name() {
    local target_id="$1"
    local new_name="$2"
    local target_file="$MUX_ROOT/app.csv.temp"
    
    local safe_name="${new_name//\"/\"\"}"
    safe_name="\"$safe_name\""

    echo -e "${F_GRAY}    ›› Updating Category [${target_id}] to ${safe_name}...${F_RESET}"

    awk -v FPAT='([^,]*)|("[^"]+")' -v OFS="," \
        -v tid="$target_id" -v val="$safe_name" '
    {
        cid=$1; gsub(/^"|"$/, "", cid)
        
        if (cid == tid) {
            $3 = val
        }
        print $0
    }' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
    
    _bot_say "success" "Category Renamed."
}

# 核心編輯路由器 (The Logic Router)
function _fac_edit_router() {
    local raw_selection="$1"
    local target_key="$2"
    local view_mode="${3:-EDIT}"

    local room_id=$(echo "$raw_selection" | awk -F'\t' '{print $2}')
    
    if command -v _fac_room_guide &> /dev/null; then
        _fac_room_guide "$room_id"
    fi
    
    local header_text="MODIFY PARAMETER"
    local border_color="208"
    local prompt_color="208"
    
    case "$view_mode" in
        "NEW") header_text="CONFIRM CREATION"; border_color="46"; prompt_color="46" ;;
        "DEL") header_text="DELETE PARAMETER"; border_color="196"; prompt_color="196" ;;
        "EDIT"|*) header_text="MODIFY PARAMETER :: "; border_color="208"; prompt_color="208" ;;
    esac

    local room_id=$(echo "$raw_selection" | awk -F'\t' '{print $2}')
    
    case "$room_id" in
        "ROOM_INFO")
            _fac_neural_read "$target_key"
            local current_cat_no="$_VAL_CATNO"
            local current_cat_name="$_VAL_CATNAME"
            
            if echo "$raw_selection" | grep -q "$current_cat_name"; then
                _bot_say "action" "Edit Category Name:"
                echo -e "${F_GRAY}    Target: [$current_cat_no] $current_cat_name${F_RESET}"
                
                read -e -p "    › " -i "$current_cat_name" input_val
                
                if [ -n "$input_val" ] && [ "$input_val" != "$current_cat_name" ]; then
                    _fac_update_category_name "$current_cat_no" "$input_val"
                    return 2 
                fi
            else
                # 點擊第二行 (ID/Type)，不做動作
                _bot_say "info" "Node ID: $current_cat_no:$_VAL_COMNO"
            fi
            ;;
        "ROOM_CMD")
            local edit_com=$(echo "$target_key" | awk '{print $1}')
            local edit_sub=""
            if [[ "$target_key" == *"'"* ]]; then
                edit_com=$(echo "$target_key" | awk -F"'" '{print $1}' | sed 's/[ \t]*$//')
                edit_sub=$(echo "$target_key" | awk -F"'" '{print $2}')
            fi
            
            local guide_txt="Modify CLI Identity (No spaces allowed)"

            while true; do
                local full_preview="${edit_com}"
                if [ -n "$edit_sub" ]; then full_preview="${edit_com} '${edit_sub}'"; fi

                local menu_list=$(
                    echo -e " COMMAND \t$edit_com"
                    if [ -z "$edit_sub" ]; then
                        echo -e " SUBCMD  \t\033[1;30m[Empty]\033[0m"
                    else
                        echo -e " SUBCMD  \t$edit_sub"
                    fi
                    echo -e "\033[1;30m----------\033[0m"
                    echo -e "\033[1;32m[Confirm]\033[0m"
                )

                local choice=$(echo -e "$menu_list" | fzf --ansi \
                    --height=8 \
                    --layout=reverse \
                    --border-label=" :: $header_text :: " \
                    --border=bottom \
                    --header-first \
                    --header=" :: Identity: [$full_preview] ::" \
                    --prompt=" :: Modify › " \
                    --info=hidden \
                    --pointer="››" \
                    --delimiter="\t" \
                    --with-nth=1,2 \
                    --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                    --color=info:240,prompt:$prompt_color,pointer:red,marker:208,border:$border_color,header:240 \
                    --bind="resize:clear-screen"
                )

                if [ -z "$choice" ]; then return 0; fi 
             
                if echo "$choice" | grep -q "COMMAND"; then
                    _bot_say "action" "Edit Command Name (Main):"
                    read -e -p "    › " -i "$edit_com" input_val
                    input_val="${input_val// /}"
                    if [ -z "$input_val" ]; then
                        _bot_say "warn" "Command name cannot be empty."
                    else
                        edit_com="$input_val"
                    fi

                elif echo "$choice" | grep -q "SUBCMD"; then
                    _bot_say "action" "Edit Sub-Command (Empty to clear):"
                    read -e -p "    › " -i "$edit_sub" input_val
                    edit_sub=$(echo "$input_val" | sed 's/^[ \t]*//;s/[ \t]*$//')

                elif echo "$choice" | grep -q "Confirm"; then
                    if [ -z "$edit_com" ]; then
                        _bot_say "error" "Invalid Identity: Command missing."
                        continue
                    fi

                    local step1_key=$(_fac_update_node "$target_key" 5 "$edit_com" 2>&1 >/dev/null)
                    local current_key="${step1_key:-$target_key}"
                    
                    local final_key=$(_fac_update_node "$current_key" 6 "$edit_sub" 2>&1 >/dev/null)
                    final_key="${final_key:-$current_key}"

                    _bot_say "success" "Command Identity Updated."
                    echo "UPDATE_KEY:$final_key"
                    return 2
                fi
            done
            ;;
        "ROOM_HUD")
            _fac_generic_edit "$target_key" 8 "Edit Description (HUD Name):"
            ;;
        "ROOM_UI")
            _fac_generic_edit "$target_key" 9 "Edit Display Name (Bot Label):"
            ;;
        "ROOM_PKG")
            _fac_generic_edit "$target_key" 10 "Edit Package Name (com.xxx.xxx):"
            ;;
        "ROOM_ACT")
            _fac_generic_edit "$target_key" 11 "Edit Activity / Class Path:"
            ;;
        "ROOM_FLAG")
            _fac_generic_edit "$target_key" 17 "Edit Execution Flags:"
            ;;
        "ROOM_INTENT")
            _fac_generic_edit "$target_key" 12 "Edit Intent Action (Head):"
            _fac_generic_edit "$target_key" 13 "Edit Intent Data (Body):"
            ;;
        "ROOM_URI")
            _fac_neural_read "$target_key"
            
            local edit_uri="$_VAL_URI"
            local edit_engine="$_VAL_ENGINE"
            
            local engine_list="[Empty]\n\$SEARCH_GOOGLE\n\$SEARCH_BING\n\$SEARCH_DUCK\n\$SEARCH_YT\n\$SEARCH_GITHUB"

            while true; do
                local uri_display="$edit_uri"
                local eng_display="${edit_engine:-[Empty]}"
                
                if [ -n "$edit_engine" ] && [ "$edit_engine" != "[Empty]" ]; then
                    uri_display="\033[1;30m\$__GO_TARGET (Auto-Linked)\033[0m"
                    eng_display="\033[1;36m$edit_engine\033[0m"
                else
                    if [ -z "$edit_uri" ]; then uri_display="\033[1;30m[Empty]\033[0m"; fi
                    eng_display="\033[1;30m[Empty]\033[0m"
                fi
                
                local menu_list=$(
                    echo -e " URI     \t$uri_display"
                    echo -e " ENGINE  \t$eng_display"
                    echo -e "\033[1;30m----------\033[0m"
                    echo -e "\033[1;32m[Confirm]\033[0m"
                )

                local choice=$(echo -e "$menu_list" | fzf --ansi \
                    --height=8 \
                    --layout=reverse \
                    --border-label=" :: URI & ENGINE LINK :: " \
                    --border=bottom \
                    --header-first \
                    --header=" :: Static URI overrides Engine ::" \
                    --prompt=" :: Setting › " \
                    --info=hidden \
                    --pointer="››" \
                    --delimiter="\t" \
                    --with-nth=1,2 \
                    --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                    --color=info:240,prompt:$prompt_color,pointer:red,marker:208,border:$border_color,header:240
                )

                if [ -z "$choice" ]; then return 0; fi

                if echo "$choice" | grep -q "URI"; then
                    _bot_say "action" "Enter Static URI (e.g., https://...):"
                    read -e -p "    › " -i "$edit_uri" input_val
                    
                    if [ -n "$input_val" ]; then
                        edit_uri="$input_val"
                        if [ "$input_val" != "\$__GO_TARGET" ]; then
                            if [ -n "$edit_engine" ]; then
                                edit_engine=""
                                _bot_say "warn" "Engine unlinked due to static URI override."
                            fi
                        fi
                    else
                         edit_uri=""
                    fi

                elif echo "$choice" | grep -q "ENGINE"; then
                    local sel_eng=$(echo -e "$engine_list" | fzf --height=8 --layout=reverse --header=":: Select Search Engine ::")
                    
                    if [ -n "$sel_eng" ]; then
                        if [ "$sel_eng" == "[Empty]" ]; then
                            edit_engine=""
                            _bot_say "action" "Engine cleared."
                        else
                            edit_engine="$sel_eng"
                            edit_uri="\$__GO_TARGET"
                            _bot_say "success" "Engine Linked. URI locked to \$__GO_TARGET."
                        fi
                    fi

                elif echo "$choice" | grep -q "Confirm"; then
                    _fac_neural_write "$target_key" 14 "$edit_uri"
                    _fac_neural_write "$target_key" 20 "$edit_engine"
                    
                    _bot_say "success" "URI/Engine Configuration Saved."
                    return 2
                fi
            done
            ;;
        "ROOM_LOOKUP")
            _bot_say "action" "Launching Reference Tool..."
            apklist
            echo -e ""
            echo -e "${F_GRAY}    (Press Enter to return to Factory)${F_RESET}"
            read
            ;;
        "ROOM_CONFIRM")
            _fac_neural_read "$target_key"
            if [ -z "$_VAL_COM" ] || [ "$_VAL_COM" == "[Empty]" ]; then
                _bot_say "error" "Command Name is required!"
                return 0
            else
                _bot_say "success" "Node Validated."
                return 1
            fi
            ;;
        *)
            # 點到無效區域如分隔線，不做事
            ;;
    esac
    return 0
}

# 初始化視覺效果 (Initialize Visuals)
function _fac_init() {
    _system_lock
    _safe_ui_calc
    clear
    _draw_logo "factory"
    _system_check "factory"
    _show_hud "factory"
    sed -i '/_DRAFT/d' "$MUX_ROOT/app.csv.temp"
    _system_unlock
}

# 函式攔截器 (Function Interceptor)
function _factory_mask_apps() {
    local input_com="$1"
    local input_sub="$2"
    
    if [[ "$input_com" == "wb" || "$input_com" == "apklist" ]]; then
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
                    if (c == q_com && s == "" && q_sub == "") {
                        print "LOCKED"
                        exit
                    }
                }
            ' "$csv_file")

            if [ "$is_masked" == "LOCKED" ]; then
                if [ -n "$input_sub" ]; then
                    _bot_say "error" "Factory Lock: '$input_com $input_sub' is restricted."
                else
                    _bot_say "error" "Factory Lock: '$input_com' is restricted."
                fi
                return 1
            fi
        fi
    done

    return 0
}
