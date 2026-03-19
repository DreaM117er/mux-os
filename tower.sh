# tower.sh - Mux-OS 指揮塔模組 (The Command Tower)
# 權限：Lv.16 Architect & The Clumsy Co-pilot

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

# 原生指令劫持: cd (Command cd for TCT)
function cd() {
    # 模式鎖定
    if [ "$MUX_MODE" != "TCT" ] || [ "$#" -gt 0 ] || [ "$CMT_COMMAND" != "true" ] || [ "$COMMAND_CD" != "true" ]; then
        builtin cd "$@"
        return $?
    fi

    # 狀態機讀取
    local setting_file="$HOME/mux-os/.setting"
    if [ -f "$setting_file" ]; then source "$setting_file"; fi

    # 原點及旗標
    local origin_pwd="$HOME"
    local show_hidden="${TCT_RADAR_HIDDEN:-false}"
    local jail_active="${TCT_RADAR_JAIL:-true}"

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
        fi

        local menu_items=""
        if [ -n "$formatted_dirs" ]; then 
            menu_items+="${formatted_dirs}\n"
            menu_items+="${C_BLACK}----------${C_RESET}\n"
        fi

        menu_items+="${C_GREEN}[ls]${C_RESET} Show Files\n"

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

        if [ "$show_hidden" == "true" ]; then
            menu_items+="${C_BLACK}[.*]${C_RESET} Hide Hidden"
        else
            menu_items+="${C_BLACK}[.*]${C_RESET} Show Hidden"
        fi

        local line_count=$(echo -e "$menu_items" | wc -l)
        local dynamic_height=$(( line_count + 4 ))

        local ui_prompt=" :: $display_prompt › "
        if [ "$CMT_COMMAND" == "true" ] && [ "$COMMAND_CD" == "true" ]; then
            ui_prompt=" :: cmt › cd › $display_prompt :: "
        fi

        local raw_target
        raw_target=$(echo -e "$menu_items" | fzf --ansi \
            --height="$dynamic_height" \
            --layout=reverse \
            --prompt="$ui_prompt" \
            --info=hidden \
            --header=" :: Enter to Select, Esc to Return ::" \
            --border=bottom \
            --border-label=" :: TARGET DIRECTORY :: " \
            --pointer="››" \
            --color=fg:white,bg:-1,hl:211,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:211,pointer:red,marker:211,border:211,header:240 \
            --bind="resize:clear-screen"
            )

        if [ -z "$raw_target" ]; then break; fi

        local target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')

        if [ "$target" == "----------" ]; then continue; fi
        
        if [ "$target" == "[ls] Show Files" ]; then
            if [ "$CMT_COMMAND" == "true" ]; then
                export COMMAND_CD="false"
                export COMMAND_LS="true"
            fi
            ls
            if [ "$CMT_COMMAND" == "true" ]; then
                export COMMAND_CD="true"
                export COMMAND_LS="false"
            fi
            break
        elif [ "$target" == "[cd] Revert to Origin" ]; then
            builtin cd "$origin_pwd"
            continue
        elif [ "$target" == "[..] Backto" ]; then
            builtin cd ..
            export TCT_RADAR_HIDDEN="false"; show_hidden="false"
            if command -v _save_settings &> /dev/null; then _save_settings; fi
        elif [ "$target" == "[.*] Show Hidden" ]; then
            export TCT_RADAR_HIDDEN="true"; show_hidden="true"
            if command -v _save_settings &> /dev/null; then _save_settings; fi
            continue
        elif [ "$target" == "[.*] Hide Hidden" ]; then
            export TCT_RADAR_HIDDEN="false"; show_hidden="false"
            if command -v _save_settings &> /dev/null; then _save_settings; fi
            continue
        else
            local clean_dir=$(echo "$target" | sed 's/^\[  \] //')
            builtin cd "$clean_dir"
            export TCT_RADAR_HIDDEN="false"; show_hidden="false"
            if command -v _save_settings &> /dev/null; then _save_settings; fi
        fi
    done
}

