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
    local target_state="${__FAC_IO_STATE:-ANY}" 

    local t_com=$(echo "$target_key" | awk '{print $1}')
    local t_sub=""
    
    if [[ "$target_key" == *"'"* ]]; then
        t_com=$(echo "$target_key" | awk -F"'" '{print $1}' | sed 's/[ \t]*$//')
        t_sub=$(echo "$target_key" | awk -F"'" '{print $2}')
    fi

    local raw_data=$(awk -v FPAT='([^,]*)|("[^"]+")' \
                         -v key="$t_com" \
                         -v subkey="$t_sub" \
                         -v tstate="$target_state" '
        !/^#/ { 
            row_com = $5; gsub(/^"|"$/, "", row_com); gsub(/\r| /, "", row_com)
            row_com2 = $6; gsub(/^"|"$/, "", row_com2); gsub(/\r| /, "", row_com2)
            row_state = $7; gsub(/^"|"$/, "", row_state); gsub(/\r| /, "", row_state)
            
            clean_key = key; gsub(/ /, "", clean_key)
            clean_sub = subkey; gsub(/ /, "", clean_sub)

            state_match = 0
            if (tstate == "ANY") {
                if (row_state != "E") state_match = 1
            } else {
                if (row_state == tstate) state_match = 1
            }

            if (state_match) {
                if (row_com == clean_key) {
                    if (clean_sub == "" && row_com2 == "") {
                         print $0; exit
                    }
                    if (clean_sub != "" && row_com2 == clean_sub) {
                         print $0; exit
                    }
                }
            }
        }
    ' "$target_file")

    if [ -z "$raw_data" ]; then return 1; fi

    eval $(echo "$raw_data" | awk -v FPAT='([^,]*)|("[^"]+")' '{
        fields[1]="_VAL_CATNO"; fields[2]="_VAL_COMNO"; fields[3]="_VAL_CATNAME"
        fields[4]="_VAL_TYPE";  fields[5]="_VAL_COM";   fields[6]="_VAL_COM2"
        fields[7]="_VAL_COM3";  fields[8]="_VAL_HUDNAME"; fields[9]="_VAL_UINAME"
        fields[10]="_VAL_PKG";  fields[11]="_VAL_TARGET"; fields[12]="_VAL_IHEAD"
        fields[13]="_VAL_IBODY"; fields[14]="_VAL_URI";   fields[15]="_VAL_MIME"
        fields[16]="_VAL_CATE"; fields[17]="_VAL_FLAG";   fields[18]="_VAL_EX"
        fields[19]="_VAL_EXTRA"; fields[20]="_VAL_ENGINE"

        for (i=1; i<=20; i++) {
            val = $i
            if (val ~ /^".*"$/) { val = substr(val, 2, length(val)-2) }
            gsub(/""/, "\"", val); gsub(/'\''/, "'\''\\'\'''\''", val)
            printf "%s='\''%s'\''; ", fields[i], val
        }
    }')
    
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
    local target_state="${__FAC_IO_STATE:-ANY}"

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
        -v col="$col_idx" -v val="$safe_val" \
        -v tstate="$target_state" '
    {
        c=$5; gsub(/^"|"$/, "", c); gsub(/\r| /, "", c)
        s=$6; gsub(/^"|"$/, "", s); gsub(/\r| /, "", s)
        st=$7; gsub(/^"|"$/, "", st); gsub(/\r| /, "", st)

        # Key 正規化
        clean_key = tc; gsub(/ /, "", clean_key)
        clean_sub = ts; gsub(/ /, "", clean_sub)

        match_found = 0
        state_pass = 0
        
        if (tstate == "ANY") { 
            if (st != "E") state_pass = 1 
        } else {
            if (st == tstate) state_pass = 1
        }

        if (state_pass) {
            if (c == clean_key) {
                if (clean_sub == "" && s == "") match_found = 1
                if (clean_sub != "" && s == clean_sub) match_found = 1
            }
        }

        if (match_found) {
            $col = val
        }
        print $0
    }' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
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

    # 清除狀態 N 的指令
    awk -F, -v OFS=, '
        BEGIN { cn=0; cs=0; fail=0 }
        NR==1 { print; next }
        
        {
            st=$7; gsub(/^"|"$/, "", st); gsub(/\r| /, "", st)
            
            if (st == "E") { print "QA_FAIL:Active Draft (E)" > "/dev/stderr"; print $0; next }
            if (st == "B") { print "QA_FAIL:Stuck Backup (B)" > "/dev/stderr"; print $0; next }
            if (st == "C") { print "QA_FAIL:Glitch Node (C)" > "/dev/stderr"; print $0; next }
            if (st == "F") { print "QA_FAIL:Broken Node (F)" > "/dev/stderr"; print $0; next }

            if (st == "S") {
                cs++
                $7 = "\"\"" 
            }
            
            if (st == "N") {
                cn++
                $7 = "\"\""
            }

            print $0
        }
    ' "$MUX_ROOT/app.csv.temp" > "$MUX_ROOT/app.csv.temp.tmp" && mv "$MUX_ROOT/app.csv.temp.tmp" "$MUX_ROOT/app.csv.temp"

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
            local view_state="NEW"

            # 1. 呼叫類型選單
            local type_sel=$(_factory_fzf_add_type_menu)
            
            if [[ -z "$type_sel" || "$type_sel" == "Cancel" || "$type_sel" == *"------"* ]]; then
                return
            fi

            # 2. 自動備份 (保留你的邏輯)
            if command -v _factory_auto_backup &> /dev/null; then
                _fac_maintenance
                _factory_auto_backup
            fi

            # 3. 計算 999 分類下的最大編號
            local next_comno=$(awk -F, '$1==999 {gsub(/^"|"$/, "", $2); if(($2+0) > max) max=$2} END {print max+1}' "$MUX_ROOT/app.csv.temp")
            
            if [ -z "$next_comno" ] || [ "$next_comno" -eq 1 ]; then next_comno=1; fi
            if ! [[ "$next_comno" =~ ^[0-9]+$ ]]; then next_comno=999; fi

            # 4. 生成臨時節點名稱 (ND + Timestamp)
            local ts=$(date +%s)
            local temp_cmd_name="ND${ts}"

            local target_cat="999"
            local target_catname="\"Others\""
            local com3_flag="N"
            local new_row=""
            
            # 5. 根據類型建構
            case "$type_sel" in
                "Command NA")
                    # NA 模板: 預設 Type=NA, COM=TempName
                    new_row="${target_cat},${next_comno},${target_catname},\"NA\",\"${temp_cmd_name}\",,\"${com3_flag}\",\"${temp_cmd_name}\",\"${temp_cmd_name}\",,,,,,,,,,,"
                    ;;
                "Command NB")
                    # NB 模板: 預設 Type=NB, IHEAD=android.intent.action, IBODY=.VIEW, ENGINE=$SEARCH_GOOGLE
                    new_row="${target_cat},${next_comno},${target_catname},\"NB\",\"${temp_cmd_name}\",,\"${com3_flag}\",\"${temp_cmd_name}\",\"${temp_cmd_name}\",,,\"android.intent.action\",\".VIEW\",\"$(echo '$__GO_TARGET')\",,,,,,\"$(echo '$SEARCH_GOOGLE')\""
                    ;;
                *) 
                    return ;;
            esac

            # 6. 寫入與啟動編輯協議
            if [ -n "$new_row" ]; then
                # 確保換行 (防止資料黏連)
                if [ -s "$MUX_ROOT/app.csv.temp" ] && [ "$(tail -c 1 "$MUX_ROOT/app.csv.temp")" != "" ]; then
                    echo "" >> "$MUX_ROOT/app.csv.temp"
                fi
                echo "$new_row" >> "$MUX_ROOT/app.csv.temp"
                
                _bot_say "action" "Initializing Construction Sequence..."
                
                # 進入編輯模式
                _fac_safe_edit_protocol "${temp_cmd_name}"
                
                # 7. 清理邏輯
                # 如果出來後還能讀到 NDxxx，代表使用者沒改名(放棄創建)，則刪除
                if ! _fac_neural_read "${temp_cmd_name}" >/dev/null 2>&1; then
                    : # 讀不到代表已經改名成功
                else
                    _bot_say "action" "Creation Aborted / Unnamed. Cleaning up..."
                    unset __FAC_IO_STATE 
                    _fac_delete_node "${temp_cmd_name}"
                fi
            fi
            ;;

        # : Edit Neural (Edit Command)
        "edit"|"comedit"|"comm")
            local view_state="EDIT"
            local target_arg="$2"

            if [ -n "$target_arg" ]; then
                _fac_safe_edit_protocol "$target_arg"
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
                
                # [關鍵修正 1] 狀態檢查：禁止刪除正在編輯(E)或備份(B)的節點
                local current_st=$(echo "$_VAL_COM3" | tr -d ' "')
                if [[ "$current_st" == "B" || "$current_st" == "E" ]]; then
                    echo ""
                    _bot_say "error" "Operation Denied: Target is locked by active session (State: $current_st)."
                    sleep 1
                    continue
                fi

                echo -e ""
                echo -e "${F_WARN} :: WARNING :: NEUTRALIZING TARGET NODE ::${F_RESET}"
                echo -e "${F_WARN}    Target Identifier : [${clean_target}]${F_RESET}"
                echo -e "${F_GRAY}    Package Binding   : ${del_pkg}${F_RESET}"
                echo -e "${F_GRAY}    Description       : ${del_desc}${F_RESET}"
                echo -e ""
                echo -ne "${F_ERR}    ›› CONFIRM DESTRUCTION [Y/n]: ${F_RESET}"
                
                read -n 1 -r conf
                echo -e "" 
                
                if [[ "$conf" =~ ^[Yy]$ ]]; then
                    _bot_say "action" "Executing Deletion..."

                    unset __FAC_IO_STATE
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
                        
                        local current_st=$(echo "$_VAL_COM3" | tr -d ' "')
                        if [[ "$current_st" == "B" || "$current_st" == "E" ]]; then
                            echo ""
                            _bot_say "error" "Operation Denied: Target is locked by active session."
                            sleep 1
                            continue
                        fi

                        echo -e "\033[1;31m :: WARNING :: NEUTRALIZING TARGET NODE ::\033[0m"
                        echo -e "\033[1;31m    Deleting Node [$clean_target] ($del_pkg)\033[0m"
                        echo -ne "\033[1;33m    ›› Confirm destruction? [Y/n]: \033[0m"
                        read -r choice
                        
                        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                            if command -v _factory_auto_backup &> /dev/null; then _factory_auto_backup; fi
                            
                            unset __FAC_IO_STATE
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
            local target_node="$2"
            local user_params="${*:3}" 

            if [ -z "$target_node" ]; then
                target_node=$(_factory_fzf_menu "Select Payload to Test")
                
                if [ -n "$target_node" ]; then
                    local display_name=$(echo "$target_node" | awk '{print $1}') 
                    
                    local prompt_text=$'\033[1;33m :: '$display_name$' \033[1;30m(Params?): \033[0m'
                    read -e -p "$prompt_text" user_params < /dev/tty
                fi
            fi

            if [ -n "$target_node" ]; then
                _fac_launch_test "$target_node" "$user_params"
                
                echo -ne "\033[1;30m    (Press 'Enter' to return...)\033[0m"
                read
            fi
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
            _fac_maintenance
            if grep -q ',"E",' "$MUX_ROOT/app.csv.temp"; then
                echo -e "\n\033[1;31m :: DEPLOY ABORTED :: Active Drafts (E) Detected.\033[0m"
                echo -e "\033[1;30m    Please finish editing or delete drafts before deployment.\033[0m"
                echo -ne "\n\033[1;33m    ›› Acknowledge and Return? [Y/n]: \033[0m"
                read -n 1 -r
                echo ""
                return
            fi
            _fac_sort_optimization
            _fac_matrix_defrag
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
    sleep 0.5

    # Phase 0: 最終品管與統計 (Final QA & Stats & Migration)
    echo -e "\n${F_GRAY} :: Running Final Quality Assurance (QA)...${F_RESET}"
    
    local target_file="$MUX_ROOT/app.csv.temp"
    local qa_file="${target_file}.qa"
    local stats_log="${target_file}.log"

    awk -F, -v OFS=, '
        BEGIN { cn=0; cs=0; fail=0 }
        NR==1 { print; next }
        
        {
            st=$7; gsub(/^"|"$/, "", st); gsub(/\r| /, "", st)
            
            # [CRITICAL] 攔截非法狀態
            if (st == "E") { print "QA_FAIL:Active Draft (E)" > "/dev/stderr"; print $0; next }
            if (st == "B") { print "QA_FAIL:Stuck Backup (B)" > "/dev/stderr"; print $0; next }
            if (st == "F") { print "QA_FAIL:Broken Node (F)" > "/dev/stderr"; print $0; next }
            if (st == "C") { print "QA_FAIL:Glitch Node (C)" > "/dev/stderr"; print $0; next }

            # [TRANSITION] 狀態轉正 (Graduation to P)
            
            # 1. S (Saved) -> P
            if (st == "S") {
                cs++
                $7 = "\"P\""
            }
            # 2. N (New) -> P
            else if (st == "N") {
                cn++
                $7 = "\"P\""
            }
            # 3. Empty (Old) -> P (自動遷移)
            else if (st == "") {
                $7 = "\"P\""
            }

            print $0
        }
        END { print "STATS:" cn ":" cs > "/dev/stderr" }
    ' "$target_file" > "$qa_file" 2> "$stats_log"

    # 解析 QA 結果
    local qa_error=$(grep "QA_FAIL" "$stats_log")
    local stats_line=$(grep "STATS" "$stats_log")
    local cnt_n=$(echo "$stats_line" | cut -d: -f2)
    local cnt_s=$(echo "$stats_line" | cut -d: -f3)

    # 錯誤處理
    if [ -n "$qa_error" ]; then
        mv "$qa_file" "$target_file" # 寫回標記以便使用者檢查
        rm "$stats_log"
        echo -e "${F_ERR} :: QA FAILED. Invalid nodes detected.${F_RESET}"
        echo -e "${F_GRAY}    Reason: $(echo "$qa_error" | cut -d: -f2 | head -n 1)${F_RESET}"
        return 1
    else
        # QA 通過：應用轉正後的檔案 (P State applied)
        mv "$qa_file" "$target_file"
        rm "$stats_log"
        echo -e "${F_GRE}    ›› QA Passed. State normalized to [P].${F_RESET}"
    fi

    #戰報顯示
    echo -e "${F_MAIN} :: SANDBOX SESSION REPORT ::${F_RESET}"
    echo -e "    ${F_GRAY}Created (New)   :${F_RESET} \033[1;32m${cnt_n:-0}\033[0m"
    echo -e "    ${F_GRAY}Modified (Saved):${F_RESET} \033[1;33m${cnt_s:-0}\033[0m"
    echo ""
    
    echo -ne "${F_WARN} :: Press 'Enter' to Review Changes...${F_RESET}"
    read

    # Phase 1: 差異比對與確認 (Diff & Confirm)
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
    echo -e "${F_SUB}    Sandbox will OVERWRITE Production.${F_RESET}"
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

    # Phase 2: 執行部署 (Execution)
    sleep 1.0
    
    local temp_file="$MUX_ROOT/app.csv.temp"
    local prod_file="$MUX_ROOT/app.csv"

    if [ -f "$temp_file" ]; then
        mv "$temp_file" "$prod_file"
        
        if [ -f "$prod_file" ]; then
            cp "$prod_file" "$temp_file"
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
            # 讀取欄位
            catname=$3;   gsub(/^"|"$/, "", catname)
            type=$4;      gsub(/^"|"$/, "", type)
            st=$7;        gsub(/^"|"$/, "", st); gsub(/\r| /, "", st) # COM3 State
            pkg=$10;      gsub(/^"|"$/, "", pkg)
            tgt=$11;      gsub(/^"|"$/, "", tgt)
            ihead=$12;    gsub(/^"|"$/, "", ihead)
            ibody=$13;    gsub(/^"|"$/, "", ibody)
            uri=$14;      gsub(/^"|"$/, "", uri)

            if (st == "E" || st == "B" || st == "C") {
                print $0
                next
            }
            
            valid = 0
            
            # 驗證規則
            if (type == "NA") {
                if (pkg != "" && tgt != "") valid = 1
            }
            else if (type == "NB") {
                if ((ihead != "" && ibody != "") || pkg != "" || uri != "") valid = 1
            }
            else if (type == "SYS" || type == "SSL" || type == "sh") {
                valid = 1
            }
            if (type == "") valid = 0
            
            if (valid == 0) {
                # 結構損壞 / 外部篡改，轉 F
                $7 = "\"F\""
            } 
            else {
                # 結構完整，將指令改爲 P
                $7 = "\"P\""
            }
            
            print $0
        }
    ' "$target_file" > "$temp_file"

    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$target_file"
        echo -e "${F_GRE}    ›› Neural Nodes Verified (Zero Trust Scan Completed).${F_RESET}"
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
    local target_key="$1"
    local target_file="$MUX_ROOT/app.csv.temp"

    # 1. 鎖定目標與狀態識別
    unset __FAC_IO_STATE
    if ! _fac_neural_read "$target_key"; then
        _bot_say "error" "Target Node Not Found."
        return 1
    fi

    local current_state="$_VAL_COM3"
    # 若是舊資料空字串，視為 P
    if [ -z "$current_state" ]; then current_state="P"; fi 

    local working_key="$target_key"
    local origin_type="$current_state"

    # 2. 啟動交易 (Transaction Start)
    if [ "$current_state" == "E" ]; then
        _bot_say "warn" "Resuming Edit Session (State: E)..."
    else
        # 建立 B/E 交易對
        _bot_say "action" "Initializing Transaction..."

        # [Action] 將本尊轉為 B (Backup)
        # 這裡鎖定本尊，不管它是 P, N, S, F，都暫時轉為 B 隱藏起來
        _fac_neural_write "$target_key" 7 "B"

        # [Action] 複製產生 E (Clone -> Edit)
        # 這裡實現了 C 的邏輯：複製一份，並直接標記為 E
        local draft_row="$_VAL_CATNO,$_VAL_COMNO,\"$_VAL_CATNAME\",\"$_VAL_TYPE\",\"$_VAL_COM\",\"$_VAL_COM2\",\"E\",\"$_VAL_HUDNAME\",\"$_VAL_UINAME\",\"$_VAL_PKG\",\"$_VAL_TARGET\",\"$_VAL_IHEAD\",\"$_VAL_IBODY\",\"$_VAL_URI\",\"$_VAL_MIME\",\"$_VAL_CATE\",\"$_VAL_FLAG\",\"$_VAL_EX\",\"$_VAL_EXTRA\",\"$_VAL_ENGINE\""
        echo "$draft_row" >> "$target_file"
        
        # 記錄原始 Key 以便刪除 B
        export __FAC_ORIGIN_KEY="$target_key"
        # 記錄原始狀態以便 Rollback (如果是 N 轉 B，還原時要變回 N)
        export __FAC_RESTORE_TYPE="$origin_type"
    fi

    # 3. 進入編輯迴圈 (鎖定 E)
    export __FAC_IO_STATE="E"
    local loop_status="EDIT"

    while true; do
        # working_key 會隨著編輯改變 (Key Drift)
        local selection=$(_factory_fzf_detail_view "$working_key" "NEW") # 使用綠色樣式提示編輯中
        
        if [ -z "$selection" ]; then
            loop_status="CANCEL"
            break
        fi

        local router_out
        router_out=$(_fac_edit_router "$selection" "$working_key" "NEW")
        local router_code=$?
        
        if [ $router_code -eq 1 ]; then
            loop_status="CONFIRM"
            break
        elif [ $router_code -eq 2 ]; then
            # [Key Drift Fix] 捕捉改名後的 Key
            local new_k=$(echo "$router_out" | awk -F: '{print $2}')
            if [ -n "$new_k" ]; then working_key="$new_k"; fi
        fi
    done

    # 4. 結算階段 (Settlement)
    unset __FAC_IO_STATE # 解鎖

    if [ "$loop_status" == "CONFIRM" ]; then
        _bot_say "neural" "Committing Transaction..."
        
        # A. 刪除 B (Backup)
        # 必須刪除原本那個 Key 對應的 B
        export __FAC_IO_STATE="B"
        _fac_delete_node "$__FAC_ORIGIN_KEY"
        unset __FAC_IO_STATE

        # B. 焦土戰略 (Scorched Earth)
        # 如果改了名 (working_key != origin)，新名字可能跟現有的 P/S/N 衝突
        # 我們必須檢查並刪除那個「擋路者」
        if [ "$working_key" != "$__FAC_ORIGIN_KEY" ]; then
             # 不鎖狀態，預設刪除 P, N, S, F (除了 E 以外的所有人)
             _fac_delete_node "$working_key"
        fi

        # C. 將 E 轉正為 S (Saved)
        export __FAC_IO_STATE="E"
        _fac_neural_write "$working_key" 7 "S"
        unset __FAC_IO_STATE
        
        _fac_sort_optimization
        _fac_matrix_defrag
        _bot_say "success" "Changes Saved (State: S)."

    else
        # Rollback (Cancel)
        _bot_say "action" "Rolling back..."
        
        # A. 刪除 E (Draft)
        export __FAC_IO_STATE="E"
        _fac_delete_node "$working_key"
        unset __FAC_IO_STATE
        
        # B. 還原 B -> P/N/S/F
        export __FAC_IO_STATE="B"
        local restore_val="$__FAC_RESTORE_TYPE"
        # 如果原本是 P，就還原為 P
        if [ -z "$restore_val" ]; then restore_val="P"; fi
        
        _fac_neural_write "$__FAC_ORIGIN_KEY" 7 "$restore_val"
        unset __FAC_IO_STATE
        
        _bot_say "action" "State Restored."
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
    
    # 讀取全域權限鎖 (由 _fac_safe_edit_protocol 設定)
    # 如果為空，代表是使用者手動操作 -> 開啟保護模式
    # 如果有值 (e.g. "B", "E")，代表是系統操作 -> 精準獵殺模式
    local auth_state="${__FAC_IO_STATE:-User}" 

    local t_com=$(echo "$target_key" | awk '{print $1}')
    local t_sub=""
    if [[ "$target_key" == *"'"* ]]; then
        t_sub=$(echo "$target_key" | awk -F"'" '{print $2}')
    fi

    awk -F, -v OFS=, \
        -v tc="$t_com" -v ts="$t_sub" \
        -v mode="$auth_state" '
    {
        # 欄位正規化
        c=$5; gsub(/^"|"$/, "", c); gsub(/\r| /, "", c)
        s=$6; gsub(/^"|"$/, "", s); gsub(/\r| /, "", s)
        st=$7; gsub(/^"|"$/, "", st); gsub(/\r| /, "", st)
        
        # 1. 比對目標 Key (COM + COM2)
        match_found = 0
        if (c == tc) {
            if (ts == "" && s == "") match_found = 1
            if (ts != "" && s == ts) match_found = 1
        }

        # 2. 刪除決策邏輯
        if (match_found) {
            if (mode == "User") {
                # [User Mode] 保護機制
                # 絕對禁止刪除 B (備份), E (編輯中), C (複製中)
                if (st == "B" || st == "E" || st == "C") {
                    # 這是受保護的節點，保留它 (Print)
                    print $0
                } else {
                    # 允許刪除 P, N, S, F (Skip print = Delete)
                }
            } else {
                # [System Mode] 精準獵殺
                # 只刪除指定的狀態 (例如 Commit 時只刪 B)
                if (st == mode) {
                    # 狀態吻合，執行刪除 (Skip print)
                } else {
                    # 狀態不符，保留 (Print)
                    print $0
                }
            }
        } else {
            # 非目標節點，原樣保留
            print $0
        }
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
            guide_text="Specify UI rendering mode."_fac_room_guide
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
            # 1. 獲取輸入 (修正：使用原生 read)
            _bot_say "action" "Edit Cli Command:"
            read -e -p "    › " -i "$_VAL_COM" new_com
            
            _bot_say "action" "Edit Sub Command:"
            read -e -p "    › " -i "$_VAL_COM2" new_sub
            
            if [ -z "$new_com" ]; then return 0; fi

            local current_track_key="$target_key"
            local key_changed=0

            if [ "$new_com" != "$_VAL_COM" ]; then
                _fac_neural_write "$current_track_key" 5 "$new_com"
                
                if [ -n "$_VAL_COM2" ]; then
                    current_track_key="$new_com '$_VAL_COM2'"
                else
                    current_track_key="$new_com"
                fi
                key_changed=1
            fi

            if [ "$new_sub" != "$_VAL_COM2" ]; then
                _fac_neural_write "$current_track_key" 6 "$new_sub"
                
                local final_com="${new_com:-$_VAL_COM}"
                
                if [ -n "$new_sub" ]; then
                    current_track_key="$final_com '$new_sub'"
                else
                    current_track_key="$final_com"
                fi
                key_changed=1
            fi

            if [ "$key_changed" -eq 1 ]; then
                _bot_say "action" "Identity Updated. Tracking new key..."
                echo "UPDATE_KEY:$current_track_key"
                return 2
            else
                return 0
            fi
            ;;
        "ROOM_HUD")
            _fac_generic_edit "$target_key" 8 "Edit Description (HUD Name):"
            ;;
        "ROOM_CATE")
            _fac_generic_edit "$target_key" 16 "Edit Category Type:"
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
            echo -e "${F_GRAY}    (Press 'Enter' to return to Factory)${F_RESET}"
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
    awk -F, -v OFS=, '
    {
        st=$7; gsub(/^"|"$/, "", st); gsub(/\r| /, "", st)
        if (st == "C" || st == "E") next
        if (st == "B") {
            $7 = "\"P\""
        }
        print $0
    }
    ' "$MUX_ROOT/app.csv.temp" > "$MUX_ROOT/app.csv.temp.tmp" && mv "$MUX_ROOT/app.csv.temp.tmp" "$MUX_ROOT/app.csv.temp"
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

