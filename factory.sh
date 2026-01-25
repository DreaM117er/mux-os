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
F_GRE="\n\033[1;32m"

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
            # 1. 呼叫類型選單
            local type_sel=$(_factory_fzf_add_type_menu)
            
            # 處理 Cancel 或 ESC
            if [[ -z "$type_sel" || "$type_sel" == "Cancel" || "$type_sel" == *"------"* ]]; then
                return
            fi

            # 2. 確定新增，執行備份
            if command -v _factory_auto_backup &> /dev/null; then
                _fac_maintenance
                _factory_auto_backup
            fi

            # 3. 計算 COMNO (Target Category: 999 - Others)
            # 邏輯：掃描 CATNO=999 的所有行，找出最大的 COMNO，加 1
            local next_comno=$(awk -F, '$1==999 {gsub(/^"|"$/, "", $2); if(($2+0) > max) max=$2} END {print max+1}' "$MUX_ROOT/app.csv.temp")
            
            # 防呆計算
            local com3_flag="N"
            local target_cat="999"
            local target_catname="\"Others\"" # [Update] 預設分類名稱
            
            if [ -z "$next_comno" ] || [ "$next_comno" -eq 1 ]; then
                # 如果是第一筆，或是計算失敗(awk回傳空)，設為 1
                next_comno=1
            fi
            
            # 如果計算出的數字極度不合理 (例如 awk 錯誤)，掛上 F 旗標
            if ! [[ "$next_comno" =~ ^[0-9]+$ ]]; then
                com3_flag="F"
                target_cat=""     # 清空 CATNO
                next_comno=""     # 清空 COMNO
                target_catname="" # [Update] 異常時一併清空 CATNAME
            fi

            # 4. 生成暫時的指令名稱 (Unique ID)
            # 為了讓 detail_view 能馬上找到它，我們需要一個獨一無二的名字
            local ts=$(date +%s)
            local temp_cmd_name="ND${ts}"

            # 5. 建構 CSV 行 (Construct Row)
            # 欄位總數：20
            # 預設 CATNAME: "Others" -> 改用變數控制
            local new_row=""
            
            case "$type_sel" in
                "Command NA")
                    # NA 模板: TYPE=NA, COM3=N
                    # 格式: 999,NO,"Others","NA","tmp_name",,,"N",,, ... (其餘留空)
                    new_row="${target_cat},${next_comno},${target_catname},\"NA\",\"${temp_cmd_name}\",,\"${com3_flag}\",,,,,,,,,,,,,"
                    ;;
                    
                "Command NB")
                    # NB 模板: TYPE=NB, COM3=N, URI=$__GO_TARGET, ENGINE=$SEARCH_GOOGLE
                    # Col 14(URI), Col 20(ENGINE)
                    new_row="${target_cat},${next_comno},${target_catname},\"NB\",\"${temp_cmd_name}\",,\"${com3_flag}\",,,,,,,,\"$(echo '$__GO_TARGET')\",,,,,,\"$(echo '$SEARCH_GOOGLE')\""
                    ;;
                    
                "Command SYS"*) 
                    # 預留接口
                    _bot_say "warn" "SYS Creation not implemented."
                    return
                    ;;
            esac

            # 6. 寫入檔案 (Append)
            if [ -n "$new_row" ]; then
                echo "$new_row" >> "$MUX_ROOT/app.csv.temp"
                
                # 7. 直接進入 EDIT 模式
                # 這裡我們使用剛才生成的 temp_cmd_name 讓 detail_view 鎖定它
                # 因為 detail_view 現在支援 COM3="N" 的視覺變色，使用者會看到紅色的必填框
                
                # [Important] 這裡要確保 detail_view 收到的是乾淨的指令名
                _factory_fzf_detail_view "${temp_cmd_name}" "NEW"
                
                # [TODO] 編輯完後，記得要有一個後處理機制（例如移除 N 旗標、重新排序等）
                # 這部分屬於 _fac_maintenance 的範疇，目前先不處理
            fi
            ;;

        # : Edit Neural (Edit Command)
        "edit"|"comedit"|"comm")
            local view_state="EDIT"

            while true; do
                # Level 1: Select Command
                local raw_target=$(_factory_fzf_menu "Select App to Edit")
                if [ -z "$raw_target" ]; then break; fi
                
                # [Logic] 清洗目標字串
                local clean_target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')

                # Level 2: Detail View (EDIT Mode)
                if [ "$view_state" == "EDIT" ]; then
                    # 接收 Detail View 回傳的選擇 (準備路由)
                    local selection=$(_factory_fzf_detail_view "$clean_target" "EDIT")
                    
                    if [ -n "$selection" ]; then
                        # [TODO] _fac_edit_router "$selection" ...
                        : # 佔位符
                    fi
                fi
            done
            ;;

        # : Edit Category
        "catedit"|"cate")
            local view_state="EDIT"

            while true; do
                # Level 1: Select Category
                local raw_cat=$(_factory_fzf_cat_selector)
                if [ -z "$raw_cat" ]; then break; fi
                
                # [SOP 1] 提取 ID
                local temp_id=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')

                # [SOP 2] 查表獲取權威 ID & Name (Lookup ID/Name by ID)
                local db_data=$(awk -F, -v tid="$temp_id" '
                    NR>1 {
                        cid=$1; gsub(/^"|"$/, "", cid)
                        if (cid == tid) {
                            name=$3; gsub(/^"|"$/, "", name)
                            print cid "|" name
                            exit
                        }
                    }
                ' "$MUX_ROOT/app.csv.temp")

                local cat_id=$(echo "$db_data" | awk -F'|' '{print $1}')
                local cat_name=$(echo "$db_data" | awk -F'|' '{print $2}')

                # 防呆
                if [ -z "$cat_id" ]; then cat_id="XX"; cat_name="Unknown"; fi

                while true; do
                    # Level 2: Submenu (傳入權威 ID & Name)
                    local action=$(_factory_fzf_catedit_submenu "$cat_id" "$cat_name")
                    if [ -z "$action" ]; then break; fi

                    # Level 3: Action Branch
                    if echo "$action" | grep -q "Edit Name" ; then
                        # Branch A: Modify Category Name
                        _bot_say "warn" "Edit CATNAME [$cat_name] pending..."
                        
                    elif echo "$action" | grep -q "Edit Command in" ; then
                        # Branch B: Modify Commands in Category
                        while true; do
                            # 使用權威名稱搜尋指令
                            local raw_cmd=$(_factory_fzf_cmd_in_cat "$cat_name")
                            if [ -z "$raw_cmd" ]; then break; fi
                            
                            local clean_cmd=$(echo "$raw_cmd" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')

                            if [ "$view_state" == "EDIT" ]; then
                                _factory_fzf_detail_view "$clean_cmd" "EDIT"
                            fi
                        done
                    fi
                done
            done
            ;;

        # : Break Neural (Delete Command)
        "del"|"comd"|"delcom")
            while true; do
                # 1. 紅色警示選單
                local raw_target=$(_factory_fzf_menu "Select to Destroy" "DEL")
                if [ -z "$raw_target" ]; then break; fi
                
                # 2. 清洗與解析座標
                local clean_target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                # 解析 COM 與 COM2
                local t_com=$(echo "$clean_target" | awk '{print $1}')
                local t_sub=""
                if [[ "$clean_target" == *"'"* ]]; then
                    t_sub=$(echo "$clean_target" | awk -F"'" '{print $2}')
                fi

                # 3. 確認刪除
                echo -e "\033[1;31m :: WARNING: Deleting Node [ $clean_target ] \033[0m"
                echo -ne "\033[1;33m    ›› Confirm destruction? [Y/n]: \033[0m"
                read -r choice
                if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
                    continue
                fi

                # 4. 執行備份
                if command -v _factory_auto_backup &> /dev/null; then
                    _factory_auto_backup
                fi

                # 5. 物理刪除
                local target_file="$MUX_ROOT/app.csv.temp"
                local temp_del="${target_file}.del"
                
                awk -F, -v c="$t_com" -v s="$t_sub" '
                    {
                        csv_c=$5; gsub(/^"|"$/, "", csv_c)
                        csv_s=$6; gsub(/^"|"$/, "", csv_s)
                        
                        is_target = 0
                        if (csv_c == c) {
                            if (s == "" && csv_s == "") is_target = 1
                            if (s != "" && csv_s == s) is_target = 1
                        }

                        if (is_target == 0 || NR == 1) {
                            print $0
                        }
                    }
                ' "$target_file" > "$temp_del"
                
                mv "$temp_del" "$target_file"
                
                # 6. 排序 + 重組
                _fac_sort_optimization
                _fac_matrix_defrag
            done
            ;;
        
        # : Delete Command via Category (Filter Search)
        "catd"|"catdel")
            while true; do
                # Level 1: 選擇分類 (紅色模式)
                local raw_cat=$(_factory_fzf_cat_selector "DEL")
                if [ -z "$raw_cat" ]; then break; fi
                
                # 解析 ID 與 Name
                local temp_id=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
                local db_name=$(awk -F, -v tid="$temp_id" 'NR>1 {cid=$1; gsub(/^"|"$/, "", cid); if(cid==tid){name=$3; gsub(/^"|"$/, "", name); print name; exit}}' "$MUX_ROOT/app.csv.temp")
                if [ -z "$db_name" ]; then db_name="Unknown"; fi

                # Level 2: 戰術決策 (使用模組化子選單 - DEL 模式)
                # UI 回傳字串範例: "Delete Category [005] Network" 或 "Delete Command in [005] Network"
                local action=$(_factory_fzf_catedit_submenu "$temp_id" "$db_name" "DEL")
                
                if [ -z "$action" ]; then continue; fi

                # Branch A: 解散分類 (Delete Category)
                if [[ "$action" == *"Delete Category"* ]]; then
                    echo -e "\033[1;31m :: CRITICAL: Dissolving Category [$db_name] [$temp_id] \033[0m"
                    echo -e "\033[1;30m    All assets will be transferred to [Others] [999].\033[0m"
                    echo -ne "\033[1;33m    ›› TYPE 'CONFIRM' TO DEPLOY: \033[0m"
                    read -r confirm
                    echo -e ""
                    if [ "$confirm" == "CONFIRM" ]; then
                        if command -v _factory_auto_backup &> /dev/null; then _factory_auto_backup; fi
                        
                        _fac_safe_merge "999" "$temp_id"
                        break
                    else
                        _bot_say "system" "Operation Aborted."
                    fi

                # Branch B: 肅清指令 (Delete Command in...)
                elif [[ "$action" == *"Delete Command"* ]]; then
                    while true; do
                        # 進入分類內指令選擇 (紅色模式)
                        local raw_cmd=$(_factory_fzf_cmd_in_cat "$db_name" "DEL")
                        if [ -z "$raw_cmd" ]; then break; fi
                        
                        # 清洗與解析 (含 Sub Command 修正)
                        local clean_target=$(echo "$raw_cmd" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                        local t_com=$(echo "$clean_target" | awk '{print $1}')
                        local t_sub=""
                        if [[ "$clean_target" == *"'"* ]]; then
                            t_sub=$(echo "$clean_target" | awk -F"'" '{print $2}')
                        fi

                        echo -e "\033[1;31m :: WARNING: Deleting Node [$clean_target] from [$db_name]\033[0m"
                        echo -ne "\033[1;33m    ›› Confirm destruction? [Y/n]: \033[0m"
                        read -r choice
                        echo -e ""
                        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then continue; fi

                        if command -v _factory_auto_backup &> /dev/null; then _factory_auto_backup; fi

                        # 物理刪除
                        local target_file="$MUX_ROOT/app.csv.temp"
                        local temp_del="${target_file}.del"
                        awk -F, -v c="$t_com" -v s="$t_sub" '
                            {
                                csv_c=$5; gsub(/^"|"$/, "", csv_c)
                                csv_s=$6; gsub(/^"|"$/, "", csv_s)
                                is_target = 0
                                if (csv_c == c) {
                                    if (s == "" && csv_s == "") is_target = 1
                                    if (s != "" && csv_s == s) is_target = 1
                                }
                                if (is_target == 0 || NR == 1) print $0
                            }
                        ' "$target_file" > "$temp_del"
                        mv "$temp_del" "$target_file"
                        
                        # 序列重整 + 矩陣重組
                        _fac_sort_optimization
                        _fac_matrix_defrag
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
            echo -e "\033[1;33m :: Cycling Factory Power... \033[0m"
            sleep 0.5
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
            echo -e "${F_SUB} :: Unknown Directive: $cmd${F_RESET}"
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
        echo ""

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
            } else {
                # [Action] 合規：如果原本是 F，嘗試移除 F (可選)
                # 這裡暫不自動移除 F，讓使用者手動確認，或之後在 sort 移除
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

    echo -e "${F_GRAY} :: Migrating Node Matrix: [${source_id}] -> [${target_id}]...${F_RESET}"

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

    echo -e "${F_GRAY} :: Defragmenting Matrix...${F_RESET}"

    awk -F, -v OFS=, '
        NR==1 { print; next }

        {
            curr_cat = $1; gsub(/^"|"$/, "", curr_cat)
            curr_name = $3; gsub(/^"|"$/, "", curr_name)

            if (curr_cat != prev_cat) {
                seq = 1
                master_name = curr_name
                prev_cat = curr_cat
            } else {
                seq++
            }

            $2 = seq

            if (curr_name != master_name) {
                $3 = "\"" master_name "\""
            }

            print $0
        }
    ' "$target_file" > "$temp_file"

    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$target_file"
        echo -e "${F_GRE}    ›› Matrix Defragmented. Sequence aligned.${F_RESET}"
    else
        rm "$temp_file"
        echo -e "${F_ERR}    ›› Defrag Failed.${F_RESET}"
    fi
}

