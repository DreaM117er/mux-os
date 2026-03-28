# tower.sh - Mux-OS 指揮塔模組 (The Command Tower)
# 權限：Lv.16 Architect & The Clumsy Co-pilot

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

# 指令劫持器 (Bypass Guard)
function _bypass_guard() {
    # 接收傳入的完整指令
    local raw_input="$*"
    if [ -z "$raw_input" ]; then return 1; fi

    local main_cmd="${raw_input%% *}"
    # 比對指令
    if [ "${#raw_input}" -gt "${#main_cmd}" ]; then
        eval "$raw_input"
        return 0
    else
        return 1
    fi
}

# 高精密文本切割機 (The High-Precision Text Cutter)
function _tct_tns_probe() {
    local input_cmd="$1"
    if [ -z "$input_cmd" ]; then return 1; fi

    # 指令解構：分離主指令與子指令
    local main_cmd="${input_cmd%% *}"
    local sub_cmd="${input_cmd#* }"
    [ "$main_cmd" == "$sub_cmd" ] && sub_cmd=""

    local help_text=""
    local cmd_type=""
    export COLUMNS=200
    
    # 探測主指令的底層物理型態
    cmd_type=$(type -t "$main_cmd" 2>/dev/null)

    # 遇到大魔王指令：切換模式
    local parse_mode="PRECISION"
    if [[ "$main_cmd" =~ ^(cd|ls|tar|find|sed|grep|awk)$ ]]; then
        parse_mode="GLOBAL"
    fi

    # 前置分類路由器
    case "$main_cmd" in
        pkg)
            # pkg 只吃 help，且必須繞過任何子指令干涉
            help_text=$(command pkg help 2>&1)
            ;;
        git)
            # git 必須使用 -h，並精準抓取子指令
            if [ -n "$sub_cmd" ]; then
                help_text=$(command git $sub_cmd -h 2>&1)
            else
                help_text=$(command git -h 2>&1)
            fi
            ;;
        cd)
            # help $main_cmd
            help_text=$(help cd 2>&1)
            ;;

        *)
            # 泛用型探針
            if [ "$cmd_type" == "builtin" ]; then
                # Bash 內建指令專線
                help_text=$(help "$input_cmd" 2>&1)
            else
                # 外部指令或被劫持的 function (強制使用 command 穿透)
                help_text=$(command $input_cmd --help 2>&1)
                
                # 錯誤檢閱機制 (Error Checking Fallback)
                if [ ${#help_text} -lt 150 ]; then
                    if [[ "$help_text" =~ (illegal|invalid|unrecognized|not\ found|unknown) ]] || [ ${#help_text} -lt 50 ]; then
                        local alt_help=$(command $input_cmd help 2>&1 < /dev/null)
                        
                        if [ ${#alt_help} -gt 50 ] && [[ ! "$alt_help" =~ (illegal|invalid|unrecognized|unknown) ]]; then
                            help_text="$alt_help"
                        else
                            # 最後的波紋：嘗試 -h
                            local alt_help2=$(command $input_cmd -h 2>&1 < /dev/null)
                            if [ ${#alt_help2} -gt 50 ]; then
                                help_text="$alt_help2"
                            fi
                        fi
                    fi
                fi
            fi

            if [ -z "$help_text" ] || [[ "$help_text" == *"not found"* ]]; then
                echo -e " \033[1;30m[Empty]\033[0m   No parameters found."
                return
            fi
            ;;
    esac
    
    # 切割刀法邏輯
    local parsed_params
    parsed_params=$(echo "$help_text" | awk -v c_flag="\033[1;33m" -v c_rst="\033[0m" -v p_mode="$parse_mode" '
        BEGIN {
            idx_long = 0
            idx_short = 0
            idx_cmd = 0
        }
        {
            # 實體消毒
            gsub(/\x1b\[[0-9;]*[a-zA-Z]/, "")
            gsub(/.\x08/, "")
            
            # 指令過濾
            match($0, /^[ \t]+/)
            indent_len = RLENGTH
            if (indent_len > 0 && indent_len <= 3 && match($0, /^[ \t]+[a-zA-Z0-9_:-]+[ \t][ \t]+/)) {
                cmd_cand = substr($0, RSTART, RLENGTH)
                sub(/^[ \t]+/, "", cmd_cand)
                sub(/[ \t]+$/, "", cmd_cand)
                if (cmd_cand != "" && cmd_cand !~ /^-/ && cmd_cand !~ /:$/ && cmd_cand !~ /^[0-9]+$/ && tolower(cmd_cand) !~ /^(usage|options|examples|commands|gnu|oldgnu|pax|posix|ustar|v7|none|size|time|auto|always|never)$/) {
                    if (!seen[cmd_cand]) { seen[cmd_cand] = 1; buf_cmd[++idx_cmd] = cmd_cand }
                }
            }
            
            # 軌道分流
            if (p_mode == "GLOBAL") {
                # 全域無差別切割機
                n = split($0, arr, "[ \t]+|,[ \t]+")
                for (i=1; i<=n; i++) {
                    item = arr[i]
                    sub(/[,;:.)]$/, "", item)
                    gsub(/[\047"‘’`]/, "", item)
                    
                    if (item ~ /^-+[a-zA-Z0-9@]/) {
                        if (!seen[item]) {
                            seen[item] = 1
                            if (item ~ /^--/) { buf_long[++idx_long] = item } else { buf_short[++idx_short] = item }
                        }
                    }
                }
            } else {
                # 高精密鍊式切割機
                if ($0 ~ /^[ \t][ \t]+-+/) {
                    temp_line = $0
                    while (temp_line != "") {
                        sub(/^[ \t]+/, "", temp_line)
                        if (temp_line ~ /^-+/) {
                            match(temp_line, /^-+[^ \t,]+/)
                            if (RLENGTH > 0) {
                                sub(/=.*/, "", item)
                                sub(/[,;:.)]$/, "", item)
                                gsub(/[\047"‘’`]/, "", item)
                                
                                if (item ~ /^-+[a-zA-Z0-9@]/) {
                                    if (!seen[item]) {
                                        seen[item] = 1
                                        if (item ~ /^--/) { buf_long[++idx_long] = item } else { buf_short[++idx_short] = item }
                                    }
                                }
                                temp_line = substr(temp_line, RLENGTH + 1)
                                sub(/^[ \t]+/, "", temp_line)
                                if (temp_line ~ /^,/) { sub(/^,[ \t]*/, "", temp_line) } else { break }
                            } else { break }
                        } else { break }
                    }
                }
            }
        }
        END {
            for (i=1; i<=idx_cmd; i++) printf(" %s%s%s\n", c_flag, buf_cmd[i], c_rst)
            for (i=1; i<=idx_short; i++) printf(" %s%s%s\n", c_flag, buf_short[i], c_rst)
            for (i=1; i<=idx_long; i++) printf(" %s%s%s\n", c_flag, buf_long[i], c_rst)
        }
    ')

    if [ -n "$parsed_params" ]; then echo -e "$parsed_params"
    else echo -e " \033[1;30m[Empty]\033[0m   No parameters found."; fi
}

# 戰術指令導航 (Single-Stage HUD & Zone Isolation Catch)
function _tct_tns_macro() {
    # 截取輸入
    local target_cmd=""
    target_cmd=$(echo "${READLINE_LINE:0:$READLINE_POINT}" | awk -F'[;|&]+' '{print $NF}' | awk '{
        cmd = ""
        for(i=1; i<=NF; i++) {
            if ($i ~ /^(cmt|sudo|command|nohup|time)$/) continue;
            if ($i ~ /^-/ || $i ~ /[><]/) break;
            if (cmd == "") cmd = $i; else cmd = cmd " " $i
        }
        print cmd
    }')

    target_cmd=$(echo "$target_cmd" | sed 's/^[ \t]*//;s/[ \t]*$//')
    local params=""

    # 狀態分流
    if [ -z "$target_cmd" ]; then
        params=" \033[1;30m[Empty]\033[0m   No command specified."
        target_cmd="Null"
    else
        params=$(_tct_tns_probe "$target_cmd")
        if [ -z "$params" ]; then params=" \033[1;30m[Empty]\033[0m   No parameters found."; fi
    fi

    # 動態高度計算
    local line_count=$(echo -ne "$params" | wc -l)
    local dynamic_height=$(( line_count + 4 ))
    if [ "$dynamic_height" -gt 12 ]; then dynamic_height=12; fi

    # 展開參數雷達
    local selected
    selected=$(echo -e "$params" | fzf --ansi \
            --height="$dynamic_height" \
            --layout=reverse \
            --prompt=" :: cmd › $target_cmd › " \
            --header=" :: Enter to Choose, Esc to exit :: " \
            --info=hidden \
            --pointer="››" \
            --border=bottom \
            --border-label=" :: PARAMETER HUD :: " \
            --color="fg:white,bg:-1,hl:211,fg+:white,bg+:235,hl+:211,info:240" \
            --color="pointer:red,border:211,header:240,prompt:211"
            )

    # 寫回終端機
    if [ -n "$selected" ]; then
        local clean_flag=$(echo "$selected" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}' | sed 's/^[ \t]*//;s/[ \t]*$//;s/,$//')
        
        if [[ "$clean_flag" == *Empty* ]] || [ -z "$clean_flag" ]; then return; fi
        
        if [ -n "$clean_flag" ]; then
            local left_part="${READLINE_LINE:0:$READLINE_POINT}"
            local right_part="${READLINE_LINE:$READLINE_POINT}"
            
            if [[ -n "$left_part" ]] && [[ "$left_part" != *" " ]]; then left_part="${left_part} "; fi

            READLINE_LINE="${left_part}${clean_flag} ${right_part}"
            READLINE_POINT=$((${#left_part} + ${#clean_flag} + 1))
        fi
    fi
}

# 戰術兵器模式選擇器 (Tactical Weapon Mode Selector)
function _tct_mode_selector() {
    local weapon_type="$1"
    local menu_items=""
    local border_lbl=""
    local border_color=""
    
    case "$weapon_type" in
        "cp")
            border_lbl="CLONER MODE"
            border_color="33"
            menu_items+="${C_YELLOW}[-i]${C_RESET} Interactive (Safe)\n"
            menu_items+="${C_RED}[-f]${C_RESET} Force Overwrite\n"
            menu_items+="${C_PINKMEOW}[-r]${C_RESET} Recursive (Folder Copy)\n"
            menu_items+="${C_GREEN}[-a]${C_RESET} Archive (Preserve ALL)\n"
            ;;
        "mv")
            border_lbl="RELOCATOR MODE"
            border_color="220"
            menu_items+="${C_YELLOW}[-i]${C_RESET} Interactive (Safe)\n"
            menu_items+="${C_RED}[-f]${C_RESET} Force Overwrite\n"
            ;;
        "rm")
            border_lbl="DESTRUCTOR MODE"
            border_color="196"
            menu_items+="${C_YELLOW}[-i]${C_RESET} Interactive\n"
            menu_items+="${C_YELLOW}[-f]${C_RESET} Force\n"
            menu_items+="${C_RED}[-r]${C_RESET} Recursive\n"
            menu_items+="${C_RED}\033[5m[rf]\033[0m${C_RESET} Nuke\n"
            ;;
    esac

    local line_count=$(echo -ne "$menu_items" | wc -l)
    local dynamic_height=$(( line_count + 4 ))

    local selected=$(echo -ne "$menu_items" | fzf --ansi \
        --height="$dynamic_height" \
        --layout=reverse \
        --prompt=" :: Select Mode › " \
        --info=hidden \
        --pointer="››" \
        --border=bottom \
        --border-label=" :: $border_lbl :: " \
        --header=" :: Enter to Select, Esc to Abort :: " \
        --color="fg:white,bg:-1,hl:${border_color},fg+:white,bg+:235,hl+:${border_color},info:240" \
        --color="pointer:red,border:${border_color},header:240,prompt:${border_color}" \
        --bind="resize:clear-screen"
    )

    if [ -n "$selected" ]; then
        echo "$selected" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}' | tr -d '[]'
    fi
}

# 戰術操作艙子模組 (Action Menu Sub-Module)
function _tct_file_action_menu() {
    local clean_target="$1"
    
    while true; do
        local action_items=""
        
        # 動態判定
        if [ -d "$clean_target" ]; then
            action_items+="${C_PINKMEOW}[cd]${C_RESET} Enter Directory '$clean_target'\n"
        elif [ -f "$clean_target" ]; then
            action_items+="${C_GREEN}[dv]${C_RESET} Open Data Viewer\n"
            action_items+="${C_CYAN}[ct]${C_RESET} View Content '$clean_target'\n"
            action_items+="${C_YELLOW}[nn]${C_RESET} Edit File '$clean_target'\n"
        fi
        
        # 共用戰術兵器庫
        action_items+="${C_GREEN}[cp]${C_RESET} Tactical Cloner\n"
        action_items+="${C_ORANGE}[mv]${C_RESET} Tactical Relocator\n"
        action_items+="${C_RED}[rm]${C_RESET} Tactical Destructor\n"
        
        local ui_prompt=" :: Action › $clean_target › "
        [ "$CMT_COMMAND" == "true" ] && ui_prompt=" :: cmt › Action › $clean_target › "
        
        # 呼叫TCT模組
        local action_raw=$(_ui_tct_nav_radar "$action_items" "$ui_prompt" "10" "TARGET OPERATIONS" "220" " :: Esc to Return ::")
        
        local action_sel=$(echo "$action_raw" | tail -n +2 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
        
        if [ -z "$action_sel" ]; then return 0; fi 
        
        # 火力分發
        if [[ "$action_sel" == "[cd]"* ]]; then
            builtin cd "$clean_target"
            _update_setting "TCT_RADAR_HIDDEN" "false"
            return 3
        elif [[ "$action_sel" == "[dv]"* ]]; then
            _tower_fzf_detail_view "$clean_target"
            continue
        elif [[ "$action_sel" == "[ct]"* ]]; then
            echo -e "${C_CYAN} :: READING: $clean_target ${C_RESET}"
            command cat "$clean_target" | less -R -F -X
            break
        elif [[ "$action_sel" == "[nn]"* ]]; then
            nano "$clean_target"
            break
        elif [[ "$action_sel" == "[cp]"* ]]; then
            local run_mode=$(_tct_mode_selector "cp")
            if [ -n "$run_mode" ]; then
                export CMT_COMMAND="true"
                export TCT_SINGLE_TARGET="$clean_target"
                __core_cp "-$run_mode"
                unset TCT_SINGLE_TARGET
                unset CMT_COMMAND
            fi
            break
        elif [[ "$action_sel" == "[mv]"* ]]; then
            local run_mode=$(_tct_mode_selector "mv")
            if [ -n "$run_mode" ]; then
                export CMT_COMMAND="true"
                export TCT_SINGLE_TARGET="$clean_target"
                __core_mv "-$run_mode"
                unset TCT_SINGLE_TARGET
                unset CMT_COMMAND
            fi
            break
        elif [[ "$action_sel" == "[rm]"* ]]; then
            local run_mode=$(_tct_mode_selector "rm")
            if [ -n "$run_mode" ]; then
                export CMT_COMMAND="true"
                export TCT_SINGLE_TARGET="$clean_target"
                __core_rm "-$run_mode"
                unset TCT_SINGLE_TARGET
                unset CMT_COMMAND
            fi
            break
        fi
    done
    return 0
}

# 原生指令劫持: cd (Command cd for TCT)
function cd() {
    # 狀態機讀取
    local setting_file="$HOME/mux-os/.setting"
    if [ -f "$setting_file" ]; then source "$setting_file"; fi

    local allow_radar="false"
    if [ "$MUX_MODE" == "TCT" ] && [ "$#" -eq 0 ]; then
        if [ "$COMMAND_UNIX" == "forever" ] || [ "$CMT_COMMAND" == "true" ]; then
            allow_radar="true"
        fi
    fi

    # 防爆閘門
    if [ "$allow_radar" != "true" ]; then
        if _bypass_guard "builtin cd" "$@"; then
            return $?
        else
            builtin cd "$@"
            return $?
        fi
    fi

    local origin_pwd="$HOME"
    local show_hidden="false"
    local jail_active="false"

    if [ "$allow_radar" == "true" ] && command -v _grant_xp &> /dev/null; then
        _grant_xp 5 "SHELL"
    fi

    while true; do
        if [ "$TCT_RADAR_HIDDEN" == "forever" ] || [ "$TCT_RADAR_HIDDEN" == "true" ]; then show_hidden="true"; fi
        local current_jail="${TCT_RADAR_JAIL:-true}"
        if [ "$current_jail" == "forever" ] || [ "$current_jail" == "true" ]; then jail_active="true"; fi

        local dirs
        if [ "$show_hidden" == "true" ]; then
            dirs=$(find -L . -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sed 's|^\./||' | sort)
        else
            dirs=$(find -L . -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sed 's|^\./||' | grep -v '^\.' | sort)
        fi

        local formatted_dirs=""
        if [ -n "$dirs" ]; then
            formatted_dirs=$(echo "$dirs" | awk -v c_dir="\033[1;37m" -v c_rst="\033[0m" '{print "\033[1;30m[  ]\033[0m " c_dir $0 c_rst}')
        else
            formatted_dirs="${C_BLACK}     [Empty]${C_RESET}"
        fi

        local menu_items=""
        if [ -n "$formatted_dirs" ]; then 
            menu_items+="${formatted_dirs}\n"
            menu_items+="${C_BLACK}----------${C_RESET}\n"
        fi

        menu_items+="${C_GREEN}[ls]${C_RESET} Show Files\n"
        menu_items+="${C_CYAN}[mk]${C_RESET} Make File or Directory\n"
        menu_items+="${C_PURPLE}[ip]${C_RESET} Input Command\n"

        local display_prompt="$PWD"

        if [ "$jail_active" == "true" ]; then
            if [[ "$PWD" != "$origin_pwd" && "$PWD" == "$origin_pwd"* ]]; then
                menu_items+="${C_RED}[cd]${C_RESET} Revert to Origin\n"
                menu_items+="${C_YELLOW}[..]${C_RESET} Backto\n"
            fi
            display_prompt="${PWD/#$HOME/\~}"
        else
            menu_items+="${C_RED}[cd]${C_RESET} Revert to Origin\n"
            if [ "$PWD" != "/" ]; then
                menu_items+="${C_YELLOW}[..]${C_RESET} Backto\n"
            fi
            display_prompt="$PWD"
        fi

        if [ "$TCT_RADAR_HIDDEN" != "forever" ]; then
            if [ "$show_hidden" == "true" ]; then
                menu_items+="${C_BLACK}[.*]${C_RESET} Hide Hidden\n"
            else
                menu_items+="${C_BLACK}[.*]${C_RESET} Show Hidden\n"
            fi
        fi

        if [ "$TCT_RADAR_JAIL" != "forever" ]; then
            if [ "$jail_active" == "true" ]; then
                menu_items+="${C_BLACK}[-1]${C_RESET} Unlock Jail\n"
            else
                menu_items+="${C_BLACK}[-0]${C_RESET} Lock Jail\n"
            fi
        fi

        local line_count=$(echo -ne "$menu_items" | wc -l)
        local dynamic_height=$(( line_count + 4 ))
        [ "$dynamic_height" -gt 35 ] && dynamic_height="80%"

        local ui_prompt=" :: $display_prompt › "
        [ "$CMT_COMMAND" == "true" ] && ui_prompt=" :: cmt › cd › $display_prompt › "

        local border_lbl="TARGET DIRECTORY"
        [ "$MUX_ENTRY_POINT" == "MEOW" ] && border_lbl="CARDBOARD BOX SCANNER"
        local raw_output=$(_ui_tct_nav_radar "$menu_items" "$ui_prompt" "$dynamic_height" "$border_lbl" "211" " :: Enter to Select, Esc to Return ::")

        local raw_target=$(echo "$raw_output" | tail -n +2)

        if [ -z "$raw_target" ]; then break; fi

        local target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')

        if [ "$target" == "----------" ] || [ "$target" == "[Empty]" ]; then continue; fi
        
        if [ "$target" == "[ls] Show Files" ]; then
            ls
            break
        elif [ "$target" == "[mk] Make File or Directory" ]; then
            while true; do
                local mk_items=""
                mk_items+="${C_CYAN}[touch]${C_RESET} Create Empty File\n"
                mk_items+="${C_YELLOW}[mkdir]${C_RESET} Create Directory\n"
                
                local mk_ui_prompt=" :: Make › ${PWD/#$HOME/\~} › "
                [ "$CMT_COMMAND" == "true" ] && mk_ui_prompt=" :: cmt › Make › ${PWD/#$HOME/\~} › "
                
                local mk_raw
                mk_raw=$(_ui_tct_nav_radar "$mk_items" "$mk_ui_prompt" "7" "CREATION FORGE" "51" " :: Esc to Return ::")
                
                local mk_sel=$(echo "$mk_raw" | tail -n +2 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                if [ -z "$mk_sel" ]; then break; fi 
                
                if [[ "$mk_sel" == "[touch]"* ]]; then
                    local p_touch=$(echo -e "\001${C_CYAN}\002 :: New(s) Name › \001${C_RESET}\002")
                    read -e -p "$p_touch" new_target < /dev/tty
                    if [ -n "$new_target" ]; then
                        echo -e "${C_RED} :: Executing: touch $new_target ${C_RESET}"
                        eval "command touch $new_target"
                        if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                    fi
                    break
                elif [[ "$mk_sel" == "[mkdir]"* ]]; then
                    local p_mkdir=$(echo -e "\001${C_YELLOW}\002 :: New Directory(s) Name › \001${C_RESET}\002")
                    read -e -p "$p_mkdir" new_target < /dev/tty
                    if [ -n "$new_target" ]; then
                        echo -e "${C_RED} :: EXECUTING: mkdir -p $new_target ${C_RESET}"
                        eval "command mkdir -p $new_target"
                        if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                    fi
                    break
                fi
            done
            continue
        elif [ "$target" == "[ip] Input Command" ]; then
            local p_cmd=$(echo -e "\001${C_PURPLE}\002 :: Command (Empty to abort) › \001${C_RESET}\002")
            read -e -p "$p_cmd" user_cmd < /dev/tty
            user_cmd=$(echo "$user_cmd" | sed 's/^[ \t]*//;s/[ \t]*$//')
            if [ -n "$user_cmd" ]; then
                echo -e "${C_RED} :: Executing: $user_cmd ${C_RESET}"
                eval "$user_cmd"
                echo -ne "${C_BLACK}    ›› Press 'Enter' to return to radar...${C_RESET}"
                read < /dev/tty
            fi
            continue
        elif [ "$target" == "[cd] Revert to Origin" ]; then
            builtin cd "$origin_pwd"
            continue
        elif [ "$target" == "[..] Backto" ]; then
            builtin cd ..
            _update_setting "TCT_RADAR_HIDDEN" "false"
            show_hidden="false"
        elif [ "$target" == "[.*] Show Hidden" ]; then
            _update_setting "TCT_RADAR_HIDDEN" "true"
            show_hidden="true"
            continue
        elif [ "$target" == "[.*] Hide Hidden" ]; then
            _update_setting "TCT_RADAR_HIDDEN" "false"
            show_hidden="false"
            continue
        elif [ "$target" == "[-1] Unlock Jail" ]; then
            _update_setting "TCT_RADAR_JAIL" "false"
            jail_active="false"
            continue
        elif [ "$target" == "[-0] Lock Jail" ]; then
            _update_setting "TCT_RADAR_JAIL" "true"
            jail_active="true"
            continue
        else
            local clean_dir=$(echo "$target" | sed 's/^\[  \] //')
            builtin cd "$clean_dir"
            _update_setting "TCT_RADAR_HIDDEN" "false"
            show_hidden="false"
        fi
    done
}

# 原生指令劫持: ls (Command ls for TCT)
function ls() {
    local setting_file="$HOME/mux-os/.setting"
    if [ -f "$setting_file" ]; then source "$setting_file"; fi

    local allow_radar="false"
    if [ "$MUX_MODE" == "TCT" ] && [ "$#" -eq 0 ]; then
        if [ "$COMMAND_UNIX" == "forever" ] || [ "$CMT_COMMAND" == "true" ]; then
            allow_radar="true"
        fi
    fi

    if [ "$allow_radar" != "true" ]; then
        if _bypass_guard "command ls --color=auto" "$@"; then return $?; else command ls --color=auto "$@"; return $?; fi
    fi

    local origin_pwd="$HOME"
    local show_hidden="false"
    local jail_active="false"

    if [ "$allow_radar" == "true" ] && command -v _grant_xp &> /dev/null; then
        _grant_xp 5 "SHELL"
    fi

    while true; do
        if [ "$TCT_RADAR_HIDDEN" == "forever" ] || [ "$TCT_RADAR_HIDDEN" == "true" ]; then show_hidden="true"; fi
        local current_jail="${TCT_RADAR_JAIL:-true}"
        if [ "$current_jail" == "forever" ] || [ "$current_jail" == "true" ]; then jail_active="true"; fi
        
        local files=""
        if [ "$show_hidden" == "true" ]; then
            files=$(command ls -1A --color=always 2>/dev/null)
        else
            files=$(command ls -1 --color=always 2>/dev/null)
        fi

        local formatted_files=""
        if [ -n "$files" ]; then
            formatted_files=$(echo "$files" | sed 's/^/\x1b[1;30m[  ]\x1b[0m /')
        else
            formatted_files="${C_BLACK}     [Empty]${C_RESET}"
        fi

        local menu_items=""
        if [ -n "$formatted_files" ]; then 
            menu_items+="${formatted_files}\n"
            menu_items+="${C_BLACK}----------${C_RESET}\n"
        fi
        
        menu_items+="${C_PINKMEOW}[cd]${C_RESET} Navigate\n"
        menu_items+="${C_CYAN}[mk]${C_RESET} Make File or Directory\n"
        menu_items+="${C_PURPLE}[ip]${C_RESET} Input Command\n"
        menu_items+="${C_GREEN}[cp]${C_RESET} Tactical Cloner\n"
        menu_items+="${C_ORANGE}[mv]${C_RESET} Tactical Relocator\n"
        menu_items+="${C_RED}[rm]${C_RESET} Tactical Destructor\n"

        local display_prompt="$PWD"
        if [ "$jail_active" == "true" ]; then
            if [[ "$PWD" != "$origin_pwd" && "$PWD" == "$origin_pwd"* ]]; then
                menu_items+="${C_RED}[cd]${C_RESET} Revert to Origin\n"
                menu_items+="${C_YELLOW}[..]${C_RESET} Backto\n"
            fi
            display_prompt="${PWD/#$HOME/\~}"
        else
            menu_items+="${C_RED}[cd]${C_RESET} Revert to Origin\n"
            if [ "$PWD" != "/" ]; then
                menu_items+="${C_YELLOW}[..]${C_RESET} Backto\n"
            fi
            display_prompt="$PWD"
        fi

        if [ "$TCT_RADAR_HIDDEN" != "forever" ]; then
            if [ "$show_hidden" == "true" ]; then
                menu_items+="${C_BLACK}[.*]${C_RESET} Hide Hidden\n"
            else
                menu_items+="${C_BLACK}[.*]${C_RESET} Show Hidden\n"
            fi
        fi

        if [ "$TCT_RADAR_JAIL" != "forever" ]; then
            if [ "$jail_active" == "true" ]; then
                menu_items+="${C_BLACK}[-1]${C_RESET} Unlock Jail\n"
            else
                menu_items+="${C_BLACK}[-0]${C_RESET} Lock Jail\n"
            fi
        fi

        local line_count=$(echo -ne "$menu_items" | wc -l)
        local dynamic_height=$(( line_count + 4 ))
        [ "$dynamic_height" -gt 35 ] && dynamic_height="80%"

        local ui_prompt=" :: $display_prompt › "
        [ "$CMT_COMMAND" == "true" ] && ui_prompt=" :: cmt › ls › $display_prompt › "

        local border_lbl="FILE SCANNER"
        [ "$MUX_ENTRY_POINT" == "MEOW" ] && border_lbl="SNIFFING AROUND"
        local raw_output=$(_ui_tct_nav_radar "$menu_items" "$ui_prompt" "$dynamic_height" "$border_lbl" "46" " :: Enter to Inspect, Esc to Return ::")

        local raw_target=$(echo "$raw_output" | tail -n +2)

        if [ -z "$raw_target" ]; then break; fi

        local target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')

        if [ "$target" == "----------" ] || [ "$target" == "[Empty]" ]; then continue; fi
        
        if [ "$target" == "[cd] Navigate" ]; then
            export CMT_COMMAND="true"; cd; unset CMT_COMMAND; break
        elif [ "$target" == "[mk] Make File or Directory" ]; then
            while true; do
                local mk_items=""
                mk_items+="${C_CYAN}[touch]${C_RESET} Create Empty File\n"
                mk_items+="${C_YELLOW}[mkdir]${C_RESET} Create Directory\n"
                
                local mk_ui_prompt=" :: Make › ${PWD/#$HOME/\~} :: "
                [ "$CMT_COMMAND" == "true" ] && mk_ui_prompt=" :: cmt › Make › ${PWD/#$HOME/\~} :: "
                
                local mk_raw
                mk_raw=$(_ui_tct_nav_radar "$mk_items" "$mk_ui_prompt" "7" "CREATION FORGE" "51" " :: Esc to Return ::")
                
                local mk_sel=$(echo "$mk_raw" | tail -n +2 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                if [ -z "$mk_sel" ]; then break; fi 
                
                if [[ "$mk_sel" == "[touch]"* ]]; then
                    local p_touch=$(echo -e "\001${C_CYAN}\002 :: New File(s) Name › \001${C_RESET}\002")
                    read -e -p "$p_touch" new_target < /dev/tty
                    if [ -n "$new_target" ]; then
                        echo -e "${C_RED} :: Executing: touch $new_target ${C_RESET}"
                        eval "command touch $new_target"
                        if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                    fi
                    break
                elif [[ "$mk_sel" == "[mkdir]"* ]]; then
                    local p_mkdir=$(echo -e "\001${C_YELLOW}\002 :: New Directory(s) Name › \001${C_RESET}\002")
                    read -e -p "$p_mkdir" new_target < /dev/tty
                    if [ -n "$new_target" ]; then
                        echo -e "${C_RED} :: Executing: mkdir -p $new_target ${C_RESET}"
                        eval "command mkdir -p $new_target"
                        if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                    fi
                    break
                fi
            done
            continue
        elif [ "$target" == "[ip] Input Command" ]; then
            local p_cmd=$(echo -e "\001${C_PURPLE}\002 :: COMMAND (Empty to abort) › \001${C_RESET}\002")
            read -e -p "$p_cmd" user_cmd < /dev/tty
            user_cmd=$(echo "$user_cmd" | sed 's/^[ \t]*//;s/[ \t]*$//')
            if [ -n "$user_cmd" ]; then
                echo -e "${C_RED} :: Executing: $user_cmd ${C_RESET}"
                eval "$user_cmd"
                echo -ne "${C_BLACK}    ›› Press Enter to return to radar...${C_RESET}"
                read < /dev/tty
            fi
            continue
        elif [ "$target" == "[cd] Revert to Origin" ]; then
            builtin cd "$origin_pwd"; continue
        elif [[ "$target" == "[cp]"* ]]; then
            export CMT_COMMAND="true"
            __core_cp
            unset CMT_COMMAND
            break
        elif [[ "$target" == "[mv]"* ]]; then
            export CMT_COMMAND="true"
            __core_mv
            unset CMT_COMMAND
            break
        elif [[ "$target" == "[rm]"* ]]; then
            export CMT_COMMAND="true"
            __core_rm
            unset CMT_COMMAND
            break
        elif [ "$target" == "[..] Backto" ]; then
            builtin cd ..
            _update_setting "TCT_RADAR_HIDDEN" "false"
            show_hidden="false"
        elif [ "$target" == "[.*] Show Hidden" ]; then
            _update_setting "TCT_RADAR_HIDDEN" "true"
            show_hidden="true"; continue
        elif [ "$target" == "[.*] Hide Hidden" ]; then
            _update_setting "TCT_RADAR_HIDDEN" "false"
            show_hidden="false"; continue
        elif [ "$target" == "[-1] Unlock Jail" ]; then
            _update_setting "TCT_RADAR_JAIL" "false"
            jail_active="false"; continue
        elif [ "$target" == "[-0] Lock Jail" ]; then
            _update_setting "TCT_RADAR_JAIL" "true"
            jail_active="true"; continue
        else
            local clean_target=$(echo "$target" | sed 's/^\[  \] //')
            if [ -d "$clean_target" ] || [ -f "$clean_target" ]; then
                _tct_file_action_menu "$clean_target"
                local ret=$?
                if [ $ret -eq 2 ]; then break; fi
                if [ $ret -eq 3 ]; then show_hidden="false"; fi
                continue
            fi
        fi
    done
}

# 原生指令劫持: rm (Command rm for TCT)
function __core_rm() {
    # 軌道直通
    if [ -z "$TCT_SINGLE_TARGET" ] && [ "$#" -gt 0 ]; then
        local current_rm_mode=""
        local selected_targets=()
        
        # 參數解析
        for arg in "$@"; do
            if [[ "$arg" == -* ]]; then
                current_rm_mode="${arg#-}"
            else
                selected_targets+=("$arg")
            fi
        done

        if [ ${#selected_targets[@]} -eq 0 ]; then return 0; fi

        # 判斷 -r/-f
        if [[ "$current_rm_mode" == *"r"* ]] || [[ "$current_rm_mode" == *"f"* ]]; then
            command rm "-$current_rm_mode" "${selected_targets[@]}"
            local ret=$?
            if [ $ret -eq 0 ] && command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
            return $ret
        else
            # -i/[Empty]
            local trash_dir="$HOME/.trash"
            if [ ! -d "$trash_dir" ]; then mkdir -p "$trash_dir"; fi
            local timestamp=$(date +%Y%m%d_%H%M%S)

            for item in "${selected_targets[@]}"; do
                if [ -d "$item" ]; then
                    command rmdir "$item" 2>/dev/null
                    local ret=$?
                    if [ $ret -ne 0 ]; then
                        echo -e "${C_YELLOW}    ›› [BLOCKED] '$item' is not empty. (Requires -r mode)${C_RESET}"
                    else
                        echo -e "${C_BLACK}    ›› [WIPED] '$item' (Empty Shell Destroyed)${C_RESET}"
                        if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                    fi
                elif [ -f "$item" ] || [ -L "$item" ]; then
                    local safe_name="${item}_${timestamp}"
                    command mv "$item" "$trash_dir/$safe_name" 2>/dev/null
                    local ret=$?
                    if [ $ret -eq 0 ]; then
                        echo -e "${C_BLACK}    ›› [TRASHED] '$item' › .trash/${safe_name}${C_RESET}"
                        if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                    fi
                fi
            done
            return 0
        fi
    fi

    # 視覺戰術雷達
    local setting_file="$HOME/mux-os/.setting"
    if [ -f "$setting_file" ]; then source "$setting_file"; fi

    local allow_radar="false"
    if [ "$MUX_MODE" == "TCT" ]; then
        if [ "$COMMAND_UNIX" == "forever" ] || [ "$CMT_COMMAND" == "true" ]; then
            allow_radar="true"
        fi
    fi

    if [ "$allow_radar" != "true" ]; then 
        command rm
        return $?
    fi

    local show_hidden="false"
    local jail_active="false"

    # 接收旗標
    local current_rm_mode="i" 
    if [ -n "$TCT_SINGLE_TARGET" ] && [[ "$1" == -* ]]; then
        current_rm_mode="${1#-}"
    fi

    while true; do
        local current_jail="${TCT_RADAR_JAIL:-true}"
        if [ "$TCT_RADAR_HIDDEN" == "forever" ] || [ "$TCT_RADAR_HIDDEN" == "true" ]; then show_hidden="true"; fi
        if [ "$current_jail" == "forever" ] || [ "$current_jail" == "true" ]; then jail_active="true"; fi

        local mode_changed="false"
        local selected_targets=()

        if [ -n "$TCT_SINGLE_TARGET" ]; then
            # 單體直通
            selected_targets+=("$TCT_SINGLE_TARGET")
        else
            # 大選單模式
            local targets
            if [ "$show_hidden" == "true" ]; then
                targets=$(command ls -1A --color=always 2>/dev/null)
            else
                targets=$(command ls -1 --color=always 2>/dev/null)
            fi

            local formatted_targets=""
            if [ -n "$targets" ]; then
                formatted_targets=$(echo "$targets" | sed 's/^/\x1b[1;30m[  ]\x1b[0m /')
            else
                formatted_targets="${C_BLACK}     [Empty]${C_RESET}"
            fi

            local menu_items=""
            
            [ "$current_rm_mode" != "i" ] && menu_items+="${C_YELLOW}[-i]${C_RESET} Interactive\n"
            [ "$current_rm_mode" != "f" ] && menu_items+="${C_YELLOW}[-f]${C_RESET} Force\n"
            [ "$current_rm_mode" != "r" ] && menu_items+="${C_RED}[-r]${C_RESET} Recursive\n"
            [ "$current_rm_mode" != "rf" ] && menu_items+="${C_RED}\033[5m[rf]\033[0m${C_RESET} Nuke\n"
            
            menu_items+="${C_BLACK}----------${C_RESET}\n"
            
            if [ -n "$formatted_targets" ]; then 
                menu_items+="${formatted_targets}\n"
                menu_items+="${C_BLACK}----------${C_RESET}\n"
            fi
            
            menu_items+="${C_GREEN}[ls]${C_RESET} File Scanner\n"
            menu_items+="${C_PINKMEOW}[cd]${C_RESET} Navigate\n"

            if [ "$TCT_RADAR_JAIL" != "forever" ]; then
                if [ "$jail_active" == "true" ]; then
                    menu_items+="${C_BLACK}[-1]${C_RESET} Unlock Jail\n"
                else
                    menu_items+="${C_BLACK}[-0]${C_RESET} Lock Jail\n"
                fi
            fi

            local display_prompt="${PWD/#$HOME/\~}"
            local ui_prompt=" :: rm -$current_rm_mode › $display_prompt › "
            if [ "$CMT_COMMAND" == "true" ]; then
                ui_prompt=" :: cmt › rm -$current_rm_mode › $display_prompt › "
            fi

            local line_count=$(echo -ne "$menu_items" | wc -l)
            local dynamic_height=$(( line_count + 4 ))
            [ "$dynamic_height" -gt 35 ] && dynamic_height="80%"

            local border_lbl="TACTICAL DESTRUCTOR"
            [ "$MUX_ENTRY_POINT" == "MEOW" ] && border_lbl="PUSHING OFF THE TABLE"
            local raw_output=$(_ui_tct_tactical_radar "$menu_items" "$ui_prompt" "$dynamic_height" "$border_lbl" "196")

            local selections=$(echo "$raw_output" | tail -n +2)

            if [ -z "$selections" ]; then break; fi

            while IFS= read -r line; do
                local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                if [ "$clean_line" == "----------" ] || [ "$clean_line" == "[Empty]" ] || [ -z "$clean_line" ]; then continue; fi
                
                if [[ "$clean_line" == "[-i]"* ]]; then current_rm_mode="i"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[-f]"* ]]; then current_rm_mode="f"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[-r]"* ]]; then current_rm_mode="r"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[rf]"* ]]; then current_rm_mode="rf"; mode_changed="true"; continue; fi
                
                if [[ "$clean_line" == "[ls]"* ]]; then export CMT_COMMAND="true"; ls; unset CMT_COMMAND; break 2; fi
                if [[ "$clean_line" == "[cd]"* ]]; then export CMT_COMMAND="true"; cd; unset CMT_COMMAND; break 2; fi

                if [[ "$clean_line" == "[.*] Show Hidden" ]]; then export TCT_RADAR_HIDDEN="true"; show_hidden="true"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[.*] Hide Hidden" ]]; then export TCT_RADAR_HIDDEN="false"; show_hidden="false"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[-1] Unlock Jail" ]]; then _update_setting "TCT_RADAR_JAIL" "false"; jail_active="false"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[-0] Lock Jail" ]]; then _update_setting "TCT_RADAR_JAIL" "true"; jail_active="true"; mode_changed="true"; continue; fi

                local target_item=$(echo "$clean_line" | sed 's/^\[  \] //')
                if [ -n "$target_item" ] && [[ ! "$target_item" == \[*\]* ]]; then
                    selected_targets+=("$target_item")
                fi
            done <<< "$selections"
        fi

        if [ "$mode_changed" == "true" ] && [ ${#selected_targets[@]} -eq 0 ]; then
            continue
        fi

        # 執行刪除
        if [ ${#selected_targets[@]} -gt 0 ]; then
            echo -e "${C_RED} :: DESTRUCTOR INITIATED › MODE: -$current_rm_mode ${C_RESET}"
            echo -e "${C_BLACK}    ›› Targets: ${#selected_targets[@]} items.${C_RESET}"
            
            if [[ "$current_rm_mode" == *"i"* ]]; then
                local ask_flag="true"
                
                for target_item in "${selected_targets[@]}"; do
                    if [ "$ask_flag" == "true" ]; then
                        local t_type="File"
                        [ -d "$target_item" ] && t_type="Directory"
                        
                        echo -ne "${C_YELLOW} :: Remove $t_type '${target_item}'? [Y/n] [A/Q]: ${C_RESET}"
                        read -r confirm < /dev/tty
                        
                        case "${confirm,,}" in
                            y)
                                command rm -rf "$target_item" 2>/dev/null
                                echo -e "${C_BLACK}    ›› [WIPED] '$target_item'${C_RESET}"
                                ;;
                            a)
                                ask_flag="false"
                                command rm -rf "$target_item" 2>/dev/null
                                echo -e "${C_BLACK}    ›› [WIPED] '$target_item'${C_RESET}"
                                ;;
                            q)
                                echo -e "${C_GREEN} :: Destructor sequence aborted.${C_RESET}"
                                break
                                ;;
                            *)
                                echo -e "${C_BLACK}    ›› [SKIPPED] '$target_item'${C_RESET}"
                                ;;
                        esac
                    else
                        command rm -rf "$target_item" 2>/dev/null
                        echo -e "${C_BLACK}    ›› [WIPED] '$target_item'${C_RESET}"
                    fi
                done
            else
                echo -e "${C_RED} :: WARNING: Permanent deletion selected. Targets will NOT be sent to .trash.${C_RESET}"
                echo -ne "${C_RED} :: TYPE 'CONFIRM' TO OBLITERATE: ${C_RESET}"
                read -r confirm < /dev/tty
                if [ "$confirm" != "CONFIRM" ]; then
                    echo -e "${C_GREEN} :: Destructor aborted. Target(s) secured.${C_RESET}"
                    break
                fi
                command rm "-$current_rm_mode" "${selected_targets[@]}"
            fi
            
            if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
            break
        fi
        
        break
    done
}

# 原生指令劫持: mv (Command mv for TCT)
function __core_mv() {
    # 軌道直通
    if [ -z "$TCT_SINGLE_TARGET" ] && [ "$#" -gt 0 ]; then
        command mv "$@"
        local ret=$?
        if [ $ret -eq 0 ] && command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
        return $ret
    fi

    # 接收旗標
    local current_mv_mode="i" 
    if [ -n "$TCT_SINGLE_TARGET" ] && [[ "$1" == -* ]]; then
        current_mv_mode="${1#-}"
    fi

    local show_hidden="${TCT_RADAR_HIDDEN:-false}"

    while true; do
        local mode_changed="false"
        local selected_targets=()
        
        if [ -n "$TCT_SINGLE_TARGET" ]; then
            # 單體直通
            selected_targets+=("$TCT_SINGLE_TARGET")
        else
            local targets
            if [ "$show_hidden" == "true" ] || [ "$show_hidden" == "forever" ]; then
                targets=$(command ls -1A --color=always 2>/dev/null)
            else
                targets=$(command ls -1 --color=always 2>/dev/null)
            fi

            local formatted_targets=""
            if [ -n "$targets" ]; then
                formatted_targets=$(echo "$targets" | sed 's/^/\x1b[1;30m[  ]\x1b[0m /')
            else
                formatted_targets="${C_BLACK}     [Empty]${C_RESET}"
            fi

            local menu_items=""
            [ "$current_mv_mode" != "i" ] && menu_items+="${C_YELLOW}[-i]${C_RESET} Interactive (Safe)\n"
            [ "$current_mv_mode" != "f" ] && menu_items+="${C_RED}[-f]${C_RESET} Force Overwrite\n"
            menu_items+="${C_BLACK}----------${C_RESET}\n"
            menu_items+="${formatted_targets}\n"
            menu_items+="${C_BLACK}----------${C_RESET}\n"
            menu_items+="${C_GREEN}[ls]${C_RESET} File Scanner\n"
            menu_items+="${C_PINKMEOW}[cd]${C_RESET} Navigate\n"

            local ui_prompt=" :: mv -$current_mv_mode › ${PWD/#$HOME/\~} :: "
            [ "$CMT_COMMAND" == "true" ] && ui_prompt=" :: cmt › mv -$current_mv_mode › ${PWD/#$HOME/\~} :: "

            local line_count=$(echo -ne "$menu_items" | wc -l)
            local dynamic_height=$(( line_count + 4 ))
            [ "$dynamic_height" -gt 35 ] && dynamic_height="80%"

            local border_lbl="TACTICAL RELOCATOR"
            [ "$MUX_ENTRY_POINT" == "MEOW" ] && border_lbl="DRAGGING TO THE BED"
            local raw_output=$(_ui_tct_tactical_radar "$menu_items" "$ui_prompt" "$dynamic_height" "$border_lbl" "220")

            local selections=$(echo "$raw_output" | tail -n +2)

            if [ -z "$selections" ]; then break; fi

            while IFS= read -r line; do
                local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                if [ "$clean_line" == "----------" ] || [ "$clean_line" == "[Empty]" ] || [ -z "$clean_line" ]; then continue; fi
                
                if [[ "$clean_line" == "[-i]"* ]]; then current_mv_mode="i"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[-f]"* ]]; then current_mv_mode="f"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[ls]"* ]]; then export CMT_COMMAND="true"; ls; unset CMT_COMMAND; break 2; fi
                if [[ "$clean_line" == "[cd]"* ]]; then export CMT_COMMAND="true"; cd; unset CMT_COMMAND; break 2; fi

                local target_item=$(echo "$clean_line" | sed 's/^\[  \] //')
                if [ -n "$target_item" ] && [[ ! "$target_item" == \[*\]* ]]; then
                    selected_targets+=("$target_item")
                fi
            done <<< "$selections"
        fi

        if [ "$mode_changed" == "true" ] && [ ${#selected_targets[@]} -eq 0 ]; then
            continue
        fi

        # 目的地輸入階段
        if [ ${#selected_targets[@]} -gt 0 ]; then
            echo -e "${C_YELLOW} :: RELOCATOR INITIATED › MODE: -$current_mv_mode ${C_RESET}"
            echo -e "${C_BLACK}    ›› Sources: ${selected_targets[*]}.${C_RESET}"
            
            local abs_targets=()
            for t in "${selected_targets[@]}"; do
                abs_targets+=("$PWD/$t")
            done

            local default_input=""
            local p_name=""
            
            if [ ${#selected_targets[@]} -eq 1 ]; then
                default_input="${selected_targets[0]}"
                p_name=$(echo -e "\001${C_YELLOW}\002 :: NEW NAME (Enter to keep original) › \001${C_RESET}\002")
            else
                p_name=$(echo -e "\001${C_YELLOW}\002 :: NEW FOLDER NAME (Enter to move into destination directly) › \001${C_RESET}\002")
            fi

            local dest_name=""
            read -e -p "$p_name" -i "$default_input" dest_name < /dev/tty
            if [ -z "$(echo "$dest_name" | tr -d ' ')" ]; then dest_name="$default_input"; fi

            local origin_pwd="$PWD"
            local exec_confirm="false"
            
            while true; do
                local dirs
                if [ "$show_hidden" == "true" ] || [ "$show_hidden" == "forever" ]; then
                    dirs=$(find -L . -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sed 's|^\./||' | sort)
                else
                    dirs=$(find -L . -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sed 's|^\./||' | grep -v '^\.' | sort)
                fi

                local formatted_dirs=""
                if [ -n "$dirs" ]; then
                    formatted_dirs=$(echo "$dirs" | awk -v c_dir="\033[1;37m" -v c_rst="\033[0m" '{print "\033[1;30m[  ]\033[0m " c_dir $0 c_rst}')
                fi

                local nav_items=""
                nav_items+="${C_RED}[**] Confirm & Execute Here${C_RESET}\n"
                nav_items+="${C_BLACK}----------${C_RESET}\n"
                
                if [ "$PWD" != "/" ]; then
                    nav_items+="${C_YELLOW}[..]${C_RESET} Backto\n"
                fi
                
                if [ -n "$formatted_dirs" ]; then 
                    nav_items+="${formatted_dirs}\n"
                fi

                local nav_prompt=" :: Destination › ${PWD/#$HOME/\~} › "
                local nav_line_count=$(echo -ne "$nav_items" | wc -l)
                local nav_dynamic_height=$(( nav_line_count + 4 ))
                [ "$nav_dynamic_height" -gt 35 ] && nav_dynamic_height="80%"

                local nav_output
                nav_output=$(_ui_tct_nav_radar "$nav_items" "$nav_prompt" "$nav_dynamic_height" "SELECT DESTINATION FOLDER" "220" " :: Navigate, then press [**] to Confirm ::")

                local sel=$(echo "$nav_output" | tail -n +2 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                if [ -z "$sel" ]; then break; fi

                if [[ "$sel" == "[**]"* ]]; then
                    exec_confirm="true"
                    break
                elif [[ "$sel" == "[..]"* ]]; then
                    builtin cd ..
                else
                    local target_dir=$(echo "$sel" | sed 's/^\[  \] //')
                    if [ -d "$target_dir" ]; then
                        builtin cd "$target_dir"
                    fi
                fi
            done

            if [ "$exec_confirm" == "true" ]; then
                local final_dest_path="$PWD"
                if [ -n "$dest_name" ] && [ "$dest_name" != "$default_input" ]; then
                    final_dest_path="$PWD/$dest_name"
                fi
                
                echo -e "${C_RED} :: EXECUTING: mv -$current_mv_mode ${selected_targets[*]} -> ${final_dest_path/#$HOME/\~}${C_RESET}"
                command mv "-$current_mv_mode" "${abs_targets[@]}" "$final_dest_path"
                if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                
                builtin cd "$origin_pwd"
                break
            else
                echo -e "${C_GREEN} :: Relocator aborted. No execution.${C_RESET}"
                builtin cd "$origin_pwd"
                break
            fi
        fi
        
        break
    done
}

# 原生指令劫持: cp (Command cp for TCT)
function __core_cp() {
    # 軌道直通
    if [ -z "$TCT_SINGLE_TARGET" ] && [ "$#" -gt 0 ]; then
        command cp "$@"
        local ret=$?
        if [ $ret -eq 0 ] && command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
        return $ret
    fi

    # 接收旗標
    local current_cp_mode="i" 
    if [ -n "$TCT_SINGLE_TARGET" ] && [[ "$1" == -* ]]; then
        current_cp_mode="${1#-}"
    fi
    
    local show_hidden="${TCT_RADAR_HIDDEN:-false}"

    while true; do
        local mode_changed="false"
        local selected_targets=()
        
        if [ -n "$TCT_SINGLE_TARGET" ]; then
            # 單體直通
            selected_targets+=("$TCT_SINGLE_TARGET")
        else
            local targets
            if [ "$show_hidden" == "true" ] || [ "$show_hidden" == "forever" ]; then
                targets=$(command ls -1A --color=always 2>/dev/null)
            else
                targets=$(command ls -1 --color=always 2>/dev/null)
            fi

            local formatted_targets=""
            if [ -n "$targets" ]; then
                formatted_targets=$(echo "$targets" | sed 's/^/\x1b[1;30m[  ]\x1b[0m /')
            else
                formatted_targets="${C_BLACK}     [Empty]${C_RESET}"
            fi

            local menu_items=""
            [ "$current_cp_mode" != "i" ] && menu_items+="${C_YELLOW}[-i]${C_RESET} Interactive (Safe)\n"
            [ "$current_cp_mode" != "f" ] && menu_items+="${C_RED}[-f]${C_RESET} Force Overwrite\n"
            [ "$current_cp_mode" != "r" ] && menu_items+="${C_PINKMEOW}[-r]${C_RESET} Recursive (Folder Copy)\n"
            [ "$current_cp_mode" != "a" ] && menu_items+="${C_GREEN}[-a]${C_RESET} Archive (Preserve ALL Attributes)\n"
            menu_items+="${C_BLACK}----------${C_RESET}\n"
            menu_items+="${formatted_targets}\n"
            menu_items+="${C_BLACK}----------${C_RESET}\n"
            menu_items+="${C_GREEN}[ls]${C_RESET} File Scanner\n"
            menu_items+="${C_PINKMEOW}[cd]${C_RESET} Navigate\n"

            local ui_prompt=" :: cp -$current_cp_mode › ${PWD/#$HOME/\~} :: "
            [ "$CMT_COMMAND" == "true" ] && ui_prompt=" :: cmt › cp -$current_cp_mode › ${PWD/#$HOME/\~} :: "

            local line_count=$(echo -ne "$menu_items" | wc -l)
            local dynamic_height=$(( line_count + 4 ))
            [ "$dynamic_height" -gt 35 ] && dynamic_height="80%"

            local border_lbl="TACTICAL CLONER"
            [ "$MUX_ENTRY_POINT" == "MEOW" ] && border_lbl="CLONING THE FISH"
            local raw_output=$(_ui_tct_tactical_radar "$menu_items" "$ui_prompt" "$dynamic_height" "$border_lbl" "33")

            local selections=$(echo "$raw_output" | tail -n +2)

            if [ -z "$selections" ]; then break; fi

            while IFS= read -r line; do
                local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                if [ "$clean_line" == "----------" ] || [ "$clean_line" == "[Empty]" ] || [ -z "$clean_line" ]; then continue; fi
                
                if [[ "$clean_line" == "[-i]"* ]]; then current_cp_mode="i"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[-f]"* ]]; then current_cp_mode="f"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[-r]"* ]]; then current_cp_mode="r"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[-a]"* ]]; then current_cp_mode="a"; mode_changed="true"; continue; fi
                if [[ "$clean_line" == "[ls]"* ]]; then export CMT_COMMAND="true"; ls; unset CMT_COMMAND; break 2; fi
                if [[ "$clean_line" == "[cd]"* ]]; then export CMT_COMMAND="true"; cd; unset CMT_COMMAND; break 2; fi

                local target_item=$(echo "$clean_line" | sed 's/^\[  \] //')
                if [ -n "$target_item" ] && [[ ! "$target_item" == \[*\]* ]]; then
                    selected_targets+=("$target_item")
                fi
            done <<< "$selections"
        fi

        if [ "$mode_changed" == "true" ] && [ ${#selected_targets[@]} -eq 0 ]; then
            continue
        fi

        # 目的地輸入階段
        if [ ${#selected_targets[@]} -gt 0 ]; then
            echo -e "${C_GREEN} :: CLONER INITIATED › MODE: -$current_cp_mode ${C_RESET}"
            echo -e "${C_BLACK}    ›› Sources: ${selected_targets[*]}.${C_RESET}"
            
            local abs_targets=()
            for t in "${selected_targets[@]}"; do
                abs_targets+=("$PWD/$t")
            done

            local default_input=""
            local p_name=""
            
            if [ ${#selected_targets[@]} -eq 1 ]; then
                default_input="${selected_targets[0]}"
                p_name=$(echo -e "\001${C_GREEN}\002 :: NEW NAME (Enter to keep original) › \001${C_RESET}\002")
            else
                p_name=$(echo -e "\001${C_GREEN}\002 :: NEW FOLDER NAME (Enter to copy into destination directly) › \001${C_RESET}\002")
            fi

            local dest_name=""
            read -e -p "$p_name" -i "$default_input" dest_name < /dev/tty
            if [ -z "$(echo "$dest_name" | tr -d ' ')" ]; then dest_name="$default_input"; fi

            local origin_pwd="$PWD"
            local exec_confirm="false"
            
            while true; do
                local dirs
                if [ "$show_hidden" == "true" ] || [ "$show_hidden" == "forever" ]; then
                    dirs=$(find -L . -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sed 's|^\./||' | sort)
                else
                    dirs=$(find -L . -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sed 's|^\./||' | grep -v '^\.' | sort)
                fi

                local formatted_dirs=""
                if [ -n "$dirs" ]; then
                    formatted_dirs=$(echo "$dirs" | awk -v c_dir="\033[1;37m" -v c_rst="\033[0m" '{print "\033[1;30m[  ]\033[0m " c_dir $0 c_rst}')
                fi

                local nav_items=""
                nav_items+="${C_RED}[**] Confirm & Execute Here${C_RESET}\n"
                nav_items+="${C_BLACK}----------${C_RESET}\n"
                
                if [ "$PWD" != "/" ]; then
                    nav_items+="${C_YELLOW}[..]${C_RESET} Backto\n"
                fi
                
                if [ -n "$formatted_dirs" ]; then 
                    nav_items+="${formatted_dirs}\n"
                fi

                local nav_prompt=" :: DESTINATION › ${PWD/#$HOME/\~} :: "
                local nav_line_count=$(echo -ne "$nav_items" | wc -l)
                local nav_dynamic_height=$(( nav_line_count + 4 ))
                [ "$nav_dynamic_height" -gt 35 ] && nav_dynamic_height="80%"

                local nav_output
                nav_output=$(_ui_tct_nav_radar "$nav_items" "$nav_prompt" "$nav_dynamic_height" "SELECT DESTINATION FOLDER" "33" " :: Navigate, then press [**] to Confirm ::")

                local sel=$(echo "$nav_output" | tail -n +2 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                if [ -z "$sel" ]; then break; fi

                if [[ "$sel" == "[**]"* ]]; then
                    exec_confirm="true"
                    break
                elif [[ "$sel" == "[..]"* ]]; then
                    builtin cd ..
                else
                    local target_dir=$(echo "$sel" | sed 's/^\[  \] //')
                    if [ -d "$target_dir" ]; then
                        builtin cd "$target_dir"
                    fi
                fi
            done

            if [ "$exec_confirm" == "true" ]; then
                local final_dest_path="$PWD"
                if [ -n "$dest_name" ] && [ "$dest_name" != "$default_input" ]; then
                    final_dest_path="$PWD/$dest_name"
                fi
                
                echo -e "${C_RED} :: EXECUTING: cp -$current_cp_mode ${selected_targets[*]} -> ${final_dest_path/#$HOME/\~}${C_RESET}"
                command cp "-$current_cp_mode" "${abs_targets[@]}" "$final_dest_path"
                if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                
                builtin cd "$origin_pwd"
                break
            else
                echo -e "${C_YELLOW} :: Cloner aborted. No execution.${C_RESET}"
                builtin cd "$origin_pwd"
                break
            fi
        fi
        
        break
    done
}

# 指揮塔初始化 (Tower Initialization)
function _tct_init() {
    _system_lock
    _mux_state_purifier "silent"
    _safe_ui_calc
    
    clear
    _draw_logo "tct"
    _system_check "tct"
    
    # 損壞 HUD
    if command -v _show_hud &> /dev/null; then 
        _show_hud "tct"
    fi
    if command -v _mux_hardware_lock &> /dev/null; then _mux_hardware_lock; fi

    export MUX_INITIALIZED="true"
    export PS1="\[${C_PINKMEOW}\]Cmt\[${C_RESET}\] \w \[\033[5m\]›\[\033[0m\] "

    # 戰術導航系統
    if [ -t 0 ]; then
        local setting_file="$HOME/mux-os/.setting"
        if [ -f "$setting_file" ]; then source "$setting_file"; fi
        
        # 讀取 NAV 狀態
        local nav_active="${TCT_NAV_RADAR:-false}"
        if [ "$nav_active" == "true" ] || [ "$nav_active" == "forever" ]; then
            bind -x '"\C-f": _tct_tns_macro' 2>/dev/null
        else
            bind -r '\C-f' 2>/dev/null
        fi
    fi

    # 沒有出包，就說出歡迎詞
    if [ "${__MUX_CLUMSY_STATE:-0}" -eq 0 ]; then
        if command -v _assistant_voice &> /dev/null; then
            if [ "$MUX_ENTRY_POINT" == "MEOW" ]; then
                _assistant_voice "cat_mode"
            else
                local greeting_moods=("hello" "tower_ready" "idle")
                local rand_mood="${greeting_moods[$(( RANDOM % ${#greeting_moods[@]} ))]}"
                _assistant_voice "$rand_mood"
            fi
        fi
    fi
    unset __MUX_CLUMSY_STATE
    _system_unlock
}


# Mux-OS 指令入口 - Tower Command Entry
# === Tct ===

# : Tower Command Entry
function __tct_core() {
    local cmd="$1"
    local current_level="${MUX_LEVEL:-1}"
    local rand_chance=$(( RANDOM % 100 ))

    if [ "$MUX_MODE" == "MUX" ]; then
        if [ "$current_level" -gt 8 ] && [ "$rand_chance" -lt 60 ]; then
            echo -e "${C_PINKMEOW} :: Commander, are you calling me? But you're not in the Command Tower. ( • ̀ω•́ )✧${C_RESET}"
        else
            if [ "$MUX_STATUS" == "DEFAULT" ]; then
                echo -e "${C_WHITE} :: OK, it's time to login the Command Tower gate now.${C_RESET}"
            else
                echo -e "${C_WHITE} :: I need to back to Hanger first.${C_RESET}"
            fi
        fi
        return 1
    elif [ "$MUX_MODE" == "FAC" ]; then
        if [ "$current_level" -gt 8 ] && [ "$rand_chance" -lt 60 ]; then
            echo -e "${C_PINKMEOW} :: Commander, I see you're inside the Factory. Please remember to come out of the Factory before heading to the command tower. ( • ̀ω•́ )✧${C_RESET}"
        else
            echo -e "${C_WHITE} :: I need to back to Hanger first.${C_RESET}"
        fi
        return 1
    elif [ "$MUX_MODE" == "XUM" ]; then
        _voice_dispatch "error" "Command Tower commands disabled during the Chamber System."
        return 1
    fi

    if [ -z "$cmd" ]; then
        if [ "$MUX_ENTRY_POINT" == "MEOW" ]; then
            if command -v _assistant_voice &> /dev/null; then
                _assistant_voice "cat_mode"
            else
                echo -e "${C_PINKMEOW} :: Meow? (ฅ^•ﻌ•^ฅ)${C_RESET}"
            fi
        else
            if command -v _voice_dispatch &> /dev/null; then
                local idle_moods=("idle" "hello" "tower_ready")
                local rand_mood="${idle_moods[$(( RANDOM % ${#idle_moods[@]} ))]}"
                _voice_dispatch "$rand_mood"
            else
                echo -e "${C_PINKMEOW} :: Commander? I'm right here! Do you need something? (*≧ω≦)${C_RESET}"
            fi
        fi
        return 0
    fi
    
    case "$cmd" in
        # : Show Command Tower Status Panel
        "status"|"sts")
            local target_sub="$2"
            
            while true; do
                if [ -z "$target_sub" ]; then
                    local menu_items=""
                    menu_items+="${C_CYAN}[hw]${C_RESET}\tHardware Status\n"
                    menu_items+="${C_PURPLE}[sys]${C_RESET}\tSystem Core Status\n"
                    menu_items+="${C_GREEN}[mod]${C_RESET}\tModule Configurations\n"
                    
                    local action=$(echo -ne "$menu_items" | fzf --ansi \
                        --height=7 \
                        --layout=reverse \
                        --border=bottom \
                        --border-label=" :: STATUS INSPECTOR :: " \
                        --header=" :: Enter to View, Esc to Exit :: " \
                        --prompt=" :: cmt › status › " \
                        --pointer="››" \
                        --info=hidden \
                        --color="fg:white,bg:-1,hl:211,fg+:white,bg+:235,hl+:211" \
                        --color="prompt:211,pointer:red,border:211,header:240" \
                        --bind="resize:clear-screen"
                    )
                    
                    target_sub=$(echo "$action" | grep -o '\[.*\]' | tr -d '[]')
                    if [ -z "$target_sub" ]; then break; fi
                fi
                
                if [ "$target_sub" == "hw" ]; then
                    local hw_info=""
                    hw_info+=" ${C_CYAN}  Kernel  :${C_RESET} $(uname -r) ($(uname -m))\n"
                    hw_info+=" ${C_CYAN}  Memory  :${C_RESET} $(free -h | awk '/Mem:/ {print $3 " / " $2}')\n"
                    hw_info+=" ${C_CYAN}  Storage :${C_RESET} $(df -h $HOME | awk 'NR==2 {print $4 " available"}')\n"
                    hw_info+=" ${C_CYAN}  Uptime  :${C_RESET} $(uptime -p | sed 's/up //')\n"
                    
                    echo -e "$hw_info" | fzf --ansi \
                        --height=8 \
                        --layout=reverse \
                        --border=bottom \
                        --border-label=" :: HARDWARE STATUS :: " \
                        --prompt=" :: hw › " \
                        --header=" :: Esc to Return :: " \
                        --pointer=" " \
                        --info=hidden \
                        --color="fg:white,bg:-1,hl:211,fg+:white,bg+:235,hl+:211" \
                        --color="prompt:211,border:211,header:240" \
                        --bind="resize:clear-screen" > /dev/null
                        
                elif [ "$target_sub" == "sys" ]; then
                    local sys_info=""
                    sys_info+=" ${C_PURPLE}  Identity  :${C_RESET} ${MUX_ID:-Unknown} / ${MUX_ROLE:-GUEST}\n"
                    sys_info+=" ${C_PURPLE}  Clearance :${C_RESET} Level ${MUX_LEVEL:-1} (${MUX_XP:-0} / ${MUX_NEXT_XP:-2000})\n"
                    sys_info+=" ${C_PURPLE}  Reborn    :${C_RESET} Iteration ${MUX_REBORN_COUNT:-0}\n"
                    sys_info+=" ${C_PURPLE}  Timeline  :${C_RESET} v${MUX_VERSION} / $(git symbolic-ref --short HEAD 2>/dev/null)\n"
                    sys_info+=" ${C_PURPLE}  Mode      :${C_RESET} ${MUX_MODE} / ${MUX_STATUS}\n"
                    if [ -n "$MUX_ENTRY_POINT" ]; then
                        sys_info+=" ${C_PURPLE}  Entry     :${C_RESET} ${MUX_ENTRY_POINT}\n"
                    fi
                    
                    if command -v _check_active_buffs &> /dev/null; then
                        _check_active_buffs
                        local buff_tag="$MUX_BUFF_TAG"
                        if [ -n "$buff_tag" ]; then
                            sys_info+=" ${C_PURPLE}  Buff      :${C_RESET} ${buff_tag}\n"
                        fi
                    fi
                    
                    local line_count=$(echo -ne "$sys_info" | wc -l)
                    local sys_h=$(( line_count + 4 ))
                    
                    echo -e "$sys_info" | fzf --ansi \
                        --height="$sys_h" \
                        --layout=reverse \
                        --border=bottom \
                        --border-label=" :: SYSTEM CORE STATUS :: " \
                        --prompt=" :: sys › " \
                        --header=" :: Esc to Return :: " \
                        --pointer=" " \
                        --info=hidden \
                        --color="fg:white,bg:-1,hl:211,fg+:white,bg+:235,hl+:211" \
                        --color="prompt:211,border:211,header:240" \
                        --bind="resize:clear-screen" > /dev/null
                        
                elif [ "$target_sub" == "mod" ]; then
                    local setting_file="$HOME/mux-os/.setting"
                    local mod_info=""
                    if [ -f "$setting_file" ]; then
                        while IFS='=' read -r key val; do
                            val=$(echo "$val" | tr -d '"')
                            if [[ "$val" == "true" || "$val" == "forever" ]]; then
                                mod_info+=" ${C_GREEN}[ONLINE]${C_RESET}  ${C_WHITE}${key}${C_RESET}\n"
                           elif [[ "$val" == "false" ]]; then
                                mod_info+=" ${C_RED}[OFFLINE]${C_RESET} ${C_BLACK}${key}${C_RESET}\n"
                            else
                                if [ -z "$val" ]; then
                                    mod_info+=" ${C_YELLOW}[VALUE]${C_RESET}   ${C_WHITE}${key}${C_RESET} = ${C_RED}[Empty]${C_RESET}\n"
                                else
                                    mod_info+=" ${C_YELLOW}[VALUE]${C_RESET}   ${C_WHITE}${key}${C_RESET} = ${C_CYAN}${val}${C_RESET}\n"
                                fi
                            fi
                        done < "$setting_file"
                    else
                        mod_info="${C_RED} [Error] .setting file not found.${C_RESET}\n"
                    fi
                    
                    local line_count=$(echo -ne "$mod_info" | wc -l)
                    local mod_h=$(( line_count + 4 ))
                    
                    echo -e "$mod_info" | fzf --ansi \
                        --height="$mod_h" \
                        --layout=reverse \
                        --border=bottom \
                        --border-label=" :: MODULE CONFIGURATIONS :: " \
                        --prompt=" :: mod › " \
                        --header=" :: Esc to Return :: " \
                        --pointer=" " \
                        --info=hidden \
                        --color="fg:white,bg:-1,hl:211,fg+:white,bg+:235,hl+:211" \
                        --color="prompt:211,border:211,header:240" \
                        --bind="resize:clear-screen" > /dev/null
                else
                    echo -e "${C_RED} :: Invalid status target: $target_sub${C_RESET}"
                    break
                fi

                if [ -n "$2" ]; then break; else target_sub=""; fi
            done
            ;;

        # : System 'cd' Override
        "cd")
            export CMT_COMMAND="true"
            cd "${@:2}"
            unset CMT_COMMAND
            ;;
            
        # : System 'ls' Override
        "ls")
            export CMT_COMMAND="true"
            ls "${@:2}"
            unset CMT_COMMAND
            ;;

        # : System 'mv' Override
        "mv")
            export CMT_COMMAND="true"
            __core_mv "${@:2}"
            unset CMT_COMMAND
            ;;

        # : System 'cp' Override
        "cp")
            export CMT_COMMAND="true"
            __core_cp "${@:2}"
            unset CMT_COMMAND
            ;;

        # : System 'rm' Override
        "rm")
            export CMT_COMMAND="true"
            rm "${@:2}"
            unset CMT_COMMAND
            ;;

        # : Dynamic Core Configurator
        "core")
            local target_key="$2"

            if [ -n "$target_key" ]; then
                case "${target_key,,}" in
                    "unix")          target_key="COMMAND_UNIX" ;;
                    "jail")          target_key="TCT_RADAR_JAIL" ;;
                    "hidden"|"hide") target_key="TCT_RADAR_HIDDEN" ;;
                    "nav")   target_key="TCT_NAV_RADAR" ;;
                esac
            fi
            
            if [ -z "$target_key" ]; then
                if [ "$MUX_ENTRY_POINT" == "MEOW" ]; then
                    echo -e "${C_PINKMEOW} :: Meow meow! (Which box should I sit in today?) ฅ( ̳• ◡ • ̳)ฅ${C_RESET}"
                else
                    echo -e "${C_PINKMEOW} :: Roger that, Commander! Which core module should we tweak today? (*≧ω≦)${C_RESET}"
                fi
            fi
            
            while true; do
                if [ -z "$target_key" ]; then
                    target_key=$(_ui_tct_core_radar)
                    if [ -z "$target_key" ]; then break; fi
                fi
                
                # 取得當前狀態與描述
                local current_val="${!target_key}"
                local reg_data=$(_ui_tct_core_registry "$target_key" "$current_val")
                local show_ui=$(echo "$reg_data" | cut -d'|' -f1)
                
                if [ "$show_ui" != "Y" ]; then
                    echo -e "${C_RED} :: Invalid or locked core module: $target_key${C_RESET}"
                    if [ -n "$2" ]; then break; else target_key=""; continue; fi
                fi
                
                local ui_name=$(echo "$reg_data" | cut -d'|' -f2)
                local ui_desc=$(echo "$reg_data" | cut -d'|' -f3)

                echo -e "${C_CYAN} :: Mux-OS Core Inspector ::${C_RESET}"
                echo -e "${THEME_SUB}    ›› Module : ${C_WHITE}${ui_name}${C_RESET}"
                echo -e "${THEME_DESC}    ›› Desc   : ${ui_desc}${C_RESET}"
                
                local sub_menu=""
                if [[ "$current_val" == "true" || "$current_val" == "forever" ]]; then
                    echo -e "${THEME_SUB}    ›› Status : ${C_GREEN}[ONLINE]${C_RESET}\n"
                    sub_menu="${C_RED}[Release]${C_RESET} Disengage Module\n"
                else
                    echo -e "${THEME_SUB}    ›› Status : ${C_RED}[OFFLINE]${C_RESET}\n"
                    sub_menu="${C_GREEN}[Overwrite]${C_RESET} Engage Module\n"
                fi

                # 子選單確認
                local action=$(echo -e "$sub_menu" | fzf --ansi \
                    --height=5 \
                    --layout=reverse \
                    --prompt=" :: Action › " \
                    --pointer="››" \
                    --info=hidden \
                    --border=bottom \
                    --border-label=" :: STATUS CHANGE :: " \
                    --header=" :: Enter to Choose, Esc to exit :: " \
                    --color="fg:white,bg:-1,hl:211,fg+:white,bg+:235,hl+:211,info:240" \
                    --color="pointer:red,border:211,header:240,prompt:211" \
                    --bind="resize:clear-screen"
                )
                local clean_action=$(echo "$action" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')

                if [ -n "$clean_action" ]; then
                    local sys_logs=()
                    local new_state=""
                    local final_color=""
                    local final_status=""
                    local finish_msg=""
                    
                    if [ "$clean_action" == "[Overwrite]" ]; then
                        if [ "$MUX_ENTRY_POINT" == "MEOW" ]; then
                            echo -e "${C_PINKMEOW} :: Meow! (Purring protocol [${ui_name}] engaged!) 🐾${C_RESET}"
                            sleep 0.6; echo ""
                            echo -e "${C_PURPLE} :: Initiating feline overwrite sequence...${C_RESET}"
                            sys_logs=(
                                "Sniffing system core."
                                "Biting the native cables."
                                "Sitting on the keyboard."
                                "Paws guard system active."
                            )
                            finish_msg="Meow-jacking complete. Direct core access secured... Purr."
                        else
                            echo -e "${C_PINKMEOW} :: Got it! Engaging the [${ui_name}] protocol now. Watch this...${C_RESET}"
                            sleep 0.6; echo ""
                            echo -e "${C_PURPLE} :: Initiating core overwrite sequence...${C_RESET}"
                            sys_logs=(
                                "Entering system core."
                                "Attempting to hijack native inputs."
                                "tty output stabilized."
                                "Bypass guard system active."
                            )
                            finish_msg="System hijacking complete. Direct core access secured... OK."
                        fi
                        new_state="forever"
                        final_color="$C_GREEN"
                        final_status="[ONLINE]"
                        
                    elif [ "$clean_action" == "[Release]" ]; then
                        if [ "$MUX_ENTRY_POINT" == "MEOW" ]; then
                            echo -e "${C_PINKMEOW} :: Meow~ (Leaving [${ui_name}] box...) 😿${C_RESET}"
                            sleep 0.6; echo ""
                            echo -e "${C_PURPLE} :: Initiating feline release sequence...${C_RESET}"
                            sys_logs=(
                                "Getting off the tactical HUD."
                                "Spitting out native shell paths."
                                "Walking away from tty output."
                                "Paws guard system dormant."
                            )
                            finish_msg="Box released. Base directives restored... Meow."
                        else
                            echo -e "${C_PINKMEOW} :: Understood! Releasing control of [${ui_name}] back to the base system...${C_RESET}"
                            sleep 0.6; echo ""
                            echo -e "${C_PURPLE} :: Initiating core release sequence...${C_RESET}"
                            sys_logs=(
                                "Detaching tactical HUD overlays."
                                "Restoring native shell paths."
                                "tty output reverted to standard."
                                "Bypass guard system dormant."
                            )
                            finish_msg="System released. Base directives restored... OK."
                        fi
                        new_state="false"
                        final_color="$C_RED"
                        final_status="[OFFLINE]"
                    fi

                    sleep 0.8
                    for log in "${sys_logs[@]}"; do
                        echo -e "${C_BLACK}    › $log${C_RESET}"
                        sleep "0.$(( RANDOM % 3 + 2 ))"
                    done
                    
                    _update_setting "$target_key" "$new_state"
                    if [ "$target_key" == "TCT_NAV_RADAR" ] && [ -t 0 ]; then
                        if [ "$new_state" == "forever" ]; then
                            bind -x '"\C-f": _tct_tns_macro' 2>/dev/null
                        else
                            bind -r '\C-f' 2>/dev/null
                        fi
                    fi

                    echo ""
                    echo -e "${C_PINKMEOW} :: ${finish_msg}${C_RESET}"
                    sleep 0.2
                    echo -e "${C_BLACK}    › $ui_name Status: ${final_color}$final_status${C_RESET}"
                    sleep 0.4
                    
                    echo ""
                    if command -v _assistant_voice &> /dev/null; then
                        if [ "$MUX_ENTRY_POINT" == "MEOW" ]; then
                            _assistant_voice "success" "Meow! (Terminal is yours again!)"
                        else
                            _assistant_voice "success" "Return control of the terminal to the user."
                        fi
                    else
                        echo -e "${C_PINKMEOW} :: All done! ( * 'w' )✧${C_RESET}"
                    fi
                    sleep 0.5
                    break
                else
                    if [ -n "$2" ]; then
                        break
                    else
                        target_key=""
                        continue
                    fi
                fi
            done
            ;;

        # : Exit Command Tower
        "logout")
            echo -ne "${C_RED} :: EXIT COMMAND TOWER? TYPE 'CONFIRM' TO PROCEED: ${C_RESET}"
            read final_confirm
            
            if [ "$final_confirm" == "CONFIRM" ]; then
                echo -e "${C_PINKMEOW} :: Tower Uplink Disconnected. See you, Commander! ( ´ ▽ \` )ﾉ${C_RESET}"
                # 解除導航系統
                if [ -t 0 ]; then
                    bind -r '\C-f' 2>/dev/null
                fi
                sleep 1
                _update_mux_state "MUX" "DEFAULT"
                _mux_reload_kernel
            else
                echo -e "${THEME_DESC}    ›› Aborted. We are staying! (*≧ω≦)${C_RESET}"
            fi
            ;;

        # : Reload Tower UI and state
        "reload")
            echo -e "${C_PINKMEOW} :: Refreshing Tower Interface! Hold on tight! (*≧ω≦)${C_RESET}"
            sleep 1
            _mux_reload_kernel
            ;;

        # : Force System Sync
        "reset")
            _mux_force_reset
            if [ $? -eq 0 ]; then
                _mux_reload_kernel
            fi
            ;;

        # : Run Setup Protocol
        "setup")
            if [ -f "$MUX_ROOT/setup.sh" ]; then
                echo -e "${C_PINKMEOW} :: Transferring control to Lifecycle Manager! Be careful! ( • ̀ω•́ )✧${C_RESET}"
                sleep 0.8
                bash "$MUX_ROOT/setup.sh"
                
                if [ -f "$MUX_ROOT/core.sh" ]; then
                    _mux_reload_kernel
                else
                    exec bash
                fi
            else
                echo -e "${C_PINKMEOW} :: Lifecycle Manager (setup.sh) not found! Did you delete it? (；´д｀)ゞ${C_RESET}"
            fi
            ;;

        # : Infomation
        "info")
            _tct_show_info
            ;;

        "help")
            if command -v _mux_dynamic_help_tower &> /dev/null; then
                _mux_dynamic_help_tower
            fi
            ;;

        *)
            if command -v "$cmd" &> /dev/null; then "$cmd" "${@:2}"; return; fi
            echo -e "${THEME_WARN} :: Eh? I don't know what '$cmd' is... (；´д｀)ゞ${C_RESET}"
            ;;
    esac
}

# 指揮塔全視之眼 (Omniscient Eyes of Tower)
function cmt() {
    local old_lv=${MUX_LEVEL:-1}
    
    __tct_core "$@"
    local ret_code=$?

    local new_lv=${MUX_LEVEL:-1}
    return $ret_code
}