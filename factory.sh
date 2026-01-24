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
            # 1. 前置作業：選擇要修改的指令 (使用既有的 Detail View 選擇邏輯)
            # 這裡假設你會先呼叫一個選擇器拿到 target_line 或 row_index
            # 為了測試，我們先假設已經選好了一行，這裡我寫一個簡單的 fzf 選擇器範例
            # 實際整合時，請替換成你的標準選擇流程
            
            _factory_auto_backup
            
            # [模擬選擇流程] 讀取 CSV 產生選單
            local sel_line=$(awk -v FPAT='([^,]*)|("[^"]+")' 'NR>1 {gsub(/"/, "", $3); gsub(/"/, "", $5); print NR " " $3 " (" $5 ")"}' "$MUX_ROOT/app.csv.temp" | fzf --height=15 --reverse --header="Select Node to Edit")
            
            if [ -z "$sel_line" ]; then return; fi
            local row_idx=$(echo "$sel_line" | awk '{print $1}')
            
            # 2. 讀取該行目前的狀態 (Type, Values...)
            # 使用 awk 提取整行資料
            local current_row=$(sed "${row_idx}q;d" "$MUX_ROOT/app.csv.temp")
            
            # 解析 Type (第 4 欄)
            local type=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $4); print $4}')
            
            # 3. 呼叫 UI：顯示房間地圖
            local room_selection=$(_factory_fzf_edit_menu "$type")
            if [ -z "$room_selection" ]; then return; fi
            
            # 提取房間 ID (R1, R2...)
            local room_id=$(echo "$room_selection" | awk '{print $1}')

            # 4. 狀態機路由 (State Machine Routing)
            case "$room_id" in
                # === 共用房間 ===
                "R1") # Identity (CATNO:1, COMNO:2, TYPE:4, CATNAME:3)
                    # [Suite] 子選單
                    local sub_sel=$(echo -e "Edit Label (CATNAME)\nChange Category (Move)" | fzf --height=10 --reverse --header=" :: Identity Settings :: ")
                    if [[ "$sub_sel" == *"Edit Label"* ]]; then
                        local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $3); print $3}')
                        local new_val=$(_factory_input_monitor "CATNAME" "$curr_val" "$type")
                        _fac_update_cell "$row_idx" 3 "$new_val"
                    elif [[ "$sub_sel" == *"Change Category"* ]]; then
                        _bot_say "factory" "Category Mover module pending..."
                    fi
                    ;;

                "R2") # Command (COM:5, COM2:6)
                    # [Suite] 子選單
                    local sub_sel=$(echo -e "Primary (COM)\nSecondary (COM2)" | fzf --height=10 --reverse --header=" :: Command Aliases :: ")
                    if [[ "$sub_sel" == *"Primary"* ]]; then
                        local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $5); print $5}')
                        local new_val=$(_factory_input_monitor "COM" "$curr_val" "$type")
                        _fac_update_cell "$row_idx" 5 "$new_val"
                    elif [[ "$sub_sel" == *"Secondary"* ]]; then
                        local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $6); print $6}')
                        local new_val=$(_factory_input_monitor "COM2" "$curr_val" "$type")
                        _fac_update_cell "$row_idx" 6 "$new_val"
                    fi
                    ;;

                "R3") # HUD (HUDNAME:8) -> [Single]
                    local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $8); print $8}')
                    local new_val=$(_factory_input_monitor "HUDNAME" "$curr_val" "$type")
                    _fac_update_cell "$row_idx" 8 "$new_val"
                    ;;

                "R4") # UI (UINAME:9) -> [Single]
                    local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $9); print $9}')
                    local new_val=$(_factory_input_monitor "UINAME" "$curr_val" "$type")
                    _fac_update_cell "$row_idx" 9 "$new_val"
                    ;;

                # === NA 專屬 ===
                "R5") # NA: PKG(10) / NB: Intent(12,13)
                    if [ "$type" == "NA" ]; then
                        local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $10); print $10}')
                        local new_val=$(_factory_input_monitor "PKG" "$curr_val" "NA")
                        _fac_update_cell "$row_idx" 10 "$new_val"
                    else # NB
                        local sub_sel=$(echo -e "Action Head (Namespace)\nAction Body (Event)" | fzf --height=10 --reverse --header=" :: Intent Settings :: ")
                        if [[ "$sub_sel" == *"Head"* ]]; then
                            local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $12); print $12}')
                            local new_val=$(_factory_input_monitor "IHEAD" "$curr_val" "NB")
                            _fac_update_cell "$row_idx" 12 "$new_val"
                        elif [[ "$sub_sel" == *"Body"* ]]; then
                            local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $13); print $13}')
                            local new_val=$(_factory_input_monitor "IBODY" "$curr_val" "NB")
                            _fac_update_cell "$row_idx" 13 "$new_val"
                        fi
                    fi
                    ;;
                
                "R6") # NA: Target(11) / NB: URI(14) & Engine(20)
                    if [ "$type" == "NA" ]; then
                        local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $11); print $11}')
                        local new_val=$(_factory_input_monitor "TARGET" "$curr_val" "NA")
                        _fac_update_cell "$row_idx" 11 "$new_val"
                    else # NB Smart URI
                        # 讀取目前顯示值 (優先顯示 Engine)
                        local curr_uri=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $14); print $14}')
                        local curr_eng=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $20); print $20}')
                        local display_val="$curr_uri"
                        if [ -n "$curr_eng" ]; then display_val="$curr_eng"; fi
                        
                        local new_val=$(_factory_input_monitor "URI/ENGINE" "$display_val" "NB")
                        
                        # 智慧判斷邏輯
                        if [[ "$new_val" == *"%s"* ]]; then
                            _fac_update_cell "$row_idx" 20 "$new_val"      # Engine
                            _fac_update_cell "$row_idx" 14 "\$__GO_TARGET" # URI
                        else
                            _fac_update_cell "$row_idx" 14 "$new_val"      # URI
                            _fac_update_cell "$row_idx" 20 ""              # Clear Engine
                        fi
                    fi
                    ;;

                "R7") # NA: Flags(17) / NB: Category(16)
                    if [ "$type" == "NA" ]; then
                        local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $17); print $17}')
                        local new_val=$(_factory_input_monitor "FLAG" "$curr_val" "NA")
                        _fac_update_cell "$row_idx" 17 "$new_val"
                    else # NB
                        local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $16); print $16}')
                        local new_val=$(_factory_input_monitor "CATE" "$curr_val" "NB")
                        _fac_update_cell "$row_idx" 16 "$new_val"
                    fi
                    ;;
                
                # === NB 剩餘房間 (R8-R11) ===
                "R8") # NB: Mime(15)
                    local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $15); print $15}')
                    local new_val=$(_factory_input_monitor "MIME" "$curr_val" "NB")
                    _fac_update_cell "$row_idx" 15 "$new_val"
                    ;;

                "R9") # NB: Extra(19) [Suite for EX/EXTRA]
                    local sub_sel=$(echo -e "Extra Key (EX)\nExtra Value (EXTRA)" | fzf --height=10 --reverse --header=" :: Extra Data :: ")
                    if [[ "$sub_sel" == *"Key"* ]]; then
                        local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $18); print $18}')
                        local new_val=$(_factory_input_monitor "EX" "$curr_val" "NB")
                        _fac_update_cell "$row_idx" 18 "$new_val"
                    elif [[ "$sub_sel" == *"Value"* ]]; then
                        local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $19); print $19}')
                        local new_val=$(_factory_input_monitor "EXTRA" "$curr_val" "NB")
                        _fac_update_cell "$row_idx" 19 "$new_val"
                    fi
                    ;;

                "R10") # NB: Package(10)
                    local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $10); print $10}')
                    local new_val=$(_factory_input_monitor "PKG" "$curr_val" "NB")
                    _fac_update_cell "$row_idx" 10 "$new_val"
                    ;;

                "R11") # NB: Target(11)
                    local curr_val=$(echo "$current_row" | awk -v FPAT='([^,]*)|("[^"]+")' '{gsub(/"/, "", $11); print $11}')
                    local new_val=$(_factory_input_monitor "TARGET" "$curr_val" "NB")
                    _fac_update_cell "$row_idx" 11 "$new_val"
                    ;;
            esac
            
            _bot_say "success" "Matrix updated. Please verify."
            ;;

        # : Load Neural (Test Command)
        "load"|"test") 
            echo -e "${F_SUB} :: Command Need Build${F_RESET}"
            ;;

        # : Break Neural (Delete Command)
        "del") 
            # 1. 選擇目標 (Target Acquisition)
            # 使用 awk 預覽資料，格式: "LineNo [CAT] COM (PKG)"
            # NR>1 跳過標題列
            local sel_line=$(awk -v FPAT='([^,]*)|("[^"]+")' '
                NR>1 {
                    gsub(/"/, "", $3); # CATNAME
                    gsub(/"/, "", $5); # COM
                    gsub(/"/, "", $10); # PKG
                    if ($5=="") $5="[Empty]"
                    printf "%3d  %-15s %-10s %s\n", NR, "[" $3 "]", $5, $10
                }
            ' "$MUX_ROOT/app.csv.temp" | fzf --height=20 --reverse --header=" :: Select Node to DELETE :: " --prompt=" TERMINATE › " --pointer="XX")

            if [ -z "$sel_line" ]; then return; fi
            
            # 提取行號 (第一欄)
            local row_idx=$(echo "$sel_line" | awk '{print $1}')
            local target_name=$(echo "$sel_line" | awk '{print $3 " " $4}')

            # 2. 最終確認 (Final Confirmation)
            # 這裡用一個簡單的 read 確認，防止手滑
            _bot_say "warn" "WARNING: Deleting node $target_name at line $row_idx."
            echo -e "\033[1;31m    Are you sure? (Type 'yes' to confirm)\033[0m"
            read -p "    › " confirm

            if [ "$confirm" == "yes" ]; then
                # 3. 執行刪除 (Execution)
                # 使用 sed 刪除指定行
                sed -i "${row_idx}d" "$MUX_ROOT/app.csv.temp"
                
                _bot_say "success" "Node terminated."
                
                # 4. 系統修復 (Maintenance)
                # 重新排序 ID，填補空缺
                _fac_maintenance
            else
                _bot_say "factory" "Deletion canceled."
            fi
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

        "ui")
            # 定義測試項目
            local test_menu="1. Template Selector (Add New)\n2. Detail View (Mock NEW Mode)\n3. Edit Field (FZF Universal)\n4. Input Monitor (CLI Standard)"
            
            # 呼叫 FZF 選單
            local selected=$(echo -e "$test_menu" | fzf \
                --height=15 --layout=reverse --border=bottom \
                --header=" :: UI Component Lab :: " \
                --prompt=" Run Test › " \
                --pointer="››" \
                --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
                --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240)

            # 根據選擇執行測試
            case "$selected" in
                *"1."*)
                    # 測試：類型選擇器
                    local res=$(_factory_fzf_template_selector)
                    echo -e "\n\033[1;33m[Result]\033[0m Raw Selection: $res"
                    ;;
                
                *"2."*)
                    # 測試：詳細資料檢視 (模擬 NEW 模式)
                    # 注入假資料到 temp 檔以便 awk 讀取
                    local mock_beacon="_UI_TEST_"
                    # 建立一個暫時的 NA 節點
                    local mock_row="\"999\",\"99\",\"[NEW]\",\"NA\",\"$mock_beacon\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\""
                    echo "$mock_row" >> "$MUX_ROOT/app.csv.temp"
                    
                    # 啟動 UI
                    _factory_fzf_detail_view "$mock_beacon" "NEW"
                    local status=$?
                    
                    # 清理假資料
                    sed -i '/_UI_TEST_/d' "$MUX_ROOT/app.csv.temp"
                    
                    if [ $status -eq 0 ]; then
                        echo -e "\n\033[1;32m[Result]\033[0m Confirmed (Exit Code 0)"
                    else
                        echo -e "\n\033[1;31m[Result]\033[0m Canceled (Exit Code $status)"
                    fi
                    ;;
                
                *"3."*)
                    # 測試：通用修改面板 (FZF)
                    # 模擬修改 NA 的 Package 欄位 (測試紅色警告)
                    local res=$(_factory_fzf_edit_field "Package" "[Empty]" "NA")
                    echo -e "\n\033[1;33m[Result]\033[0m User Input: $res"
                    ;;
                
                *"4."*)
                    # 測試：戰術輸入監視器 (CLI)
                    # 模擬修改 NB 的 Intent 欄位 (測試紅色警告與說明文字)
                    # 這裡為了測試方便，暫時不寫入，只顯示回傳值
                    local res=$(_factory_input_monitor "IHEAD" "android.intent.action" "NB")
                    echo -e "\n\033[1;33m[Result]\033[0m User Input: $res"
                    ;;
            esac
            
            # 測試結束後暫停，方便查看結果
            if [ -n "$selected" ]; then
                echo -e "\n\033[1;30mPress Enter to return...\033[0m"
                read
            fi
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
        
        if [ -f "$temp_file" ]; then
            rm -f "$temp_file"
        fi
    else
         _bot_say "error" "Sandbox integrity failed."
         return 1
    fi
    
    echo ""
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
    local main_target="$MUX_ROOT/app.csv.temp"
    local other_targets=("$MUX_ROOT/system.csv" "$MUX_ROOT/vendor.csv")
    
    echo -e "${F_MAIN} :: Initiating Mechanism Maintenance (Data Integrity)...${F_RESET}"
    
    # 大破修復 - for app.csv.temp 
    if [ -f "$main_target" ]; then
        echo -e "${F_GRAY}    ›› Deep Scanning: $(basename "$main_target")...${F_RESET}"

        if [ -n "$(tail -c 1 "$main_target")" ]; then echo "" >> "$main_target"; fi

        local temp_out="${main_target}.chk"
        
        awk -v FPAT='([^,]*)|("[^"]+")' -v OFS=',' '
        BEGIN {
            C_RED="\033[1;31m"; C_YEL="\033[1;33m"; C_RES="\033[0m"
        }
        
        # 學習階段 (建立分類映射表)
        NR > 1 {
            lines[NR] = $0
            c_no = $1; gsub(/^"|"$/, "", c_no)
            c_name = $3; gsub(/^"|"$/, "", c_name)
            if (c_no != "" && c_name != "" && c_name != "Others") {
                cat_map[c_no] = c_name
            }
        }

        # 執行階段 (檢查與修正)
        END {
            getline header < FILENAME
            print header
            
            for (i = 2; i <= NR; i++) {
                $0 = lines[i]
                status = "OK"
                msg = ""
                flag_lock = "" # 指令標記
                
                # 欄位解析
                cat_no = $1;  gsub(/^"|"$/, "", cat_no)
                type   = $4;  gsub(/^"|"$/, "", type)
                com    = $5;  gsub(/^"|"$/, "", com)
                com2   = $6;  gsub(/^"|"$/, "", com2)
                pkg    = $10; gsub(/^"|"$/, "", pkg)
                target = $11; gsub(/^"|"$/, "", target)
                ihead  = $12; gsub(/^"|"$/, "", ihead)
                ibody  = $13; gsub(/^"|"$/, "", ibody)
                
                # 進階參數解析
                flg    = $17; gsub(/^"|"$/, "", flg)
                ex     = $18; gsub(/^"|"$/, "", ex)
                extra  = $19; gsub(/^"|"$/, "", extra)
                
                # 指令結構檢查
                if (com == "" && com2 != "") {
                    status = "ERR"; flag_lock = "F"; msg = "Invalid Command Structure (COM2 only)";
                }

                # AM 核心參數檢查
                if (type == "NA") {
                    # NA: Explicit Intent (PKG + CLASS)
                    if (pkg == "" || target == "") {
                        status = "ERR"; flag_lock = "F"; msg = "Type NA missing PKG/TARGET";
                    }
                } else if (type == "NB" || type == "SYS") {
                    if (ihead == "" || ibody == "") {
                        status = "ERR"; flag_lock = "F"; msg = "Type " type " missing ACTION (IHEAD+IBODY)";
                    }
                }

                # EX-EXTRA 參數耦合檢查
                if ( (ex == "" && extra != "") || (ex != "" && extra == "") ) {
                    status = "ERR"; flag_lock = "F"; msg = "Broken Parameter Coupling (EX/EXTRA mismatch)";
                }

                # Flags 格式檢查
                if (flg != "") {
                    if (flg !~ /^[0-9]+$/ && flg !~ /^0x[0-9a-fA-F]+$/) {
                        status = "ERR"; flag_lock = "F"; msg = "Invalid Flag Format (Must be Int or Hex)";
                    }
                }

                # 矩陣排序檢查
                cat_fix = 0
                if (cat_no == "") {
                    status = "ERR"; flag_lock = "F"; msg = "Missing Category Index";
                    cat_fix = 1;
                } else if (cat_map[cat_no] == "") {
                    msg = "Unknown Category ID: " cat_no " -> Auto-classified to Others";
                    if (status == "OK") { 
                        print C_YEL "    ›› [INFO] Line " i ": " msg C_RES > "/dev/stderr"
                    }
                    cat_fix = 1;
                } else {
                    # 自動校正分類名稱
                    $3 = "\"" cat_map[cat_no] "\""
                }

                # 執行分類修復
                if (cat_fix == 1) {
                    $1 = 999
                    $3 = "\"Others\""
                }

                # COM3寫入
                if (status == "ERR") {
                    $7 = "\"F\""
                    print C_RED "    ›› [ERR] Line " i ": " msg " -> Locked (F)" C_RES > "/dev/stderr"
                } else if (status == "WARN") {
                    $7 = "\"W\""
                    print C_YEL "    ›› [WARN] Line " i ": " msg " -> Warning (W)" C_RES > "/dev/stderr"
                } else {
                    $7 = "" # 清空標記
                }
                
                print $0
            }
        }
        ' "$main_target" > "$temp_out"

        # 排序整理 (Sort)
        local header=$(head -n 1 "$temp_out")
        local body=$(tail -n +2 "$temp_out" | sort -t',' -k1,1n -k2,2n)
        
        echo "$header" > "$main_target"
        echo "$body" >> "$main_target"
        rm -f "$temp_out"
        
        echo -e "${F_WARN}    ›› Integrity Check & Sort Complete. ✅${F_RESET}"
    fi

    # 基礎維護 - for system/vendor
    for file in "${other_targets[@]}"; do
        if [ -f "$file" ]; then
            if [ -n "$(tail -c 1 "$file")" ]; then echo "" >> "$file"; fi
            local row_count=$(wc -l < "$file")
            if [ "$row_count" -gt 1 ]; then
                local header=$(head -n 1 "$file")
                local body_raw=$(tail -n +2 "$file")
                local body_sorted=$(echo "$body_raw" | sort -t',' -k1,1n -k2,2n)
                
                if [ "$body_raw" != "$body_sorted" ]; then
                     echo "$header" > "$file"
                     echo "$body_sorted" >> "$file"
                fi
            fi
        fi
    done

    sleep 0.5
    echo -e ""
    _bot_say "factory" "Mechanism maintenance complete, Commander."
}

# 內部工具：安全更新 CSV 單一儲存格 (保持 20 欄位引號結構)
# 用法: _fac_update_cell "行號" "欄位號" "新數值"
function _fac_update_cell() {
    local row_idx="$1"
    local col_idx="$2"
    local new_val="$3"
    local target_file="$MUX_ROOT/app.csv.temp"

    # 使用 awk 精準替換並重建整行，確保引號不遺失
    awk -v r="$row_idx" -v c="$col_idx" -v v="$new_val" -v FPAT='([^,]*)|("[^"]+")' '
    BEGIN { OFS="," }
    NR == r {
        # 移除舊數值的引號 (如果有的話) 以便乾淨處理，這裡直接強制覆寫
        # 替換指定欄位，並強制加上雙引號
        $c = "\"" v "\""
        
        # 重建整行輸出 (確保每一欄都有引號，防止 awk 輸出時遺漏)
        for(i=1; i<=NF; i++) {
            # 如果欄位本身沒有引號，補上 (針對 awk 修改後的欄位)
            if ($i !~ /^".*"$/) $i = "\"" $i "\""
        }
    }
    { print $0 }
    ' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
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