# 核心編輯路由器 (The Logic Router)
function _fac_edit_router() {
    local raw_selection="$1"
    local row_idx="$2"  # 知道要改哪一行 CSV
    local type="$3"     # 知道是 NA 還是 NB

    if [ -z "$raw_selection" ]; then return; fi

    # 1. 解析 Label (去除顏色代碼，抓冒號前面的字)
    local label=$(echo "$raw_selection" | sed 's/\x1b\[[0-9;]*m//g' | awk -F':' '{print $1}' | xargs)

    # 2. 狀態機判斷 (Case Switch)
    case "$label" in
        "Command")   _fac_update_cell "$row_idx" 5 "$(_factory_input_monitor "COM" "" "$type")" ;;
        "Command 2") _fac_update_cell "$row_idx" 6 "$(_factory_input_monitor "COM2" "" "$type")" ;;
        "HUD Name")  _fac_update_cell "$row_idx" 8 "$(_factory_input_monitor "HUDNAME" "" "$type")" ;;
        "UI Name")   _fac_update_cell "$row_idx" 9 "$(_factory_input_monitor "UINAME" "" "$type")" ;;
        
        # NA 區
        "Package")   _fac_update_cell "$row_idx" 10 "$(_factory_input_monitor "PKG" "" "$type")" ;;
        "Target")    _fac_update_cell "$row_idx" 11 "$(_factory_input_monitor "TARGET" "" "$type")" ;;
        "Flags")     _fac_update_cell "$row_idx" 17 "$(_factory_input_monitor "FLAG" "" "$type")" ;;
        
        # NB 區
        "Intent")    # 特殊處理：可能要跳子選單問 Head 還是 Body
             local sub=$(_factory_fzf_submenu "Head|Body")
             if [ "$sub" == "Head" ]; then _fac_update_cell "$row_idx" 12 "$(_factory_input_monitor "IHEAD" "" "$type")"; fi
             if [ "$sub" == "Body" ]; then _fac_update_cell "$row_idx" 13 "$(_factory_input_monitor "IBODY" "" "$type")"; fi
             ;;
        "URI")       
             # 智慧判斷邏輯放在這裡
             local val=$(_factory_input_monitor "URI/ENGINE" "" "$type")
             if [[ "$val" == *"%s"* ]]; then
                 _fac_update_cell "$row_idx" 20 "$val"
                 _fac_update_cell "$row_idx" 14 "\$__GO_TARGET"
             else
                 _fac_update_cell "$row_idx" 14 "$val"
                 _fac_update_cell "$row_idx" 20 ""
             fi
             ;;
             
        *) _bot_say "warn" "Field [$label] is read-only or not mapped." ;;
    esac
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
