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

# 戰術雷達直通引擎 (Radar Override Parser)
function _tct_override_parser() {
    local input_query="$1"
    if [ -z "$input_query" ]; then return 1; fi

    local main_cmd="${input_query%% *}"
    # 偵測指令
    if [[ "$main_cmd" =~ ^(cd|ls|rm|cp|mv)$ ]]; then
        # 參數確保
        if [ "${#input_query}" -gt "${#main_cmd}" ] || [ "$main_cmd" == "ls" ]; then
            # 直通指令
            echo -e "\n${C_RED} :: OVERRIDE ACTIVATED :: ${C_WHITE}$input_query${C_RESET}"
            eval "$input_query"
            return 0
        fi
    fi
    return 1
}

# 動態參數探針 (Universal Subcommand & Pager Bypass)
function _tct_tns_probe() {
    local target_cmd="$1"
    if [ -z "$target_cmd" ]; then return 1; fi

    local help_text=""
    
    if [[ "$target_cmd" == git\ * ]]; then
        help_text=$(command $target_cmd -h 2>&1)
    else
        help_text=$(PAGER=cat command $target_cmd --help 2>&1)
    fi
    
    help_text=$(echo "$help_text" | sed 's/.\x08//g')

    if [[ "$help_text" == *"not found"* ]] || [[ "$help_text" == *"illegal option"* ]] || [[ "$help_text" == *"invalid option"* ]] || [[ "$help_text" == *"unrecognized option"* ]] || [ ${#help_text} -lt 20 ]; then
        local builtin_help=$(help $target_cmd 2>&1)
        if [[ "$builtin_help" != *"no help topics"* ]] && [ -n "$builtin_help" ]; then
            help_text="$builtin_help"
        fi
    fi

    # 雙軌解析引擎
    local parsed_params
    parsed_params=$(echo "$help_text" | awk -v c_flag="\033[1;33m" -v c_rst="\033[0m" -v c_desc="\033[1;37m" '
        {
            line = $0
            
            # 分支 1：標準參數
            if (line ~ /^[ \t]*-+[a-zA-Z0-9]/) {
                sub(/^[ \t]+/, "", line)
                split_idx = match(line, /[ \t]{2,}|\t/)
                
                if (split_idx > 0) {
                    flag = substr(line, 1, split_idx - 1)
                    desc = substr(line, split_idx + RLENGTH)
                } else {
                    space_idx = index(line, " ")
                    if (space_idx > 0) {
                        flag = substr(line, 1, space_idx - 1)
                        desc = substr(line, space_idx + 1)
                    } else { flag = line; desc = "" }
                }
                sub(/^[ \t=]+/, "", desc) 
                if (length(desc) > 65) { desc = substr(desc, 1, 62) "..." }
                printf "%s[%-24s]%s   %s\n", c_flag, flag, c_rst, desc
            }
            else if (line ~ /^[ \t]+[a-zA-Z0-9_-]+/) {
                sub(/^[ \t]+/, "", line)
                
                # 尋找分隔點
                split_idx = match(line, /[ \t]{2,}-?[ \t]*|[ \t]+-[ \t]+/)
                
                if (split_idx > 0) {
                    flag = substr(line, 1, split_idx - 1)
                    
                    # 判斷是否為合法的指令行
                    is_valid = 0
                    matched_sep = substr(line, split_idx, RLENGTH)
                    
                    # 條件 A
                    if (matched_sep ~ /-/) {
                        is_valid = 1
                    } 
                    # 條件 B
                    else if (index(flag, " ") == 0) {
                        is_valid = 1
                    }
                    
                    if (is_valid == 1) {
                        desc = substr(line, split_idx + RLENGTH)
                        sub(/^[ \t=:-]+/, "", desc) 
                        if (length(desc) > 65) { desc = substr(desc, 1, 62) "..." }
                        printf "%s[%-24s]%s   %s\n", c_flag, flag, c_rst, desc
                    }
                }
            }
        }
    ')

    if [ -n "$parsed_params" ]; then echo -e "$parsed_params"
    else echo -e "\033[1;30m[Empty                   ]\033[0m   No parameters found."; fi
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
        params="\033[1;30m[Empty                   ]\033[0m   No command specified."
        target_cmd="Null"
    else
        params=$(_tct_tns_probe "$target_cmd")
        if [ -z "$params" ]; then params="\033[1;30m[Empty                   ]\033[0m   No parameters found."; fi
    fi

    # 動態高度計算
    local line_count=$(echo -e "$params" | wc -l)
    local dynamic_height=$(( line_count + 4 ))
    if [ "$dynamic_height" -gt 12 ]; then dynamic_height=12; fi

    # 展開參數雷達
    local selected
    selected=$(echo -e "$params" | fzf --ansi \
            --height="$dynamic_height" \
            --layout=reverse \
            --prompt=" :: CMD › $target_cmd › " \
            --header=" :: Enter to Choose, Esc to exit :: " \
            --info=hidden \
            --pointer="››" \
            --border=bottom \
            --border-label=" :: PARAMETER HUD :: " \
            --color="fg:white,bg:-1,hl:51,fg+:white,bg+:235,hl+:51,info:240" \
            --color="pointer:red,border:51,header:240,prompt:51"
            )

    # 寫回終端機
    if [ -n "$selected" ]; then
        local clean_flag=$(echo "$selected" | sed 's/\x1b\[[0-9;]*m//g' | awk -F'[][]' '{print $2}' | awk '{print $1}' | sed 's/,$//')
        if [ "$clean_flag" == "Empty" ]; then return; fi
        
        if [ -n "$clean_flag" ]; then
            local left_part="${READLINE_LINE:0:$READLINE_POINT}"
            local right_part="${READLINE_LINE:$READLINE_POINT}"
            
            if [[ -n "$left_part" ]] && [[ "$left_part" != *" " ]]; then left_part="${left_part} "; fi

            READLINE_LINE="${left_part}${clean_flag} ${right_part}"
            READLINE_POINT=$((${#left_part} + ${#clean_flag} + 1))
        fi
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
            action_items+="${C_CYAN}[ct]${C_RESET} View Content '$clean_target'\n"
            action_items+="${C_YELLOW}[nn]${C_RESET} Edit File '$clean_target'\n"
        fi
        
        # 共用戰術兵器庫
        action_items+="${C_GREEN}[cp]${C_RESET} Tactical Cloner\n"
        action_items+="${C_ORANGE}[mv]${C_RESET} Tactical Relocator\n"
        action_items+="${C_RED}[rm]${C_RESET} Tactical Destructor\n"
        
        local ui_prompt=" :: Action › $clean_target :: "
        [ "$CMT_COMMAND" == "true" ] && ui_prompt=" :: cmt › Action › $clean_target :: "
        
        # 呼叫TCT模組
        local action_raw=$(_ui_tct_nav_radar "$action_items" "$ui_prompt" "10" "TARGET OPERATIONS" "220" " :: Esc to Return ::")
        
        local action_query=$(echo "$action_raw" | head -n 1)
        local action_sel=$(echo "$action_raw" | tail -n +2 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
        
        # 直通指令回傳
        if _tct_override_parser "$action_query"; then return 2; fi
        if [ -z "$action_sel" ]; then return 0; fi 
        
        # 火力分發
        if [[ "$action_sel" == "[cd]"* ]]; then
            # 執行導航
            builtin cd "$clean_target"
            _update_setting "TCT_RADAR_HIDDEN" "false"
            return 3
        elif [[ "$action_sel" == "[ct]"* ]]; then
            echo -e "${C_CYAN} :: READING: $clean_target ${C_RESET}"
            command cat "$clean_target" | less -R -F -X
            break
        elif [[ "$action_sel" == "[nn]"* ]]; then
            nano "$clean_target"
            break
        elif [[ "$action_sel" == "[cp]"* ]]; then
            export CMT_COMMAND="true"
            __core_cp
            unset CMT_COMMAND
            break
        elif [[ "$action_sel" == "[mv]"* ]]; then
            export CMT_COMMAND="true"
            __core_mv
            unset CMT_COMMAND
            break
        elif [[ "$action_sel" == "[rm]"* ]]; then
            export CMT_COMMAND="true"
            __core_rm
            unset CMT_COMMAND
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

    # 邏輯判定
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
    if [ "$TCT_RADAR_HIDDEN" == "forever" ] || [ "$TCT_RADAR_HIDDEN" == "true" ]; then show_hidden="true"; fi

    local jail_active="false"
    local current_jail="${TCT_RADAR_JAIL:-true}"
    if [ "$current_jail" == "forever" ] || [ "$current_jail" == "true" ]; then jail_active="true"; fi

    if [ "$allow_radar" == "true" ] && command -v _grant_xp &> /dev/null; then
        _grant_xp 5 "SHELL"
    fi

    while true; do
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
                menu_items+="${C_BLACK}[-1]${C_RESET} Unlock Jail"
            else
                menu_items+="${C_BLACK}[-0]${C_RESET} Lock Jail"
            fi
        fi

        local line_count=$(echo -e "$menu_items" | wc -l)
        local dynamic_height=$(( line_count + 4 ))
        [ "$dynamic_height" -gt 35 ] && dynamic_height="80%"

        local ui_prompt=" :: $display_prompt › "
        [ "$CMT_COMMAND" == "true" ] && ui_prompt=" :: cmt › cd › $display_prompt :: "

        # 呼叫TCT模組
        local raw_output
        raw_output=$(_ui_tct_nav_radar "$menu_items" "$ui_prompt" "$dynamic_height" "TARGET DIRECTORY" "211" " :: Enter to Select, Esc to Return ::")

        local user_query=$(echo "$raw_output" | head -n 1)
        local raw_target=$(echo "$raw_output" | tail -n +2)

        if _tct_override_parser "$user_query"; then break; fi
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
                
                local mk_ui_prompt=" :: Make › ${PWD/#$HOME/\~} :: "
                [ "$CMT_COMMAND" == "true" ] && mk_ui_prompt=" :: cmt › Make › ${PWD/#$HOME/\~} :: "
                
                local mk_raw
                mk_raw=$(_ui_tct_nav_radar "$mk_items" "$mk_ui_prompt" "7" "CREATION FORGE" "51" " :: Esc to Return ::")
                
                local mk_query=$(echo "$mk_raw" | head -n 1)
                local mk_sel=$(echo "$mk_raw" | tail -n +2 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                if _tct_override_parser "$mk_query"; then break 2; fi
                if [ -z "$mk_sel" ]; then break; fi 
                
                if [[ "$mk_sel" == "[touch]"* ]]; then
                    local p_touch=$(echo -e "\001${C_CYAN}\002 :: NEW FILE(S) NAME › \001${C_RESET}\002")
                    read -e -p "$p_touch" new_target
                    if [ -n "$new_target" ]; then
                        echo -e "${C_RED} :: EXECUTING: touch $new_target ${C_RESET}"
                        eval "command touch $new_target"
                        if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                    fi
                    break
                elif [[ "$mk_sel" == "[mkdir]"* ]]; then
                    local p_mkdir=$(echo -e "\001${C_YELLOW}\002 :: NEW DIRECTORY(S) NAME › \001${C_RESET}\002")
                    read -e -p "$p_mkdir" new_target
                    if [ -n "$new_target" ]; then
                        echo -e "${C_RED} :: EXECUTING: mkdir -p $new_target ${C_RESET}"
                        eval "command mkdir -p $new_target"
                        if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                    fi
                    break
                fi
            done
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
    # 狀態機讀取與防爆閘門
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
    if [ "$TCT_RADAR_HIDDEN" == "forever" ] || [ "$TCT_RADAR_HIDDEN" == "true" ]; then show_hidden="true"; fi

    local jail_active="false"
    local current_jail="${TCT_RADAR_JAIL:-true}"
    if [ "$current_jail" == "forever" ] || [ "$current_jail" == "true" ]; then jail_active="true"; fi

    if [ "$allow_radar" == "true" ] && command -v _grant_xp &> /dev/null; then
        _grant_xp 5 "SHELL"
    fi

    while true; do
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
                menu_items+="${C_BLACK}[-1]${C_RESET} Unlock Jail"
            else
                menu_items+="${C_BLACK}[-0]${C_RESET} Lock Jail"
            fi
        fi

        local line_count=$(echo -e "$menu_items" | wc -l)
        local dynamic_height=$(( line_count + 4 ))
        [ "$dynamic_height" -gt 35 ] && dynamic_height="80%"

        local ui_prompt=" :: $display_prompt › "
        [ "$CMT_COMMAND" == "true" ] && ui_prompt=" :: cmt › ls › $display_prompt :: "

        local raw_output
        raw_output=$(_ui_tct_nav_radar "$menu_items" "$ui_prompt" "$dynamic_height" "FILE SCANNER" "46" " :: Enter to Inspect, Esc to Return ::")

        local user_query=$(echo "$raw_output" | head -n 1)
        local raw_target=$(echo "$raw_output" | tail -n +2)

        if _tct_override_parser "$user_query"; then break; fi
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
                
                local mk_query=$(echo "$mk_raw" | head -n 1)
                local mk_sel=$(echo "$mk_raw" | tail -n +2 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
                
                if _tct_override_parser "$mk_query"; then break 2; fi
                if [ -z "$mk_sel" ]; then break; fi 
                
                if [[ "$mk_sel" == "[touch]"* ]]; then
                    local p_touch=$(echo -e "\001${C_CYAN}\002 :: NEW FILE(S) NAME › \001${C_RESET}\002")
                    read -e -p "$p_touch" new_target
                    if [ -n "$new_target" ]; then
                        echo -e "${C_RED} :: EXECUTING: touch $new_target ${C_RESET}"
                        eval "command touch $new_target"
                        if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                    fi
                    break
                elif [[ "$mk_sel" == "[mkdir]"* ]]; then
                    local p_mkdir=$(echo -e "\001${C_YELLOW}\002 :: NEW DIRECTORY(S) NAME › \001${C_RESET}\002")
                    read -e -p "$p_mkdir" new_target
                    if [ -n "$new_target" ]; then
                        echo -e "${C_RED} :: EXECUTING: mkdir -p $new_target ${C_RESET}"
                        eval "command mkdir -p $new_target"
                        if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                    fi
                    break
                fi
            done
            continue
        elif [ "$target" == "[cd] Revert to Origin" ]; then
            builtin cd "$origin_pwd"; continue
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
    if [ "$#" -gt 0 ]; then
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
                    # 目錄：使用 rmdir
                    command rmdir "$item" 2>/dev/null
                    local ret=$?
                    if [ $ret -ne 0 ]; then
                        echo -e "${C_YELLOW}    ›› [BLOCKED] '$item' is not empty. (Requires -r mode)${C_RESET}"
                    else
                        echo -e "${C_BLACK}    ›› [WIPED] '$item' (Empty Shell Destroyed)${C_RESET}"
                        if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                    fi
                elif [ -f "$item" ] || [ -L "$item" ]; then
                    # 檔案：軟隔離轉移
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
    if [ "$TCT_RADAR_HIDDEN" == "forever" ] || [ "$TCT_RADAR_HIDDEN" == "true" ]; then show_hidden="true"; fi

    local jail_active="false"
    local current_jail="${TCT_RADAR_JAIL:-true}"
    if [ "$current_jail" == "forever" ] || [ "$current_jail" == "true" ]; then jail_active="true"; fi

    local current_rm_mode="i" 

    while true; do
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

        if [ "$TCT_RADAR_HIDDEN" != "forever" ]; then
            if [ "$show_hidden" == "true" ]; then
                targets=$(command ls -1A --color=always 2>/dev/null)
            else
                targets=$(command ls -1 --color=always 2>/dev/null)
            fi
        fi

        if [ "$TCT_RADAR_JAIL" != "forever" ]; then
            if [ "$jail_active" == "true" ]; then
                menu_items+="${C_BLACK}[-1]${C_RESET} Unlock Jail\n"
            else
                menu_items+="${C_BLACK}[-0]${C_RESET} Lock Jail\n"
            fi
        fi

        local display_prompt="${PWD/#$HOME/\~}"
        local ui_prompt=" :: rm -$current_rm_mode › $display_prompt :: "
        if [ "$CMT_COMMAND" == "true" ]; then
            ui_prompt=" :: cmt › rm -$current_rm_mode › $display_prompt :: "
        fi

        local line_count=$(echo -e "$menu_items" | wc -l)
        local dynamic_height=$(( line_count + 4 ))
        [ "$dynamic_height" -gt 35 ] && dynamic_height="80%"

        # 呼叫TCT模組
        local raw_output
        raw_output=$(_ui_tct_tactical_radar "$menu_items" "$ui_prompt" "$dynamic_height" "TACTICAL DESTRUCTOR" "196")

        local user_query=$(echo "$raw_output" | head -n 1)
        local selections=$(echo "$raw_output" | tail -n +2)

        if _tct_override_parser "$user_query"; then return 0; fi
        if [ -z "$selections" ]; then break; fi

        local mode_changed="false"
        local selected_targets=()

        # 解析多選陣列
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

            # 提取實際目標
            local target_item=$(echo "$clean_line" | sed 's/^\[  \] //')
            if [ -n "$target_item" ] && [[ ! "$target_item" == \[*\]* ]]; then
                selected_targets+=("$target_item")
            fi
        done <<< "$selections"

        if [ "$mode_changed" == "true" ] && [ ${#selected_targets[@]} -eq 0 ]; then
            continue
        fi

        # 執行刪除
        if [ ${#selected_targets[@]} -gt 0 ]; then
            echo -e "${C_RED} :: DESTRUCTOR INITIATED › MODE: -$current_rm_mode ${C_RESET}"
            echo -e "${C_BLACK}    ›› Targets: ${#selected_targets[@]} items.${C_RESET}"
            
            if [[ "$current_rm_mode" == "i" ]]; then
                # [-i] 模式：軟隔離確認
                echo -ne "${C_RED} :: Initiate soft-deletion for these ${#selected_targets[@]} targets? [Y/n]: ${C_RESET}"
                read -r confirm
                if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                    echo -e "${C_GREEN} :: Destructor aborted. Target(s) secured.${C_RESET}"
                    break
                fi
            else
                # [-f], [-r], [rf] 模式：實體抹除的最終防線
                echo -e "${C_RED} :: WARNING: Permanent deletion selected. Targets will NOT be sent to .trash.${C_RESET}"
                echo -ne "${C_RED} :: TYPE 'CONFIRM' TO OBLITERATE: ${C_RESET}"
                read -r confirm
                if [ "$confirm" != "CONFIRM" ]; then
                    echo -e "${C_GREEN} :: Destructor aborted. Target(s) secured.${C_RESET}"
                    break
                fi
            fi
            rm "-$current_rm_mode" "${selected_targets[@]}"
            
            if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
            break
        fi
    done
}

# 原生指令劫持: mv (Command mv for TCT)
function __core_mv() {
    # 軌道直通
    if [ "$#" -gt 0 ]; then
        command mv "$@"
        local ret=$?
        if [ $ret -eq 0 ] && command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
        return $ret
    fi

    local current_mv_mode="i" 
    local show_hidden="${TCT_RADAR_HIDDEN:-false}"

    while true; do
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

        local line_count=$(echo -e "$menu_items" | wc -l)
        local dynamic_height=$(( line_count + 4 ))
        [ "$dynamic_height" -gt 35 ] && dynamic_height="80%"

        # 呼叫TCT模組
        local raw_output
        raw_output=$(_ui_tct_tactical_radar "$menu_items" "$ui_prompt" "$dynamic_height" "TACTICAL RELOCATOR" "220")

        local user_query=$(echo "$raw_output" | head -n 1)
        local selections=$(echo "$raw_output" | tail -n +2)

        if _tct_override_parser "$user_query"; then return 0; fi
        if [ -z "$selections" ]; then break; fi

        local mode_changed="false"
        local selected_targets=()

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

        if [ "$mode_changed" == "true" ] && [ ${#selected_targets[@]} -eq 0 ]; then
            continue
        fi

        # 目的地輸入階段
        if [ ${#selected_targets[@]} -gt 0 ]; then
            echo -e "${C_YELLOW} :: RELOCATOR INITIATED › MODE: -$current_mv_mode ${C_RESET}"
            echo -e "${C_BLACK}    ›› Sources: ${selected_targets[*]}.${C_RESET}"
            
            local default_input=""
            [ ${#selected_targets[@]} -eq 1 ] && default_input="${selected_targets[0]}"

            echo -ne "${C_YELLOW} :: DESTINATION (Path / New Name) › ${C_RESET}"
            read -e -i "$default_input" dest_target
            
            if [ -n "$dest_target" ] && [ "$dest_target" != "$default_input" ]; then
                echo -e "${C_RED} :: EXECUTING: mv -$current_mv_mode ${selected_targets[*]} $dest_target${C_RESET}"
                command mv "-$current_mv_mode" "${selected_targets[@]}" "$dest_target"
                if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                break
            else
                echo -e "${C_GREEN} :: Relocator aborted. No valid destination.${C_RESET}"
            fi
        fi
    done
}

# 原生指令劫持: cp (Command cp for TCT)
function __core_cp() {
    # 軌道直通
    if [ "$#" -gt 0 ]; then
        command cp "$@"
        local ret=$?
        if [ $ret -eq 0 ] && command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
        return $ret
    fi

    local current_cp_mode="i" 
    local show_hidden="${TCT_RADAR_HIDDEN:-false}"

    while true; do
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

        local line_count=$(echo -e "$menu_items" | wc -l)
        local dynamic_height=$(( line_count + 4 ))
        [ "$dynamic_height" -gt 35 ] && dynamic_height="80%"

        # 呼叫TCT模組
        local raw_output
        raw_output=$(_ui_tct_tactical_radar "$menu_items" "$ui_prompt" "$dynamic_height" "TACTICAL CLONER" "33")

        local user_query=$(echo "$raw_output" | head -n 1)
        local selections=$(echo "$raw_output" | tail -n +2)

        if _tct_override_parser "$user_query"; then return 0; fi
        if [ -z "$selections" ]; then break; fi

        local mode_changed="false"
        local selected_targets=()

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

        if [ "$mode_changed" == "true" ] && [ ${#selected_targets[@]} -eq 0 ]; then
            continue
        fi

        # 目的地輸入階段
        if [ ${#selected_targets[@]} -gt 0 ]; then
            echo -e "${C_GREEN} :: CLONER INITIATED › MODE: -$current_cp_mode ${C_RESET}"
            echo -e "${C_BLACK}    ›› Sources: ${selected_targets[*]}.${C_RESET}"
            
            local default_input=""
            [ ${#selected_targets[@]} -eq 1 ] && default_input="${selected_targets[0]}"

            echo -ne "${C_GREEN} :: DESTINATION (Path / New Name) › ${C_RESET}"
            read -e -i "$default_input" dest_target
            
            if [ -n "$dest_target" ] && [ "$dest_target" != "$default_input" ]; then
                echo -e "${C_RED} :: EXECUTING: cp -$current_cp_mode ${selected_targets[*]} $dest_target${C_RESET}"
                command cp "-$current_cp_mode" "${selected_targets[@]}" "$dest_target"
                if command -v _grant_xp &> /dev/null; then _grant_xp 5 "SHELL"; fi
                break
            else
                echo -e "${C_YELLOW} :: Cloner aborted. No valid destination.${C_RESET}"
            fi
        fi
    done
}

# 指揮塔初始化 (Tower Initialization)
function _tct_init() {
    _system_lock
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
        bind -x '"\C-f": _tct_tns_macro' 2>/dev/null
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
        if [ "$current_level" -ge 8 ] && [ "$rand_chance" -lt 60 ]; then
            if [ "$MUX_STATUS" == "DEFAULT" ]; then
                echo -e "${C_WHITE} :: OK, it's time to login the Command Tower gate now.${C_RESET}"
            else
                echo -e "${C_WHITE} :: I need to back to Hanger first.${C_RESET}"
            fi
        else
            echo -e "${C_PINKMEOW} :: Commander, are you calling me? But you're not in the Command Tower. ( • ̀ω•́ )✧"
        fi
        return 1
    elif [ "$MUX_MODE" == "FAC" ]; then
        if [ "$current_level" -ge 8 ] && [ "$rand_chance" -lt 60 ]; then
            echo -e "${C_WHITE} :: I need to back to Hanger first.${C_RESET}"
        else
            echo -e "${C_PINKMEOW} :: Commander, I see you're inside the Factory. Please remember to come out of the Factory before heading to the command tower. ( • ̀ω•́ )✧"
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

        # : Overwrite Command Toggle
        "set")
            local target_cmd="$2"
            if [ -z "$target_cmd" ]; then
                echo -e "${C_PINKMEOW} :: Commander, set what? (・_・)${C_RESET}"
                return 1
            fi
            
            case "$target_cmd" in
                "unix")
                    _update_setting "COMMAND_UNIX" "forever"
                    echo -e "${C_GREEN} :: UNIX Tactical Radar [ONLINE] (cd, ls, rm)${C_RESET}"
                    ;;

                "jail")
                    _update_setting "TCT_RADAR_JAIL" "forever"
                    echo -e "${C_PINKMEOW} :: Radar Jail Locked FOREVER! (*≧ω≦)${C_RESET}"
                    ;;

                "hidden")
                    _update_setting "TCT_RADAR_HIDDEN" "forever"
                    echo -e "${C_PINKMEOW} :: Hidden files revealed FOREVER! (*≧ω≦)${C_RESET}"
                    ;;

                *)
                    echo -e "${C_PINKMEOW} :: I don't know how to unset '$target_cmd'... (；´д｀)ゞ${C_RESET}"
                    return 1
                    ;;
            esac
            ;;

        # : Overwrite Command Toggle
        "unset")
            local target_cmd="$2"
            if [ -z "$target_cmd" ]; then
                echo -e "${C_PINKMEOW} :: Commander, unset what? (・_・)${C_RESET}"
                return 1
            fi
            
            case "$target_cmd" in
                "unix")
                    _update_setting "COMMAND_UNIX" "false"
                    echo -e "${C_GREEN} :: UNIX Tactical Radar [OFFLINE] (cd, ls, rm)${C_RESET}"
                    ;;

                "jail")
                    _update_setting "TCT_RADAR_JAIL" "false"
                    echo -e "${C_YELLOW} :: Radar Jail [OFFLINE]${C_RESET}"
                    ;;

                "hidden")
                    _update_setting "TCT_RADAR_HIDDEN" "false"
                    echo -e "${C_YELLOW} :: Hidden files revealed [OFFLINE]${C_RESET}"
                    ;;

                *)
                    echo -e "${C_PINKMEOW} :: I don't know how to unset '$target_cmd'... (；´д｀)ゞ${C_RESET}"
                    return 1
                    ;;
                
            esac
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