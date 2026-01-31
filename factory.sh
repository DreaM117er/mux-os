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

    # 完整保留
    local t_com="$target_key"
    local t_sub=""
    
    # 處理 'SubCommand' 格式
    if [[ "$target_key" == *"'"* ]]; then
        t_com=$(echo "$target_key" | awk -F"'" '{print $1}' | sed 's/[ \t]*$//')
        t_sub=$(echo "$target_key" | awk -F"'" '{print $2}')
    fi

    # 安全處理反斜線資料格寫入
    local safe_val="${new_val//\\/\\\\}"

    # 處理寫入值的引號轉義，但絕對保留內部所有符號
    safe_val="${safe_val//\"/\"\"}"

    if [[ "$col_idx" == "1" || "$col_idx" == "2" ]]; then
        # 純數值，不動作
        :
    else
        # 文字包裹外層引號，忽略空值
        if [ -n "$safe_val" ]; then
            safe_val="\"$safe_val\""
        fi
    fi

    awk -v FPAT='([^,]*)|("[^"]+")' -v OFS="," \
        -v tc="$t_com" -v ts="$t_sub" \
        -v col="$col_idx" -v val="$safe_val" \
        -v tstate="$target_state" '
    {
        # 1. 去除最外層引號
        c=$5; gsub(/^"|"$/, "", c); gsub(/\r$/, "", c) 
        s=$6; gsub(/^"|"$/, "", s); gsub(/\r$/, "", s) 
        st=$7; gsub(/^"|"$/, "", st); gsub(/\r| /, "", st)

        # 2. 去除頭尾空白
        clean_key = tc; gsub(/^[ \t]+|[ \t]+$/, "", clean_key)
        clean_sub = ts; gsub(/^[ \t]+|[ \t]+$/, "", clean_sub)
        
        # 處理COM
        gsub(/^[ \t]+|[ \t]+$/, "", c)

        match_found = 0
        state_pass = 0
        
        # 3. 狀態過濾
        if (tstate == "ANY") { 
            # 非狀態 E 過濾
            if (st != "E") state_pass = 1 
        } else {
            # 狀態 E 處理
            if (st == tstate) state_pass = 1
        }

        # 4. 資料比對
        if (state_pass) {
            if (c == clean_key) {
                if (clean_sub == "" && s == "") match_found = 1
                if (clean_sub != "" && s == clean_sub) match_found = 1
            }
        }

        # 5. 寫入
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
        _bot_say "action" "Reversing time flow..."
        
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
        _bot_say "error" "Factory commands disabled during Core session."
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

            # 呼叫類型選單
            local type_sel=$(_factory_fzf_add_type_menu)
            
            if [[ -z "$type_sel" || "$type_sel" == "Cancel" || "$type_sel" == *"------"* ]]; then
                return
            fi

            # 自動備份
            if command -v _factory_auto_backup &> /dev/null; then
                _fac_maintenance
                _factory_auto_backup
            fi

            # 計算編號
            local next_comno=$(awk -F, '$1==999 {gsub(/^"|"$/, "", $2); if(($2+0) > max) max=$2} END {print max+1}' "$MUX_ROOT/app.csv.temp")
            if [ -z "$next_comno" ] || [ "$next_comno" -eq 1 ]; then next_comno=1; fi
            if ! [[ "$next_comno" =~ ^[0-9]+$ ]]; then next_comno=999; fi

            # 生成臨時指令
            local ts=$(date +%s)
            local temp_cmd_name="ND${ts}"

            local target_cat="999"
            local target_catname="\"Others\""
            local com3_flag="N"
            local new_row=""
            
            # 指令模板
            case "$type_sel" in
                "Command NA")
                    new_row="${target_cat},${next_comno},${target_catname},\"NA\",\"${temp_cmd_name}\",,\"${com3_flag}\",\"Unknown\",\"Unknown\",,,,,,,,,,,"
                    ;;
                "Command NB")
                    new_row="${target_cat},${next_comno},${target_catname},\"NB\",\"${temp_cmd_name}\",,\"${com3_flag}\",\"Unknown\",\"Unknown\",,,\"android.intent.action\",\".VIEW\",\"$(echo '$__GO_TARGET')\",,,,,,\"$(echo '$SEARCH_GOOGLE')\""
                    ;;
                *) 
                    return ;;
            esac

            # 寫入與啟動編輯協議
            if [ -n "$new_row" ]; then
                if [ -s "$MUX_ROOT/app.csv.temp" ] && [ "$(tail -c 1 "$MUX_ROOT/app.csv.temp")" != "" ]; then
                    echo "" >> "$MUX_ROOT/app.csv.temp"
                fi
                echo "$new_row" >> "$MUX_ROOT/app.csv.temp"
                
                _bot_say "action" "Initializing Construction Sequence..."
                
                # 啓動綠色選單
                _fac_safe_edit_protocol "${temp_cmd_name}" "NEW"
                
                # 清理暫存檔
                if _fac_neural_read "${temp_cmd_name}" >/dev/null 2>&1; then
                    local leftover_state=$(echo "$_VAL_COM3" | tr -d ' "')
                    
                    if [[ "$leftover_state" == "S" || "$leftover_state" == "P" ]]; then
                        # 保留 S 標記
                        _bot_say "success" "Node Created (Default Identity Kept)."
                    else
                        # 清除其他標記
                        _bot_say "error" "Incomplete Transaction. Cleaning up..."
                        unset __FAC_IO_STATE 
                        _fac_delete_node "${temp_cmd_name}"
                    fi
                else
                    # 讀不到資料，跳出
                    : 
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
                local raw_cat=$(_factory_fzf_cat_selector "EDIT")
                if [ -z "$raw_cat" ]; then break; fi
                
                local temp_id=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')

                # 重新讀取 ID
                local db_data=$(awk -F, -v tid="$temp_id" 'NR>1 {gsub(/^"|"$/, "", $1); if($1==tid){gsub(/^"|"$/, "", $3); print $1 "|" $3; exit}}' "$MUX_ROOT/app.csv.temp")
                local cat_id=$(echo "$db_data" | awk -F'|' '{print $1}')
                local cat_name=$(echo "$db_data" | awk -F'|' '{print $2}')
                if [ -z "$cat_id" ]; then cat_id="XX"; cat_name="Unknown"; fi

                while true; do
                    local action=$(_factory_fzf_catedit_submenu "$cat_id" "$cat_name" "EDIT")
                    if [ -z "$action" ]; then break; fi

                    # Branch 1: 修改名稱 (Rename)
                    if echo "$action" | grep -q "Edit Name" ; then
                        
                        # 鎖定 999 不可改名
                        if [ "$cat_id" == "999" ]; then
                            _bot_say "error" "System Reserved: [999] Others." >&2
                            echo -e "${F_GRAY}    ›› The Void is immutable. You cannot rename it.${F_RESET}" >&2
                            continue
                        fi

                        _bot_say "action" "Rename Category [$cat_name]:"
                        read -e -p "    › " -i "$cat_name" new_cat_name
                        
                        if [ -n "$new_cat_name" ] && [ "$new_cat_name" != "$cat_name" ]; then
                            _fac_update_category_name "$cat_id" "$new_cat_name"
                            cat_name="$new_cat_name" # 更新變數顯示
                        fi
                        
                    # Branch 2: 修改內部指令 (Edit Content) 
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
                
                # 狀態檢查：禁止刪除標記 B
                local current_st=$(echo "$_VAL_COM3" | tr -d ' "')
                if [ "$current_st" == "B" ]; then
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
                
                read -e -r conf
                echo -e "" 
                
                if [[ "$conf" == "y" || "$conf" == "Y" ]]; then
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

                # Branch 1: 解散分類 (Dissolve Category) 
                if [[ "$action" == *"Delete Category"* ]]; then
                    echo -e "\033[1;31m :: CRITICAL: Dissolving Category [$db_name] [$temp_id] \033[0m"
                    echo -e "\033[1;30m    All assets will be transferred to [Others] [999].\033[0m"
                    
                    # 禁止解散 999
                    if [ "$temp_id" == "999" ]; then
                         _bot_say "error" "Cannot dissolve the [Others] singularity."
                         continue
                    fi

                    echo -ne "\033[1;33m    ›› TYPE 'CONFIRM' TO DEPLOY: \033[0m"
                    read -r confirm
                    if [ "$confirm" == "CONFIRM" ]; then
                        if command -v _factory_auto_backup &> /dev/null; then _factory_auto_backup; fi
                        _bot_say "action" "Migrating assets to Void..."
                        _fac_safe_merge "999" "$temp_id"
                        
                        awk -F, -v tid="$temp_id" -v OFS=, '$1 != tid {print $0}' "$MUX_ROOT/app.csv.temp" > "$MUX_ROOT/app.csv.temp.tmp" && mv "$MUX_ROOT/app.csv.temp.tmp" "$MUX_ROOT/app.csv.temp"
                        
                        _bot_say "success" "Category Dissolved."

                        _fac_sort_optimization
                        _fac_matrix_defrag
                        break
                    else
                        echo -e "${F_GRAY}    ›› Operation Aborted.${F_RESET}"
                    fi

                # Branch 2: 肅清指令 (Neutralize Command) 
                elif [[ "$action" == *"Delete Command"* ]]; then
                    while true; do
                        local raw_cmd=$(_factory_fzf_cmd_in_cat "$db_name" "DEL")
                        if [ -z "$raw_cmd" ]; then break; fi
                        
                        local clean_target=$(echo "$raw_cmd" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                         
                        _fac_neural_read "$clean_target"
                        local del_pkg="${_VAL_PKG:-N/A}"
                        
                        # 狀態鎖定檢查
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
                        read -e -r choice
                        
                        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                            if command -v _factory_auto_backup &> /dev/null; then _factory_auto_backup; fi
                            
                            unset __FAC_IO_STATE
                            _fac_delete_node "$clean_target"
                            
                            _bot_say "success" "Target neutralized."

                            _fac_sort_optimization
                            _fac_matrix_defrag
                        else
                            echo -e "${F_GRAY}    ›› Operation Aborted.${F_RESET}"
                            sleep 0.5
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
            local input_1="$2"
            local input_2="$3"
            
            local target_node=""
            local user_params=""

            # Logic A: 無參數 -> 開啟 FZF (Visual Mode)
            if [ -z "$input_1" ]; then
                target_node=$(_factory_fzf_menu "Select Payload to Test")
                
                # 選中目標後，進入參數輸入
                if [ -n "$target_node" ]; then
                    read -e -p "$(echo -e "\033[1;33m :: $target_node \033[1;30m(Params?): \033[0m")" user_params < /dev/tty
                fi

            # Logic B: 有參數 -> 智慧判斷 (Bypass Mode)
            else
                if [ -n "$input_2" ] && _fac_check_composite_exists "$input_1" "$input_2"; then
                    # Case 1: 複合指令 (git status)
                    target_node="$input_1 '$input_2'"
                    user_params="${*:4}"
                    _bot_say "neural" "Identified Composite Node: [$target_node]"
                else
                    # Case 2: 單一指令 + 參數 (Command + Args)
                    target_node="$input_1"
                    user_params="${*:3}"
                fi
            fi

            # 發射程序
            if [ -n "$target_node" ]; then
                local clean_key=$(echo "$target_node" | sed "s/$(printf '\033')\[[0-9;]*m//g" | sed 's/^[ \t]*//;s/[ \t]*$//')

                _fac_launch_test "$clean_key" "$user_params"
                
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
    echo -ne "${F_WARN} :: Initiating Deployment Sequence...${F_RESET}"
    sleep 0.5

    # QA & Stats & Migration
    echo -e "\n${F_GRAY} :: Running Final Quality Assurance (QA)...${F_RESET}"
    
    local target_file="$MUX_ROOT/app.csv.temp"
    local qa_file="${target_file}.qa"
    local stats_log="${target_file}.log"

    awk -F, -v OFS=, '
        BEGIN { cn=0; cs=0; fail=0 }
        NR==1 { print; next }
        
        {
            st=$7; gsub(/^"|"$/, "", st); gsub(/\r| /, "", st)
            
            # 攔截非法狀態
            if (st == "E") { print "QA_FAIL:Active Draft (E)" > "/dev/stderr"; print $0; next }
            if (st == "B") { print "QA_FAIL:Stuck Backup (B)" > "/dev/stderr"; print $0; next }
            if (st == "F") { print "QA_FAIL:Broken Node (F)" > "/dev/stderr"; print $0; next }
            if (st == "C") { print "QA_FAIL:Glitch Node (C)" > "/dev/stderr"; print $0; next }
            
            # 狀態轉換
            # 1. S -> P
            if (st == "S") {
                cs++
                $7 = "\"P\""
            }
            # 2. N -> P
            else if (st == "N") {
                cn++
                $7 = "\"P\""
            }
            # 3. Empty (Old) -> P
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
        sleep 1.9
    fi

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
    sleep 0.9
    
    local temp_file="$MUX_ROOT/app.csv.temp"
    local prod_file="$MUX_ROOT/app.csv"

    if [ -f "$temp_file" ]; then
        mv "$temp_file" "$prod_file"
        
        if [ -f "$prod_file" ]; then
            cp "$prod_file" "$temp_file"
        fi
    else
         _bot_say "error" "Sandbox integrity failed."
         sleep 1.4
         return 1
    fi
    
    echo -e "${F_GRE} :: DEPLOYMENT SUCCESSFUL ::${F_RESET}"
    sleep 1.4
    
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

    # 1. 確保目標存在
    if [ ! -f "$target_file" ]; then return; fi

    # 2. 啟動 AWK 引擎 (使用 FPAT 模式解決逗號問題)
    awk -v FPAT='([^,]*)|("[^"]+")' -v OFS=, '
        NR==1 { print; next } # 標題行直接通過
        
        {
            # 移除引號以進行邏輯判斷
            type=$4; gsub(/^"|"$/, "", type)
            st=$7;   gsub(/^"|"$/, "", st); gsub(/\r| /, "", st)
            pkg=$10; gsub(/^"|"$/, "", pkg)
            tgt=$11; gsub(/^"|"$/, "", tgt)
            ihead=$12; gsub(/^"|"$/, "", ihead)
            ibody=$13; gsub(/^"|"$/, "", ibody)
            uri=$14;   gsub(/^"|"$/, "", uri)

            # 直接放行狀態 E/B/C/N
            if (st == "E" || st == "B" || st == "C" || st == "N") {
                print $0
                next
            }
            
            # 開始驗證有效性
            valid = 0
            
            if (type == "NA") {
                # NA 類型需要 PKG 和 TARGET
                if (pkg != "" && tgt != "") valid = 1
            }
            else if (type == "NB") {
                # NB 類型需要 Intent 或 PKG 或 URI
                if ((ihead != "" && ibody != "") || pkg != "" || uri != "") valid = 1
            }
            else if (type == "SYS" || type == "SSL") {
                # 系統指令通常視為有效
                valid = 1
            }
            
            # 如果 Type 是空的，視為無效
            if (type == "") valid = 0
            
            if (valid == 1) {
                # 驗證通過，且狀態為空或 P/F，強制蓋上合格章 "P"
                $7 = "\"P\""
            } else {
                # 驗證失敗標記為 "F"
                $7 = "\"F\""
            }
            
            print $0
        }
    ' "$target_file" > "$temp_file"

    # 3. 安全寫入檢查 (Safety Net)
    # 只有當 temp_file 有內容且大小大於 0 時才覆蓋
    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$target_file"
        echo -e "${F_GRE}    ›› Neural Nodes Verified & Patched.${F_RESET}"
    else
        # 如果發生截斷事故，刪除壞檔，保留原檔，並報警
        rm -f "$temp_file"
        echo -e "${F_ERR} :: CRITICAL ERROR :: Maintenance output empty! Aborting overwrite.${F_RESET}"
        echo -e "${F_GRAY}    (Your original data has been protected)${F_RESET}"
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
            gsub(/"/, "\\\"", name) 
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

    # Deploy
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
    local init_mode="${2:-EDIT}"

    # 前置作業
    _fac_neural_read "$target_key"
    
    local origin_key="$target_key"
    local restore_type="$_VAL_TYPE"
    if [ "$init_mode" == "NEW" ]; then restore_type="N"; fi

    _fac_neural_write "$target_key" 7 "B"

    # 引號處理
    local draft_row="$_VAL_CATNO,$_VAL_COMNO,${_VAL_CATNAME:+\"$_VAL_CATNAME\"},${_VAL_TYPE:+\"$_VAL_TYPE\"},${_VAL_COM:+\"$_VAL_COM\"},${_VAL_COM2:+\"$_VAL_COM2\"},\"E\",${_VAL_HUDNAME:+\"$_VAL_HUDNAME\"},${_VAL_UINAME:+\"$_VAL_UINAME\"},${_VAL_PKG:+\"$_VAL_PKG\"},${_VAL_TARGET:+\"$_VAL_TARGET\"},${_VAL_IHEAD:+\"$_VAL_IHEAD\"},${_VAL_IBODY:+\"$_VAL_IBODY\"},${_VAL_URI:+\"$_VAL_URI\"},${_VAL_MIME:+\"$_VAL_MIME\"},${_VAL_CATE:+\"$_VAL_CATE\"},${_VAL_FLAG:+\"$_VAL_FLAG\"},${_VAL_EX:+\"$_VAL_EX\"},${_VAL_EXTRA:+\"$_VAL_EXTRA\"},${_VAL_ENGINE:+\"$_VAL_ENGINE\"}"
    
    # 資料格式狀態
    echo "$draft_row" >> "$MUX_ROOT/app.csv.temp"
    local working_key="$target_key"
    export __FAC_IO_STATE="E"

    # 編輯迴圈 (Mutation Loop)
    local current_view_mode="$init_mode"
    local loop_signal=0

    while true; do
        # 安全檢查
        if ! _fac_neural_read "$working_key"; then
             _bot_say "error" "CRITICAL: Pointer Lost ($working_key). Aborting transaction."
             loop_signal=0
             break
        fi

        # UI 選擇器
        local selection
        selection=$(_factory_fzf_detail_view "$working_key" "$current_view_mode")
        
        # 如果使用者在 FZF 按 ESC，selection 會是空的
        if [ -z "$selection" ]; then
            loop_signal=0
            break
        fi

        # 呼叫路由器 (Router) 並捕捉輸出
        local router_out
        router_out=$(_fac_edit_router "$selection" "$working_key" "$current_view_mode")
        loop_signal=$?  # 選單狀態值

        local new_key_candidate=$(echo "$router_out" | grep "UPDATE_KEY:" | cut -d':' -f2)
        
        if [ -n "$new_key_candidate" ]; then
            # 更新鍵值狀態
            working_key="$new_key_candidate"
        fi

        # 狀態轉化
        if [ "$loop_signal" -eq 2 ] && [ "$current_view_mode" == "NEW" ]; then
            current_view_mode="EDIT"
        fi

        if [ "$loop_signal" -eq 1 ]; then
            # Out to Confirm
            break
        elif [ "$loop_signal" -eq 2 ]; then
            # Update to keep Edit
            _fac_sort_optimization
            _fac_matrix_defrag
            continue
        elif [ "$loop_signal" -eq 0 ]; then
            # Out to Rollback
            break
        fi
    done


    # Phase 4: 結算階段 (Settlement)
    if [ "$loop_signal" -eq 1 ]; then
        # Commit
        _bot_say "action" "Committing Transaction..."

        export __FAC_IO_STATE="B"
        _fac_delete_node "$origin_key"
        
        export __FAC_IO_STATE="E"
        _fac_neural_write "$working_key" 7 "S"
        _bot_say "success" "Transaction Saved. Node is active."
    else
        # Rollback
        _bot_say "warn" "Transaction Cancelled. Rolling back..."
        export __FAC_IO_STATE="E"
        _fac_delete_node "$working_key"
        
        if [ "$restore_type" == "N" ]; then
            export __FAC_IO_STATE="B"
            _fac_delete_node "$origin_key"
        else
            export __FAC_IO_STATE="B"
            _fac_neural_write "$origin_key" 7 "$restore_type"
        fi
    fi

    # 解除鎖定
    unset __FAC_IO_STATE
}

# 原子寫入函數 (Atomic Node Updater)
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

# 原子刪除函數 (Atomic Node Deleter)
function _fac_delete_node() {
    local target_key="$1"
    local target_file="$MUX_ROOT/app.csv.temp"
    
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
        c=$5; gsub(/^"|"$/, "", c); gsub(/\r| /, "", c)
        s=$6; gsub(/^"|"$/, "", s); gsub(/\r| /, "", s)
        st=$7; gsub(/^"|"$/, "", st); gsub(/\r| /, "", st)
        
        match_found = 0
        if (c == tc) {
            if (ts == "" && s == "") match_found = 1
            if (ts != "" && s == ts) match_found = 1
        }

        if (match_found) {
            if (mode == "User") {
                if (st == "B" || st == "E" || st == "C") {
                    print $0
                } else {
                    # 保護模式下，非 B/E/C 狀態不刪除
                }
            } else {
                if (st == mode) {
                } else {
                    print $0
                }
            }
        } else {
            print $0
        }
    }' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
}

# 通用單欄位編輯器 (Generic Editor)
function _fac_generic_edit() {
    local target_key="$1"
    local col_idx="$2"
    local prompt_text="$3"
    local guide_text="$4" # 接收參數
    
    # 1. 讀取最新狀態
    _fac_neural_read "$target_key"
    
    # 2. 映射欄位 (省略中間 case，與原代碼一致)
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
    
    _bot_say "action" "$prompt_text" >&2
    
    if [ -n "$guide_text" ]; then
        echo -e "$guide_text" >&2
    fi
    
    # 3. 使用者輸入
    echo -e "${F_GRAY}    Current: [ ${current_val:-Empty} ]${F_RESET}" >&2
    read -e -p "    › " -i "$current_val" input_val
    
    # 4. 原子寫入
    _fac_neural_write "$target_key" "$col_idx" "$input_val"
    _bot_say "success" "Parameter Updated." >&2
}

# 分類名稱批量更新器 (Batch Category Renamer)
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

    if [ -z "$room_id" ]; then
        room_id=$(echo "$raw_selection" | grep -o "ROOM_[A-Z_]*")
    fi

    room_id=$(echo "$room_id" | tr -d '[:space:]')

    local header_text="MODIFY PARAMETER"
    local border_color="208"
    local prompt_color="208"
    
    case "$view_mode" in
        "NEW") header_text="CONFIRM CREATION"; border_color="46"; prompt_color="46" ;;
        "DEL") header_text="DELETE PARAMETER"; border_color="196"; prompt_color="196" ;;
        "EDIT"|*) header_text="MODIFY PARAMETER :: "; border_color="46"; prompt_color="46" ;;
    esac
    
    # 路由分支 (Router Switch)
    case "$room_id" in
        "ROOM_INFO")
            # 1. 讀取當前節點
            _fac_neural_read "$target_key"
            local current_cat_no="$_VAL_CATNO"
            local current_cat_name="$_VAL_CATNAME"

            # 2. 呼叫分類選單
            local sel_id=$(_factory_fzf_cat_selector "RELOCATE")

            if [ -z "$sel_id" ]; then return 0; fi

            sel_id=$(echo "$sel_id" | sed "s/$(printf '\033')\[[0-9;]*m//g")

            # Branch A: 新增類別 (New Category)
            if [ "$sel_id" == "NEW_SIGNAL" ]; then
                _bot_say "action" "Forging New Category..." >&2
                echo -e "${F_GRAY} :: Guide   : Enter name for the new category.${F_RESET}" >&2
                read -e -p "    › " new_cat_name
                
                if [ -z "$new_cat_name" ]; then return 0; fi

                # 全域相似度掃描
                local scan_result=$(awk -F, -v input="$new_cat_name" '
                    function min(a, b, c) {
                        m = a; if (b < m) m = b; if (c < m) m = c; return m
                    }
                    function calc_dist(s1, s2) {
                        s1 = tolower(s1); s2 = tolower(s2);
                        n = length(s1); m = length(s2);
                        if (n == 0) return m; if (m == 0) return n;
                        
                        delete d
                        
                        for (i=0; i<=n; i++) d[i,0] = i
                        for (j=0; j<=m; j++) d[0,j] = j
                        for (i=1; i<=n; i++) {
                            for (j=1; j<=m; j++) {
                                cost = (substr(s1,i,1) == substr(s2,j,1)) ? 0 : 1
                                d[i,j] = min(d[i-1,j]+1, d[i,j-1]+1, d[i-1,j-1]+cost)
                            }
                        }
                        return d[n,m]
                    }

                    BEGIN { best_sim = 0; match_type = "OK"; target_id = ""; target_name = "" }
                    
                    NR>1 {
                        id=$1; gsub(/^"|"$/, "", id);
                        name=$3; gsub(/^"|"$/, "", name);
                        
                        if (id == "" || name == "") next;

                        dist = calc_dist(input, name)
                        maxlen = (length(input) > length(name)) ? length(input) : length(name)
                        sim = 1 - (dist / maxlen)

                        if (sim == 1.0) {
                            print "EXACT:" id ":" name
                            exit 
                        }
                        
                        if (sim > 0.82 && sim > best_sim) {
                            best_sim = sim
                            match_type = "SIMILAR"
                            target_name = name
                        }
                    }
                    
                    END {
                        if (match_type == "SIMILAR") print "SIMILAR:" target_name
                        else print "OK"
                    }
                ' "$MUX_ROOT/app.csv.temp")

                # 判斷掃描結果
                if [[ "$scan_result" == EXACT* ]]; then
                    local exist_id=$(echo "$scan_result" | cut -d: -f2)
                    local exist_name=$(echo "$scan_result" | cut -d: -f3)

                    _bot_say "warn" "Detected existing category [$exist_id]. Routing..." >&2
                    echo -e "${F_GRAY}    ›› You typed that manually? We have a menu for a reason... 🙄${F_RESET}" >&2

                    local next_com_no=$(awk -F, -v target_cat="$exist_id" '
                        BEGIN { max=0 }
                        { id=$1; gsub(/^"|"$/, "", id); cn=$2; gsub(/^"|"$/, "", cn); 
                        if (id == target_cat && (cn+0) > max) max=cn+0 } END { print max+1 }
                    ' "$MUX_ROOT/app.csv.temp")

                    _fac_neural_write "$target_key" 1 "$exist_id"
                    _fac_neural_write "$target_key" 2 "$next_com_no"
                    _fac_neural_write "$target_key" 3 "$exist_name"
                    
                    _bot_say "success" "Auto-Relocated to [$exist_id]." >&2
                    return 2

                elif [[ "$scan_result" == SIMILAR* ]]; then
                    local similar_name=$(echo "$scan_result" | cut -d: -f2)
                    _bot_say "error" "Input '$new_cat_name' is too similar to existing '$similar_name'." >&2
                    echo -e "${F_GRAY}    ›› Similarity › 70%. Did you make a typo? Request Denied.${F_RESET}" >&2
                    return 0
                fi

                local next_cat_no=$(awk -F, '
                    BEGIN { max=0 }
                    NR>1 {
                        id=$1; gsub(/^"|"$/, "", id)
                        if ((id+0) > max && (id+0) != 999) max=id+0 
                    } 
                    END { 
                        val = (max == 0) ? 1 : max+1
                        printf "%03d", val 
                    }
                ' "$MUX_ROOT/app.csv.temp")
                
                _bot_say "action" "Moving Node to New Sector [$next_cat_no] $new_cat_name..." >&2
                
                # 原子寫入
                _fac_neural_write "$target_key" 1 "$next_cat_no"  
                _fac_neural_write "$target_key" 2 "1"             
                _fac_neural_write "$target_key" 3 "$new_cat_name"
                
                _bot_say "success" "Node Relocated." >&2
                return 2

            # Branch B: 移動到現有類別 (Existing Category)
            else
                local sel_name=$(awk -F, -v tid="$sel_id" '
                    NR>1 {
                        id=$1; gsub(/^"|"$/, "", id); 
                        name=$3; gsub(/^"|"$/, "", name);
                        if (id+0 == tid+0) { print name; exit }
                    }
                ' "$MUX_ROOT/app.csv.temp")

                if [ "$sel_id" == "$current_cat_no" ]; then
                    _bot_say "warn" "Node is already in this category." >&2
                    return 0
                fi

                _bot_say "action" "Relocating Node to [$sel_id] $sel_name..." >&2

                # 計算 COMNO (Max+1)
                local next_com_no=$(awk -F, -v target_cat="$sel_id" '
                    BEGIN { max=0 }
                    {
                        id=$1; gsub(/^"|"$/, "", id)
                        cn=$2; gsub(/^"|"$/, "", cn)
                        if (id == target_cat) {
                            if ((cn+0) > max) max=cn+0
                        }
                    }
                    END { print max+1 }
                ' "$MUX_ROOT/app.csv.temp")

                # 原子寫入
                _fac_neural_write "$target_key" 1 "$sel_id"
                _fac_neural_write "$target_key" 2 "$next_com_no"
                _fac_neural_write "$target_key" 3 "$sel_name"

                _bot_say "success" "Transfer Complete. Assigned ID: $next_com_no" >&2
                return 2
            fi
            ;;

        "ROOM_CMD")
            local current_track_key="$target_key"
            
            while true; do
                _fac_neural_read "$current_track_key"
                
                local disp_com="${_VAL_COM}"
                local disp_sub="${_VAL_COM2:-[Empty]}"
                
                local menu_list=$(
                    echo -e " COMMAND \t$disp_com"
                    echo -e " SUBCOM  \t$disp_sub"
                    echo -e "\033[1;30m----------\033[0m"
                    echo -e "\033[1;32m[Confirm]\033[0m"
                )

                local choice=$(echo -e "$menu_list" | fzf --ansi \
                    --height=8 \
                    --layout=reverse \
                    --border-label=" :: EDIT IDENTITY :: " \
                    --border=bottom \
                    --header=" :: Changing COM updates the Node ID ::" \
                    --prompt=" :: Setting › " \
                    --info=hidden \
                    --pointer="››" \
                    --delimiter="\t" \
                    --with-nth=1,2 \
                    --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                    --color=info:240,prompt:$prompt_color,pointer:red,marker:208,border:$border_color,header:240 \
                    --bind="resize:clear-screen"
                )

                if [ -z "$choice" ]; then return 0; fi

                if echo "$choice" | grep -q " COM"; then
                    _bot_say "action" "Edit Command (Trigger):" >&2
                    echo -e "${F_GRAY} :: Guide   : The main CLI command (e.g., 'chrome').${F_RESET}" >&2
                    
                    read -e -p "    › " -i "$_VAL_COM" new_com
                    new_com=$(echo "$new_com" | sed 's/^[ \t]*//;s/[ \t]*$//')
                    
                    if [ -n "$new_com" ] && [ "$new_com" != "$_VAL_COM" ]; then
                        _fac_neural_write "$current_track_key" 5 "$new_com"
                        local old_sub="${_VAL_COM2}"
                        if [ -n "$old_sub" ]; then
                            current_track_key="$new_com '$old_sub'"
                        else
                            current_track_key="$new_com"
                        fi
                        _bot_say "success" "Identity Updated." >&2
                    fi
                elif echo "$choice" | grep -q " SUB"; then
                    _bot_say "action" "Edit Sub-Command (Optional):" >&2
                    echo -e "${F_GRAY} :: Guide   : The secondary trigger (e.g., 'incognito').${F_RESET}" >&2
                    
                    read -e -p "    › " -i "$_VAL_COM2" new_sub
                    new_sub=$(echo "$new_sub" | sed 's/^[ \t]*//;s/[ \t]*$//')
                    
                    if [ "$new_sub" != "$_VAL_COM2" ]; then
                        _fac_neural_write "$current_track_key" 6 "$new_sub"
                        local cur_com="${_VAL_COM}"
                        if [ -n "$new_sub" ]; then
                            current_track_key="$cur_com '$new_sub'"
                        else
                            current_track_key="$cur_com"
                        fi
                        _bot_say "success" "Sub-Command Updated." >&2
                    fi
                
                elif echo "$choice" | grep -q "Confirm"; then
                    echo "UPDATE_KEY: $current_track_key"
                    return 2
                fi
            done
            ;;

        "ROOM_HUD")
            echo -e "${F_GRAY} :: Guide   : Enter the Menu Description.${F_RESET}" >&2
            echo -e "${F_GRAY} :: Format  : e.g. 'Google Chrome Browser'${F_RESET}" >&2
            
            _fac_generic_edit "$target_key" 8 "Edit Description (HUD Name):"
            return 2
            ;;

        "ROOM_UI")
            echo -e "${F_GRAY} :: Guide   : UI Rendering Mode${F_RESET}" >&2
            echo -e "${F_GRAY} :: Options : ${F_WARN}[Empty]${F_GRAY}=Default, ${F_WARN}fzf${F_GRAY}, ${F_WARN}silent${F_RESET}" >&2
            
            _fac_generic_edit "$target_key" 9 "Edit Display Name (Bot Label):"
            return 2
            ;;
            
        "ROOM_PKG")
            echo -e "${F_GRAY} :: Guide   : Target Android Package${F_RESET}" >&2
            echo -e "${F_GRAY} :: Hint    : Use 'apklist' or 'ROOM_LOOKUP' to find packages.${F_RESET}" >&2
            
            _fac_generic_edit "$target_key" 10 "Edit Package Name (com.xxx.xxx):"
            return 2
            ;;

        "ROOM_ACT")
            echo -e "${F_GRAY} :: Guide   : Target Activity Class (Optional)${F_RESET}" >&2
            echo -e "${F_GRAY} :: Format  : com.package.name.MainActivity${F_RESET}" >&2
            
            _fac_generic_edit "$target_key" 11 "Edit Activity / Class Path:"
            return 2
            ;;
            
        "ROOM_CATE")
            echo -e "${F_GRAY} :: Guide   : Intent Category Suffix${F_RESET}" >&2
            echo -e "${F_GRAY} :: Note    : System adds 'android.intent.category.' prefix.${F_RESET}" >&2
            echo -e "${F_GRAY} :: Example : ${F_WARN}BROWSABLE${F_RESET}, ${F_WARN}DEFAULT${F_RESET}, ${F_WARN}LAUNCHER${F_RESET}" >&2
            
            _fac_generic_edit "$target_key" 16 "Edit Category Type:"
            return 2
            ;;

        "ROOM_FLAG")
            echo -e "${F_GRAY} :: Guide   : Execution Flags (am start)${F_RESET}" >&2
            echo -e "${F_GRAY} :: Example : ${F_WARN}--user 0${F_RESET}, ${F_WARN}--grant-read-uri-permission${F_RESET}" >&2
            
            _fac_generic_edit "$target_key" 17 "Edit Execution Flags:"
            return 2
            ;;

        "ROOM_INTENT")
            echo -e "${F_GRAY} :: Guide   : Intent Action HEAD${F_RESET}" >&2
            echo -e "${F_GRAY} :: Format  : android.intent.action${F_RESET}" >&2
            _fac_generic_edit "$target_key" 12 "Edit Intent Action (Head):"
            
            echo -e "${F_GRAY} :: Guide   : Intent Action BODY${F_RESET}" >&2
            echo -e "${F_GRAY} :: Format  : '.VIEW', '.SEND', '.MAIN' ...${F_RESET}" >&2
            _fac_generic_edit "$target_key" 13 "Edit Intent Data (Body):"
            return 2
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
                    --header=" :: Static URI overrides Engine ::" \
                    --prompt=" :: Setting › " \
                    --info=hidden \
                    --pointer="››" \
                    --delimiter="\t" \
                    --with-nth=1,2 \
                    --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                    --color=info:240,prompt:$prompt_color,pointer:red,marker:208,border:$border_color,header:240 \
                    --bind="resize:clear-screen"
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
                    local sel_eng=$(echo -e "$engine_list" | fzf --ansi \
                    --height=10 \
                    --layout=reverse \
                    --border-label=" :: SELECT SEARCH ENGINE :: " \
                    --border=bottom \
                    --header=":: Select Search Engine ::" \
                    --info=hidden \
                    --pointer="››" \
                    --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                    --color=info:240,prompt:$prompt_color,pointer:red,marker:208,border:$border_color,header:240 \
                    --bind="resize:clear-screen"
                    )

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
            _bot_say "action" "Launching Reference Tool..." >&2
            if command -v apklist &> /dev/null; then
                apklist >&2
            else
                echo "Module missing" >&2
            fi

            echo -e "" >&2
            echo -e "${F_GRAY}    (Press 'Enter' to return to Factory)${F_RESET}" >&2
            read
            return 2
            ;;

        "ROOM_CONFIRM")
            _fac_neural_read "$target_key"
            if [ -z "$_VAL_COM" ] || [ "$_VAL_COM" == "[Empty]" ]; then
                _bot_say "error" "Command Name is required!" >&2
                return 2
            else
                _bot_say "success" "Node Validated." >&2
                return 1
            fi
            ;;

        *)
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
        # 處決狀態 B 跟 C ，將 B 轉 P
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

