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
                         
                local clean_target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | awk -F']' '{print $2}' | awk '{print $1}')
                
                if [ -z "$clean_target" ]; then
                    clean_target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
                fi

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
                
                local clean_cat=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{$1=""; print $0}' | sed 's/^[ \t]*//')
                
                if [ -z "$clean_cat" ]; then 
                    clean_cat=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
                fi

                while true; do
                    local raw_cmd=$(_factory_fzf_cmd_in_cat "$clean_cat")
                    if [ -z "$raw_cmd" ]; then break; fi
                    
                    local clean_cmd=$(echo "$raw_cmd" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')

                    if [ "$view_state" == "VIEW" ]; then
                        _factory_fzf_detail_view "$clean_cmd" "VIEW" > /dev/null
                    fi
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
            _bot_say "error" "New Feature Waiting"
            ;;

        # : Edit Neural (Edit Command)
        "edit"|"comedit"|"comm")
            local view_state="EDIT"

            while true; do
                # Level 1: 選指令
                local raw_target=$(_factory_fzf_menu "Select App to Edit")
                if [ -z "$raw_target" ]; then break; fi
                
                # [Fix] 資料清洗 (同上)
                local clean_target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | awk -F']' '{print $2}' | awk '{print $1}')
                if [ -z "$clean_target" ]; then
                    clean_target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
                fi

                # Level 2: 進入 Detail (EDIT Mode)
                if [ "$view_state" == "EDIT" ]; then
                    # 這裡接收 detail_view 的回傳值 (選中的行)
                    local selection=$(_factory_fzf_detail_view "$clean_target" "EDIT")
                    
                    # 如果使用者有選擇 (非 ESC)，則進入路由 (待實作)
                    if [ -n "$selection" ]; then
                        # [TODO] _fac_edit_router "$selection" ...
                        : # No-op
                    fi
                fi
            done
            ;;

        # : Edit Category
        "catedit"|"cate")
            local view_state="EDIT"

            while true; do
                # Level 1: 選擇分類
                local raw_cat=$(_factory_fzf_cat_selector)
                if [ -z "$raw_cat" ]; then break; fi
                
                # [Step 1] 提取 ID (信任選單的第一欄絕對是 ID)
                local temp_id=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')

                # [Step 2] 權威查詢 (Database Lookup)
                # 使用 ID 去 CSV 抓取最乾淨的 ID 和 Name
                local db_data=$(awk -F, -v tid="$temp_id" '
                    NR>1 {
                        # 移除 CSV ID 的引號
                        cid=$1; gsub(/^"|"$/, "", cid)
                        
                        if (cid == tid) {
                            # 抓取 Name (第3欄)，移除引號
                            name=$3; gsub(/^"|"$/, "", name)
                            # 輸出格式: ID|Name
                            print cid "|" name
                            exit
                        }
                    }
                ' "$MUX_ROOT/app.csv.temp")

                # [Step 3] 解析查詢結果
                local cat_id=""
                local cat_name=""

                if [ -n "$db_data" ]; then
                    cat_id=$(echo "$db_data" | awk -F'|' '{print $1}')
                    cat_name=$(echo "$db_data" | awk -F'|' '{print $2}')
                else
                    # 如果查不到 (理論上不該發生)，使用備用方案
                    cat_id="XX"
                    # 嘗試從選單字串硬切
                    cat_name=$(echo "$raw_cat" | sed 's/\x1b\[[0-9;]*m//g' | awk '{$1=""; print $0}' | sed 's/^[ \t]*//')
                    if [ -z "$cat_name" ]; then cat_name="Unknown"; fi
                fi

                while true; do
                    # Level 2: 進入 Submenu (傳入正確的 ID 和 Name)
                    local action=$(_factory_fzf_catedit_submenu "$cat_id" "$cat_name")
                    if [ -z "$action" ]; then break; fi

                    # Level 3: 分歧處理
                    # 這裡用 grep 抓關鍵字，忽略顏色和括號
                    if echo "$action" | grep -q "Edit Name" ; then
                        # Branch A: 修改標題
                        _bot_say "warn" "Edit CATNAME [$cat_name] pending..."
                        
                    elif echo "$action" | grep -q "Edit Command in" ; then
                        # Branch B: 修改分類下的指令
                        while true; do
                            # 搜尋時使用權威 Name
                            local raw_cmd=$(_factory_fzf_cmd_in_cat "$cat_name")
                            if [ -z "$raw_cmd" ]; then break; fi
                            
                            local clean_cmd=$(echo "$raw_cmd" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')

                            if [ "$view_state" == "EDIT" ]; then
                                _factory_fzf_detail_view "$clean_cmd" "EDIT"
                            fi
                        done
                    fi
                done
            done
            ;;

        # : Load Neural (Test Command)
        "load"|"test") 
            echo -e "${F_SUB} :: Command Need Build${F_RESET}"
            ;;

        # : Break Neural (Delete Command)
        "del") 
            _bot_say "error" "New Feature Waiting"
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