# 兵工廠測試發射台 - Factory Fire Control Test
function _fac_launch_test() {
    local input_key="$1"
    local input_args="${*:2}"

    # 讀取資料
    if ! _fac_neural_read "$input_key"; then
        _bot_say "error" "Node not found in Sandbox."
        return 1
    fi

    # 定義顏色
    local C_TYPE="\033[1;33m"
    local C_LBL="\033[1;30m"
    local C_VAL="\033[1;37m"
    local C_SEP="\033[1;30m"
    local C_RST="\033[0m"

    echo ""
    printf "${C_TYPE}[TYPE: %-3s]${C_RST}\n" "$_VAL_TYPE"
    
    echo -e "${C_LBL}Command:${C_RST} ${C_VAL}$_VAL_COM $_VAL_COM2${C_RST}"
    echo -e "${C_LBL}UI     :${C_RST} ${C_VAL}$_VAL_UINAME${C_RST}"
    echo -e "${C_LBL}Detail :${C_RST} ${C_VAL}$_VAL_HUDNAME${C_RST}"
    echo -e "${C_SEP}---------------${C_RST}"

    # 依照類型顯示詳細資訊
    case "$_VAL_TYPE" in
        "NA")
            echo -e "${C_LBL}PKG    :${C_RST} ${C_VAL}$_VAL_PKG${C_RST}"
            [ -n "$_VAL_TARGET" ] && echo -e "${C_LBL}Target :${C_RST} ${C_VAL}$_VAL_TARGET${C_RST}"
            ;;
        "NB")
            local intent_str="${_VAL_IHEAD}${_VAL_IBODY}"
            echo -e "${C_LBL}Intent :${C_RST} ${C_VAL}${intent_str:-N/A}${C_RST}"
            
            # ENGINE 有值就列出 ENGINE，否則列出 URI
            if [ -n "$_VAL_ENGINE" ]; then
                echo -e "${C_LBL}ENGINE :${C_RST} ${C_VAL}$_VAL_ENGINE${C_RST}"
            else
                echo -e "${C_LBL}URI    :${C_RST} ${C_VAL}$_VAL_URI${C_RST}"
            fi
            ;;
        "SYS"|"sh")
            echo -e "${C_LBL}Script :${C_RST} ${C_VAL}$_VAL_PKG${C_RST}"
            ;;
    esac

    # 動態旗標顯示 (有資料才顯示)
    [ -n "$_VAL_CATE" ] && echo -e "${C_LBL}Cate   :${C_RST} ${C_VAL}$_VAL_CATE${C_RST}"
    [ -n "$_VAL_MIME" ] && echo -e "${C_LBL}Mime   :${C_RST} ${C_VAL}$_VAL_MIME${C_RST}"
    [ -n "$_VAL_FLAG" ] && echo -e "${C_LBL}Flag   :${C_RST} ${C_VAL}$_VAL_FLAG${C_RST}"

    # EX 與 EXTRA 同排顯示
    local ex_str=""
    local extra_str=""
    [ -n "$_VAL_EX" ] && ex_str="${C_LBL}EX:${C_RST} ${C_VAL}$_VAL_EX${C_RST}  "
    [ -n "$_VAL_EXTRA" ] && extra_str="${C_LBL}EXTRA:${C_RST} ${C_VAL}$_VAL_EXTRA${C_RST}"
    
    if [ -n "$ex_str" ] || [ -n "$extra_str" ]; then
        echo -e "${ex_str}${extra_str}"
    fi
    echo ""

    # 模擬發射
    local final_cmd=""
    
    if [ "$_VAL_TYPE" == "NA" ] || [ "$_VAL_TYPE" == "NB" ]; then
        
        # 基礎指令
        final_cmd="am start --user 0"
        
        # Intent Action
        local final_action="${_VAL_IHEAD}${_VAL_IBODY}"
        [ -n "$final_action" ] && final_cmd="$final_cmd -a \"$final_action\""
        
        # Package / Target (-n 優先於 -p)
        if [ -n "$_VAL_PKG" ]; then
            if [ -n "$_VAL_TARGET" ]; then
                final_cmd="$final_cmd -n \"$_VAL_PKG/$_VAL_TARGET\""
            else
                final_cmd="$final_cmd -p \"$_VAL_PKG\""
            fi
        fi

        # URI 處理 (支援參數注入)
        local final_uri="$_VAL_URI"
        if [ -n "$input_args" ]; then
            final_uri="${final_uri//\$query/$input_args}"
        fi
        [ -n "$final_uri" ] && final_cmd="$final_cmd -d \"$final_uri\""

        # 旗標與參數
        [ -n "$_VAL_CATE" ]  && final_cmd="$final_cmd -c \"android.intent.category.$_VAL_CATE\""
        [ -n "$_VAL_MIME" ]  && final_cmd="$final_cmd -t \"$_VAL_MIME\""
        [ -n "$_VAL_FLAG" ]  && final_cmd="$final_cmd -f $_VAL_FLAG"
        [ -n "$_VAL_EX" ]    && final_cmd="$final_cmd $_VAL_EX"
        [ -n "$_VAL_EXTRA" ] && final_cmd="$final_cmd $_VAL_EXTRA"

    elif [ "$_VAL_TYPE" == "SYS" ] || [ "$_VAL_TYPE" == "sh" ]; then
        final_cmd="$_VAL_PKG $input_args"
    fi

    # 4. 點火與驗證
    echo -e "${F_WARN} :: SLOT TEST RELOAD ::${F_RESET}"
    echo -e "${F_GRAY}    FIRE › $final_cmd${F_RESET}"
    
    local output
    output=$(eval "$final_cmd" 2>&1)

    # 5. 結果驗證器
    if [[ "$output" == *"Error"* ]] || [[ "$output" == *"does not exist"* ]] || [[ "$output" == *"unable to resolve"* ]]; then
        echo -e "\n${F_ERR} :: TEST FAILED ::${F_RESET}"
        echo -e "${F_GRAY}---------------${F_RESET}"
        echo -e "\033[0;31m$output\033[0m"
        echo -e "${F_GRAY}---------------${F_RESET}"
        
        # 針對 Package Not Found 提供安裝建議
        if [ -n "$_VAL_PKG" ] && [[ "$output" == *"does not exist"* || "$output" == *"not found"* ]]; then
             echo -e "${F_WARN}    ›› Diagnosis: Package '$_VAL_PKG' is not installed on this device.${F_RESET}"
             echo -e "${F_GRAY}    ›› Action: Please verify package name or install manually.${F_RESET}"
        fi
        return 1
    else
        echo -e "\n${F_GRE} :: TEST SUCCESSFUL ::${F_RESET}"
        # 如果是 SYS，顯示輸出結果
        if [ "$_VAL_TYPE" == "SYS" ] || [ "$_VAL_TYPE" == "sh" ]; then
             echo -e "${F_GRAY}---------------${F_RESET}"
             echo -e "$output"
             echo -e "${F_GRAY}---------------${F_RESET}"
        fi
        return 0
    fi
}