# 複合鍵偵測器 (Private Logic)
function _fac_check_composite_exists() {
    local c1="$1"
    local c2="$2"
    local csv_path="$MUX_ROOT/app.csv.temp"
    if [ ! -f "$csv_path" ]; then csv_path="$MUX_ROOT/app.csv"; fi

    if [ -z "$c1" ] || [ -z "$c2" ]; then return 1; fi
    if [ ! -f "$csv_path" ]; then return 1; fi

    awk -F, -v c1="$c1" -v c2="$c2" '
    {
        k1=$5; gsub(/^"|"$/, "", k1); gsub(/^[ \t]+|[ \t]+$/, "", k1)
        k2=$6; gsub(/^"|"$/, "", k2); gsub(/^[ \t]+|[ \t]+$/, "", k2)
        st=$7; gsub(/^"|"$/, "", st); gsub(/[ \t]/, "", st)
        
        if ((st=="P" || st=="S" || st=="E") && k1==c1 && k2==c2) {
            exit 0 # Found
        }
    }
    END { exit 1 } # Not Found
    ' "$csv_path"
}

# 兵工廠測試發射台 (Factory Fire Control Test)
function _fac_launch_test() {
    local input_key="$1"
    local input_args="${*:2}"

    # 1. 讀取資料
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
    local C_EMP="\033[1;30m[Empty]\033[0m"

    # 準備注入的參數
    local raw_query="${input_args}"
    local safe_query="${input_args// /+}"

    # 處理 Smart URL / Engine
    if [[ "$_VAL_URI" == *"\$__GO_TARGET"* ]]; then
        local engine_base=""
        if [ -n "$_VAL_ENGINE" ]; then engine_base=$(eval echo "$_VAL_ENGINE"); fi
        
        if command -v _resolve_smart_url &> /dev/null; then
             _resolve_smart_url "$engine_base" "$input_args"
             _VAL_URI="$__GO_TARGET"
        else
             _VAL_URI="${engine_base}${safe_query}"
        fi
    fi

    # 全域變數替換
    _VAL_URI="${_VAL_URI//\$query/$safe_query}"
    _VAL_EXTRA="${_VAL_EXTRA//\$query/$raw_query}"
    _VAL_EX="${_VAL_EX//\$query/$raw_query}"
    _VAL_PKG="${_VAL_PKG//\$query/$raw_query}"
    _VAL_TARGET="${_VAL_TARGET//\$query/$raw_query}"
    _VAL_FLAG="${_VAL_FLAG//\$query/$raw_query}"
    
    # 顯示詳細資訊
    # 共通欄位
    echo -e "${C_SEP}    ---------------${C_RST}"
    printf "${C_TYPE}    [TYPE: %-3s]${C_RST}\n" "$_VAL_TYPE"
    echo -e "${C_LBL}    Command:${C_RST} ${C_VAL}$_VAL_COM ${_VAL_COM2:-$C_EMP}${C_RST}"
    echo -e "${C_LBL}    UI     :${C_RST} ${C_VAL}${_VAL_UINAME:-$C_EMP}${C_RST}"
    echo -e "${C_LBL}    Detail :${C_RST} ${C_VAL}${_VAL_HUDNAME:-$C_EMP}${C_RST}"
    echo -e "${C_SEP}    ---------------${C_RST}"

    # TYPE 欄位
    case "$_VAL_TYPE" in
        "NA")
            echo -e "    ${C_LBL}Package:${C_RST} ${C_VAL}${_VAL_PKG:-$C_EMP}${C_RST}"
            echo -e "    ${C_LBL}Target :${C_RST} ${C_VAL}${_VAL_TARGET:-$C_EMP}${C_RST}"
            ;;
        "NB"|"SYS")
            local intent_str="${_VAL_IHEAD}${_VAL_IBODY}"
            echo -e "    ${C_LBL}Intent :${C_RST} ${C_VAL}${intent_str:-$C_EMP}${C_RST}"
            
            if [ -n "$_VAL_ENGINE" ]; then
                echo -e "    ${C_LBL}Engine :${C_RST} ${C_VAL}$_VAL_ENGINE${C_RST}"
            else
                echo -e "    ${C_LBL}URI    :${C_RST} ${C_VAL}${_VAL_URI:-$C_EMP}${C_RST}"
            fi

            [ -n "$_VAL_PKG" ] && echo -e "    ${C_LBL}Package:${C_RST} ${C_VAL}$_VAL_PKG${C_RST}"
            [ -n "$_VAL_TARGET" ] && echo -e "    ${C_LBL}Target :${C_RST} ${C_VAL}$_VAL_TARGET${C_RST}"
            ;;
    esac

    # 旗標顯示
    [ -n "$_VAL_CATE" ] && echo -e "    ${C_LBL}Cate   :${C_RST} ${C_VAL}$_VAL_CATE${C_RST}"
    [ -n "$_VAL_MIME" ] && echo -e "    ${C_LBL}Mime   :${C_RST} ${C_VAL}$_VAL_MIME${C_RST}"
    [ -n "$_VAL_FLAG" ] && echo -e "    ${C_LBL}Flag   :${C_RST} ${C_VAL}$_VAL_FLAG${C_RST}"

    local ex_str=""
    local extra_str=""
    [ -n "$_VAL_EX" ] && ex_str="    ${C_LBL}Extra  :${C_RST} ${C_VAL}$_VAL_EX${C_RST}"
    [ -n "$_VAL_EXTRA" ] && extra_str="${C_VAL}$_VAL_EXTRA${C_RST}"
    if [ -n "$ex_str" ] || [ -n "$extra_str" ]; then echo -e "${ex_str} ${extra_str}"; fi

    # 3. 智慧網址解析
    local final_uri="$_VAL_URI"

    # 如果有變數，先進行解析
    if [[ "$_VAL_URI" == *"\$__GO_TARGET"* ]] || [[ "$_VAL_URI" == *"\$query"* ]]; then
        
        # 準備解析參數
        local engine_base=""
        if [ -n "$_VAL_ENGINE" ]; then engine_base=$(eval echo "$_VAL_ENGINE"); fi
        local test_query="${input_args:-TEST_PAYLOAD}"
        
        # 解析邏輯
        if [[ "$_VAL_URI" == *"\$query"* ]]; then
             local safe_args="${input_args// /+}"
             final_uri="${_VAL_URI//\$query/$safe_args}"
        
        elif [[ "$_VAL_URI" == *"\$__GO_TARGET"* ]]; then
             if command -v _resolve_smart_url &> /dev/null; then
                 # 呼叫 Core
                 _resolve_smart_url "$engine_base" "$test_query"
                 final_uri="$__GO_TARGET"
             else
                 # Fallback
                 local safe_q="${test_query// /+}"
                 final_uri="${engine_base}${safe_q}"
             fi
        fi
        
        # 輸出網址串
        echo -e "${C_SEP}    ---------------${C_RST}"
        echo -e "${F_GRAY}    Resolving › $final_uri${F_RESET}"
        echo -e "${C_SEP}    ---------------${C_RST}"
    fi

    # 4. 選擇開火模式
    local menu_opts=""
    
    # 建構選單 (t, d, n, p, i, SSL)
    menu_opts+="MODE_T\t\033[1;35m['t' mode]\033[0m Direct Launch ( -n PKG/TARGET )\n"
    menu_opts+="MODE_D\t\033[1;32m['d' mode]\033[0m Standard AM ( -a -d -p -f... )\n"
    menu_opts+="MODE_N\t\033[1;33m['n' mode]\033[0m Component Lock ( -a -d -n... )\n"
    menu_opts+="MODE_P\t\033[1;34m['p' mode]\033[0m Package Lock ( -a -d -p... )\n"
    menu_opts+="MODE_I\t\033[1;36m['i' mode]\033[0m Implicit Intent ( -a -d Only )\n"
    
    # SSL 隱藏接口
    # menu_opts+="SSL\t\033[1;31m[MODE_S]\033[0m Special Mode"

    local fzf_sel=$(echo -e "$menu_opts" | fzf --ansi \
        --height=9 \
        --info=hidden \
        --layout=reverse \
        --border=bottom \
        --border-label=" :: FIRE CONTROL :: " \
        --header=" :: Enter to Select, Esc to Return :: " \
        --prompt=" :: Fire Mode Detected › " \
        --pointer="››" \
        --delimiter="\t" \
        --with-nth=2,3 \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        --bind="resize:clear-screen"
    )

    if [ -z "$fzf_sel" ]; then return 0; fi
    local fire_mode=$(echo "$fzf_sel" | awk '{print $1}')
    
    echo -e "${F_WARN} :: EXECUTING SEQUENCE ($fire_mode) ::${F_RESET}"

    # 5. 根據開火模式組裝彈藥
    local final_cmd=""
    local output=""
    local success=0

    local act="${_VAL_IHEAD}${_VAL_IBODY}"
    local dat="$final_uri"
    local pkg="$_VAL_PKG"
    local tgt="$_VAL_TARGET"
    local flg="$_VAL_FLAG"
    local cat="$_VAL_CATE"
    local mime="$_VAL_MIME"
    local ex="$_VAL_EX"
    local extra="$_VAL_EXTRA"

    case "$fire_mode" in
        "MODE_T")
            # 't' mode: Direct Launch (-n PKG/TARGET)
            if [ -z "$pkg" ] || [ -z "$tgt" ]; then _bot_say "warn" "Missing PKG or TARGET."; return 1; fi
            final_cmd="am start --user 0 -n \"$pkg/$tgt\""
            ;;

        "MODE_D")
            # 'd' mode: Standard AM (adpfc, ex+extra)
            final_cmd="am start --user 0"
            [ -n "$act" ] && final_cmd="$final_cmd -a \"$act\""
            [ -n "$dat" ] && final_cmd="$final_cmd -d \"$dat\""
            [ -n "$pkg" ] && final_cmd="$final_cmd -p \"$pkg\""
            [ -n "$flg" ] && final_cmd="$final_cmd -f $flg"
            [ -n "$cat" ] && final_cmd="$final_cmd -c \"android.intent.category.$cat\""
            [ -n "$ex" ]  && final_cmd="$final_cmd $ex"
            [ -n "$extra" ] && final_cmd="$final_cmd $extra"
            ;;

        "MODE_N")
            # 'n' mode: Component Lock (apctdf, ex+extra)
            if [ -z "$pkg" ] || [ -z "$tgt" ]; then _bot_say "error" "Missing PKG or TARGET."; return 1; fi
            final_cmd="am start --user 0"
            [ -n "$act" ] && final_cmd="$final_cmd -a \"$act\""
            [ -n "$pkg" ] && final_cmd="$final_cmd -n \"$pkg/$tgt\"" # Note: -n replaces -p
            [ -n "$dat" ] && final_cmd="$final_cmd -d \"$dat\""
            [ -n "$cat" ] && final_cmd="$final_cmd -c \"android.intent.category.$cat\""
            [ -n "$mime" ] && final_cmd="$final_cmd -t \"$mime\""
            [ -n "$flg" ] && final_cmd="$final_cmd -f $flg"
            [ -n "$ex" ]  && final_cmd="$final_cmd $ex"
            [ -n "$extra" ] && final_cmd="$final_cmd $extra"
            ;;

        "MODE_P")
            # 'p' mode: Package Lock (adctf, ex+extra)
            if [ -z "$pkg" ]; then _bot_say "error" "Missing PKG."; return 1; fi
            final_cmd="am start --user 0"
            [ -n "$act" ] && final_cmd="$final_cmd -a \"$act\""
            [ -n "$dat" ] && final_cmd="$final_cmd -d \"$dat\""
            [ -n "$pkg" ] && final_cmd="$final_cmd -p \"$pkg\""
            [ -n "$cat" ] && final_cmd="$final_cmd -c \"android.intent.category.$cat\""
            [ -n "$mime" ] && final_cmd="$final_cmd -t \"$mime\""
            [ -n "$flg" ] && final_cmd="$final_cmd -f $flg"
            [ -n "$ex" ]  && final_cmd="$final_cmd $ex"
            [ -n "$extra" ] && final_cmd="$final_cmd $extra"
            ;;

        "MODE_I")
            # 'i' mode: Implicit Intent (andctf... without P/N)
            final_cmd="am start --user 0"
            [ -n "$act" ] && final_cmd="$final_cmd -a \"$act\""
            [ -n "$dat" ] && final_cmd="$final_cmd -d \"$dat\""
            [ -n "$cat" ] && final_cmd="$final_cmd -c \"android.intent.category.$cat\""
            [ -n "$mime" ] && final_cmd="$final_cmd -t \"$mime\""
            [ -n "$flg" ] && final_cmd="$final_cmd -f $flg"
            [ -n "$ex" ]  && final_cmd="$final_cmd $ex"
            [ -n "$extra" ] && final_cmd="$final_cmd $extra"
            ;;

        "SSL")
            # SSL: System / Shell Direct
            final_cmd="$pkg $input_args"
            ;;
    esac

    # 6. 執行與輸出報告
    if [ -n "$final_cmd" ]; then
        echo -e "${F_GRAY}    Payload › $final_cmd${F_RESET}"
        output=$(eval "$final_cmd" 2>&1)
        
        if [[ "$output" == *"Error"* || "$output" == *"does not exist"* || "$output" == *"unable to resolve"* ]]; then
             echo -e "\n${F_ERR} :: FIRE FAILED ::${F_RESET}"
             echo -e "${F_GRAY}    $output${F_RESET}"
             return 1
        else
             echo -e "\n${F_GRE} :: FIRE SUCCESS ::${F_RESET}"
             if [ "$fire_mode" == "SSL" ]; then
                 echo -e "${F_GRAY}    ---------------${F_RESET}"
                 echo -e "$output"
                 echo -e "${F_GRAY}    ---------------${F_RESET}"
             else
                 echo -e "${F_GRAY}    ›› Target Impacted.${F_RESET}"
             fi
             return 0
        fi
    fi
}