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
            local next_comno=$(awk -F, '$1==999 {gsub(/^"|"$/, "", $2); if(($2+0) > max) max=$2} END {print max+1}' "$MUX_ROOT/app.csv.temp")
            
            # 防呆計算
            local com3_flag="N"
            local target_cat="999"
            local target_catname="\"Others\""
            
            if [ -z "$next_comno" ] || [ "$next_comno" -eq 1 ]; then
                # 如果是第一筆，或是計算失敗(awk回傳空)，設為 1
                next_comno=1
            fi
            
            # 如果計算出的數字極度不合理 (例如 awk 錯誤)，掛上 F 旗標
            if ! [[ "$next_comno" =~ ^[0-9]+$ ]]; then
                com3_flag="F"
                target_cat=""
                next_comno=""
                target_catname=""
            fi

            # 4. 生成暫時的指令名稱
            local ts=$(date +%s)
            local temp_cmd_name="ND${ts}"

            # 5. 建構 CSV 行 (Construct Row)
            local new_row=""
            
            case "$type_sel" in
                "Command NA")
                    # NA 模板: TYPE=NA, COM3=N 
                    new_row="${target_cat},${next_comno},${target_catname},\"NA\",\"${temp_cmd_name}\",,\"${com3_flag}\",,,,,,,,,,,,,"
                    ;;
                    
                "Command NB")
                    # NB 模板: TYPE=NB, COM3=N, URI=$__GO_TARGET, ENGINE=$SEARCH_GOOGLE
                    new_row="${target_cat},${next_comno},${target_catname},\"NB\",\"${temp_cmd_name}\",,\"${com3_flag}\",,,,,,,,\"$(echo '$__GO_TARGET')\",,,,,,\"$(echo '$SEARCH_GOOGLE')\""
                    ;;
                    
                "Command SYS"*) 
                    # 預留接口
                    _bot_say "error" "SYS Creation not implemented."
                    return
                    ;;
            esac

            # 6. 寫入檔案 (Append)
            if [ -n "$new_row" ]; then
                echo "$new_row" >> "$MUX_ROOT/app.csv.temp"
                
                while true; do
                    # 1. 顯示介面 (NEW 模式 -> 綠色邊框 + [Confirm] 按鈕)
                    local selection=$(_factory_fzf_detail_view "${current_edit_target}" "NEW")
                    
                    # 2. 若按 Esc，暫存並跳出 (或可選擇刪除暫存行，看你需求)
                    if [ -z "$selection" ]; then break; fi
                    
                    # 3. 進入路由器 (傳入 NEW 模式)
                    # 捕捉 stdout 以獲取 UPDATE_KEY，並捕捉 Exit Code
                    local router_out
                    router_out=$(_fac_edit_router "$selection" "${current_edit_target}" "NEW")
                    local router_code=$?
                    
                    # 顯示非控制訊息
                    echo "$router_out" | grep -v "UPDATE_KEY"

                    # 4. 處理回傳信號
                    if [ $router_code -eq 1 ]; then
                        # 收到 ROOM_CONFIRM (1) -> 驗收通過，正式結束新增流程
                        break
                    elif [ $router_code -eq 2 ]; then
                        # 收到 UPDATE_KEY (2) -> 使用者改了指令名，更新鎖定目標
                        local new_k=$(echo "$router_out" | awk -F: '{print $2}')
                        if [ -n "$new_k" ]; then current_edit_target="$new_k"; fi
                    fi
                done
                
                # 7. 執行排序與重整
                _fac_sort_optimization
                _fac_matrix_defrag
            fi
            ;;

        # : Edit Neural (Edit Command)
        "edit"|"comedit"|"comm")
            local view_state="EDIT"

            while true; do
                local selection=$(_factory_fzf_detail_view "$clean_target" "EDIT")
                if [ -z "$selection" ]; then break; fi

                # [Fix] 這裡要分兩步：1.捕捉輸出 2.捕捉狀態碼
                local router_out
                router_out=$(_fac_edit_router "$selection" "$clean_target" "EDIT")
                local router_code=$?  # <--- 抓住它！

                # 顯示路由器的文字回應 (過濾掉控制信號)
                echo "$router_out" | grep -v "UPDATE_KEY"

                # [Logic] 根據狀態碼行動
                if [ $router_code -eq 1 ]; then
                    # 收到 1 (CONFIRM) -> 退出編輯視窗
                    break 
                elif [ $router_code -eq 2 ]; then
                    # 收到 2 (UPDATE_KEY) -> 更新鎖定目標，不退出
                    local new_k=$(echo "$router_out" | awk -F: '{print $2}')
                    if [ -n "$new_k" ]; then clean_target="$new_k"; fi
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
                
                local temp_id=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')

                # Lookup authority ID/Name
                local db_data=$(awk -F, -v tid="$temp_id" 'NR>1 {gsub(/^"|"$/, "", $1); if($1==tid){gsub(/^"|"$/, "", $3); print $1 "|" $3; exit}}' "$MUX_ROOT/app.csv.temp")
                local cat_id=$(echo "$db_data" | awk -F'|' '{print $1}')
                local cat_name=$(echo "$db_data" | awk -F'|' '{print $2}')
                if [ -z "$cat_id" ]; then cat_id="XX"; cat_name="Unknown"; fi

                while true; do
                    # Level 2: Submenu (傳入 EDIT 模式)
                    local action=$(_factory_fzf_catedit_submenu "$cat_id" "$cat_name" "EDIT")
                    if [ -z "$action" ]; then break; fi

                    if echo "$action" | grep -q "Edit Name" ; then
                        _bot_say "warn" "Edit Name: Feature pending..."
                        
                    elif echo "$action" | grep -q "Edit Command in" ; then
                        # Branch B: Modify Commands in Category
                        while true; do
                            # 1. Select Command in Category
                            local raw_cmd=$(_factory_fzf_cmd_in_cat "$cat_name")
                            
                            if [ -z "$raw_cmd" ]; then break; fi
                            
                            local clean_target=$(echo "$raw_cmd" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')

                            # 2. Enter Edit Router Loop
                            while true; do
                                local selection=$(_factory_fzf_detail_view "$clean_target" "EDIT")
                                if [ -z "$selection" ]; then break; fi # Back to list
                                
                                local router_out
                                router_out=$(_fac_edit_router "$selection" "$clean_target" "EDIT")
                                local router_code=$?
                                
                                echo "$router_out" | grep -v "UPDATE_KEY"
                                
                                if [ $router_code -eq 2 ]; then
                                    local new_k=$(echo "$router_out" | awk -F: '{print $2}')
                                    if [ -n "$new_k" ]; then clean_target="$new_k"; fi
                                fi
                            done
                        done
                    fi
                done
            done
            ;;

        # : Break Neural (Delete Command)
        "del"|"comd"|"delcom")
            local view_state="DEL"

            while true; do
                # 1. Select Command
                local raw_target=$(_factory_fzf_menu "Select App to DELETE")
                if [ -z "$raw_target" ]; then break; fi

                local clean_target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                # 2. Review (Visual Confirm)
                # 使用 DEL 模式顯示紅框詳情，讓使用者看清楚要殺誰
                _factory_fzf_detail_view "$clean_target" "DEL"
                
                # 3. Final Confirmation
                echo -e "${F_WARN} :: WARNING :: COMMAND DELETE ACTION ::${F_RESET}"
                echo -ne "${F_WARN}    ›› Confirm your choice [Y/n]: ${F_RESET}"
                read -r conf
                
                if [[ "$conf" == "y" || "$conf" == "Y" ]]; then
                    # [Core] 執行精準刪除
                    _fac_delete_node "$clean_target"
                    echo -e "${F_GRAY}    ›› Target neutralized.${F_RESET}"
                    
                    # 4. Post-processing (重整矩陣)
                    _fac_sort_optimization
                    _fac_matrix_defrag
                else
                    echo -e "${F_GRAY}    ›› Operation cancelled.${F_RESET}"
                fi
            done
            ;;
        
        # : Delete Command via Category (Filter Search)
        "catd"|"catdel")
            local view_state="DEL"

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
                        echo -e "${F_GRAY}    ›› Operation Aborted.${F_RESET}"
                    fi

                # Branch B: 肅清指令 (Delete Command in...)
                elif [[ "$action" == *"Delete Command"* ]]; then
                    while true; do
                        # 1. 進入分類內指令選擇 (紅色模式)
                        local raw_cmd=$(_factory_fzf_cmd_in_cat "$db_name" "DEL")
                        if [ -z "$raw_cmd" ]; then break; fi
                        
                        # 2. 清洗目標字串 (只需清洗，不用自己拆解 COM/SUB，函數會自己拆)
                        local clean_target=$(echo "$raw_cmd" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')

                        # 3. 視覺確認
                        echo -e "\033[1;31m :: WARNING: Deleting Node [$clean_target] from [$db_name]\033[0m"
                        echo -ne "\033[1;33m    ›› Confirm destruction? [Y/n]: \033[0m"
                        read -r choice
                        echo -e ""
                        
                        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                            if command -v _factory_auto_backup &> /dev/null; then _factory_auto_backup; fi

                            _fac_delete_node "$clean_target"
                            
                            _bot_say "success" "Target neutralized."

                            # 4. 序列重整 + 矩陣重組
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

# 原子寫入函數 - Atomic Node Updater
function _fac_update_node() {
    # 用法: _fac_update_node "TARGET_KEY" "COL_INDEX" "NEW_VALUE"
    local target_key="$1"
    local col_idx="$2"
    local new_val="$3"
    local target_file="$MUX_ROOT/app.csv.temp"

    # 解析 Key (為了 awk 定位)
    local t_com=$(echo "$target_key" | awk '{print $1}')
    local t_sub=""
    if [[ "$target_key" == *"'"* ]]; then
        t_com=$(echo "$target_key" | awk -F"'" '{print $1}' | sed 's/[ \t]*$//')
        t_sub=$(echo "$target_key" | awk -F"'" '{print $2}')
    fi

    # 執行 awk 手術
    # 同時需要處理 "回傳新 Key"，改的是 Col 5 (Command) 或 Col 6 (Sub)，Key 會變
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

    # 解析 Key
    local t_com=$(echo "$target_key" | awk '{print $1}')
    local t_sub=""
    if [[ "$target_key" == *"'"* ]]; then
        t_com=$(echo "$target_key" | awk -F"'" '{print $1}' | sed 's/[ \t]*$//')
        t_sub=$(echo "$target_key" | awk -F"'" '{print $2}')
    fi

    # 使用 awk 進行雙重驗證過濾 (只有 COM 和 COM2 都對上才跳過不印)
    awk -F, -v tc="$t_com" -v ts="$t_sub" '
    {
        # 備份原始行以便輸出
        raw = $0
        
        # 清洗引號進行比對
        gsub(/^"|"$/, "", $5); c=$5
        gsub(/^"|"$/, "", $6); s=$6
        
        match_found = 0
        if (c == tc) {
            if (ts == "" && s == "") match_found = 1
            if (ts != "" && s == ts) match_found = 1
        }

        # 如果匹配，則跳過 (即刪除)
        if (match_found) {
            # 可以在 stderr 輸出刪除日誌
            print "Deleted: " c " " s > "/dev/stderr"
            next
        }
        
        # 沒匹配的行保留
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

    # 統一輸出格式
    echo -e "${F_GRAY}    :: Guide   : ${guide_text}${F_RESET}"
    if [ -n "$example_text" ]; then
        echo -e "${F_GRAY}    :: Format  : ${example_text}${F_RESET}"
    fi
    echo -e ""
}

# 核心編輯路由器 (The Logic Router)
function _fac_edit_router() {
    local raw_selection="$1"
    local target_key="$2"
    local view_mode="${3:-EDIT}" # 預設為 EDIT，防止未傳參
    
    # 房間變數
    local header_text="MODIFY PARAMETER"
    local border_color="208" # 預設橘色
    local prompt_color="208"
    
    case "$view_mode" in
        "NEW")
            header_text="CONFIRM CREATION"
            border_color="46"  # 鮮綠色
            prompt_color="46"
            ;;
        "DEL")
            header_text="DELETE PARAMETER"
            border_color="196" # 鮮紅色
            prompt_color="196"
            ;;
        "EDIT"|*)
            header_text="MODIFY PARAMETER :: "
            border_color="208" # Mux Orange
            prompt_color="208"
            ;;
    esac

    # 1. 切割出房間代碼
    local room_id=$(echo "$raw_selection" | awk -F'\t' '{print $2}')
    
    # 2. 狀態機分流
    case "$room_id" in
        "ROOM_INFO")
            # 點到標題，不做事
            ;;
        "ROOM_CMD")
            # [Logic] 解析當前 Key 為獨立變數
            local edit_com=$(echo "$target_key" | awk '{print $1}')
            local edit_sub=""
            if [[ "$target_key" == *"'"* ]]; then
                edit_com=$(echo "$target_key" | awk -F"'" '{print $1}' | sed 's/[ \t]*$//')
                edit_sub=$(echo "$target_key" | awk -F"'" '{print $2}')
            fi
            
            # [UI] 根據模式動態調整 Header 說明
            local guide_txt="Enter the CLI trigger command"

            while true; do
                # 準備 FZF 選單內容
                local menu_list=$(
                    echo -e "Command \t$edit_com"
                    if [ -z "$edit_sub" ]; then
                        echo -e "Sub Cmd \t\033[1;30m[Empty]\033[0m"
                    else
                        echo -e "Sub Cmd \t$edit_sub"
                    fi
                    echo -e "\033[1;32m[ Confirm ]\033[0m"
                )

                # [UI] 呼叫 FZF (套用動態顏色)
                local choice=$(echo -e "$menu_list" | fzf --ansi \
                    --height=6 \
                    --layout=reverse \
                    --border-label=" :: $header_text :: " \
                    --border=bottom \
                    --header-first \
                    --header=" :: $guide_txt ::" \
                    --prompt=" :: Command › " \
                    --info=hidden \
                    --pointer="››" \
                    --delimiter="\t" \
                    --with-nth=1,2 \
                    --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                    --color=info:240,prompt:$prompt_color,pointer:red,marker:208,border:$border_color,header:240 \
                    --bind="resize:clear-screen"
                )

                if [ -z "$choice" ]; then return 0; fi 

                if echo "$choice" | grep -q "Command"; then
                    _bot_say "action" "Edit Command Name:"
                    read -e -p "    › " -i "$edit_com" input_val
                    edit_com="${input_val:-$edit_com}" 

                elif echo "$choice" | grep -q "Sub Cmd"; then
                    _bot_say "action" "Edit Sub-Command (Empty to clear):"
                    read -e -p "    › " -i "$edit_sub" input_val
                    edit_sub="$input_val"

                elif echo "$choice" | grep -q "Confirm"; then
                    # 提交變更 (Atomic Update)
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
            _bot_say "system" "[Room] Entering HUD Editor..."
            # [TODO] _fac_room_hud "$target_key"
            ;;
        "ROOM_UI")
            _bot_say "system" "[Room] Entering UI Mode Selector..."
            ;;
        "ROOM_PKG")
            _bot_say "system" "[Room] Entering Package Editor..."
            ;;
        "ROOM_ACT")
            _bot_say "system" "[Room] Entering Action/Target Editor..."
            ;;
        "ROOM_FLAG")
            _bot_say "system" "[Room] Entering Flag Editor..."
            ;;
        "ROOM_INTENT")
            _bot_say "system" "[Room] Entering Intent Construction..."
            ;;
        "ROOM_URI")
            _bot_say "system" "[Room] Entering URI/Engine Editor..."
            ;;
        "ROOM_LOOKUP")
            _bot_say "action" "Launching Reference Tool..."
            apklist
            echo -e ""
            echo -e "${F_GRAY}    (Press Enter to return to Factory)${F_RESET}"
            read
            ;;
        "ROOM_CONFIRM")
            local check_data=$(awk -F, -v key="$target_key" '
                {
                    gsub(/^"|"$/, "", $5); c=$5
                    gsub(/^"|"$/, "", $6); s=$6
                    
                    # 簡單的比對邏輯：找出當前正在編輯的那個目標
                    # (這裡假設 target_key 是 "cmd" 或 "cmd 'sub'")
                    t_c=key; t_s=""
                    if (index(key, "'\''") > 0) {
                        split(key, a, "'\''"); t_c=a[1]; t_s=a[2];
                        gsub(/[ \t]*$/, "", t_c) # 去除尾端空格
                    }

                    if (c == t_c && s == t_s) {
                        print c "|" $10  # 輸出 Command|Package
                        exit
                    }
                }
            ' "$MUX_ROOT/app.csv.temp")

            local chk_com=$(echo "$check_data" | awk -F'|' '{print $1}')
            
            # [Validation] 核心欄位檢查
            if [ -z "$chk_com" ] || [ "$chk_com" == "[Empty]" ]; then
                _bot_say "error" "Command Name is required!"
                return 0 # 驗收失敗，留在迴圈繼續填
            else
                _bot_say "success" "Node Validated. Committing..."
                return 1 # 驗收通過，發出結束信號
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