# 原生指令劫持: ls (Command ls for TCT)
function ls() {
    # 模式鎖定
    if [ "$MUX_MODE" != "TCT" ] || [ "$#" -gt 0 ] || [ "$CMT_COMMAND" != "true" ] || [ "$COMMAND_LS" != "true" ]; then
        command ls --color=auto "$@"
        return $?
    fi

    local setting_file="$HOME/mux-os/.setting"
    if [ -f "$setting_file" ]; then source "$setting_file"; fi

    local origin_pwd="$HOME"
    local show_hidden="${TCT_RADAR_HIDDEN:-false}"
    local jail_active="${TCT_RADAR_JAIL:-true}"

    while true; do
        local files
        if [ "$show_hidden" == "true" ]; then
            files=$(command ls -1A --color=always 2>/dev/null)
        else
            files=$(command ls -1 --color=always 2>/dev/null | grep -v '^\.')
        fi

        local formatted_files=""
        if [ -n "$files" ]; then
            formatted_files=$(echo "$files" | sed 's/^/\x1b[1;30m[  ]\x1b[0m /')
        fi

        local menu_items=""
        
        if [ -n "$formatted_files" ]; then 
            menu_items+="${formatted_files}\n"
            menu_items+="${C_BLACK}----------${C_RESET}\n"
        fi

        menu_items+="${C_PINKMEOW}[cd]${C_RESET} Hide Files\n"

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

        if [ "$show_hidden" == "true" ]; then
            menu_items+="${C_BLACK}[.*]${C_RESET} Hide Hidden"
        else
            menu_items+="${C_BLACK}[.*]${C_RESET} Show Hidden"
        fi

        local line_count=$(echo -e "$menu_items" | wc -l)
        local dynamic_height=$(( line_count + 4 ))
        [ "$dynamic_height" -gt 35 ] && dynamic_height="80%"

        local ui_prompt=" :: ls › $display_prompt :: "
        if [ "$CMT_COMMAND" == "true" ] && [ "$COMMAND_LS" == "true" ]; then
            ui_prompt=" :: cmt › ls › $display_prompt :: "
        fi

        local raw_target
        raw_target=$(echo -e "$menu_items" | fzf --ansi \
            --height="$dynamic_height" \
            --layout=reverse \
            --prompt="$ui_prompt" \
            --info=hidden \
            --header=" :: Enter to Inspect, Esc to Return ::" \
            --border=bottom \
            --border-label=" :: FILE SCANNER :: " \
            --pointer="››" \
            --color=fg:white,bg:-1,hl:46,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:46,pointer:red,marker:46,border:46,header:240 \
            --bind="resize:clear-screen"
            )

        if [ -z "$raw_target" ]; then break; fi

        local target=$(echo "$raw_target" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//')

        if [ "$target" == "----------" ]; then continue; fi
        
        if [ "$target" == "[cd] Hide Files" ]; then
            if [ "$CMT_COMMAND" == "true" ]; then
                export COMMAND_LS="false"
                export COMMAND_CD="true"
            fi
            cd
            if [ "$CMT_COMMAND" == "true" ]; then
                export COMMAND_LS="true"
                export COMMAND_CD="false"
            fi
            break
        elif [ "$target" == "[cd] Revert to Origin" ]; then
            builtin cd "$origin_pwd"
            continue
        elif [ "$target" == "[..] Backto" ]; then
            builtin cd ..
            export TCT_RADAR_HIDDEN="false"; show_hidden="false"
            if command -v _save_settings &> /dev/null; then _save_settings; fi
        elif [ "$target" == "[.*] Show Hidden" ]; then
            export TCT_RADAR_HIDDEN="true"; show_hidden="true"
            if command -v _save_settings &> /dev/null; then _save_settings; fi
            continue
        elif [ "$target" == "[.*] Hide Hidden" ]; then
            export TCT_RADAR_HIDDEN="false"; show_hidden="false"
            if command -v _save_settings &> /dev/null; then _save_settings; fi
            continue
        else
            local clean_target=$(echo "$target" | sed 's/^\[  \] //')
            if [ -d "$clean_target" ]; then
                builtin cd "$clean_target"
                export TCT_RADAR_HIDDEN="false"; show_hidden="false"
                if command -v _save_settings &> /dev/null; then _save_settings; fi
            elif [ -f "$clean_target" ]; then
                continue
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

    export MUX_INITIALIZED="true"
    export PS1="\[${C_PINKMEOW}\]Cmt\[${C_RESET}\] \w \033[5m›\033[0m "

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
            export COMMAND_CD="true"
            cd "${@:2}"
            unset CMT_COMMAND COMMAND_CD
            ;;
            
        # : System 'ls' Override
        "ls")
            export CMT_COMMAND="true"
            export COMMAND_LS="true"
            ls "${@:2}"
            unset CMT_COMMAND COMMAND_LS
            ;;

        # : Exit Command Tower
        "logout")
            echo -ne "${C_RED} :: EXIT COMMAND TOWER? TYPE 'CONFIRM' TO PROCEED: ${C_RESET}"
            read final_confirm
            
            if [ "$final_confirm" == "CONFIRM" ]; then
                echo -e "${C_PINKMEOW} :: Tower Uplink Disconnected. See you, Commander! ( ´ ▽ \` )ﾉ${C_RESET}"
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
    # 紀錄操作前的等級
    local old_lv=${MUX_LEVEL:-1}
    
    # 執行指揮塔核心指令
    __tct_core "$@"
    local ret_code=$?
    
    # 紀錄操作後的等級
    local new_lv=${MUX_LEVEL:-1}
    
    # --- [提示] 塔內專屬解鎖檢查區 ---
    # (如果指揮官你在塔內實作了獲得經驗值的機制，這裡就可以像 fac 一樣
    #  寫入到達特定等級時，解鎖新外骨骼指令的劇情廣播！目前先留空)
    
    # if [ "$old_lv" -lt 10 ] && [ "$new_lv" -ge 10 ]; then
    #     _assistant_voice "success" "Commander! We unlocked the rm tactical override!"
    # fi
    # --------------------------------
    
    return $ret_code
}