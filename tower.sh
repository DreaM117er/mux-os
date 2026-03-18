# tower.sh - Mux-OS 指揮塔模組 (The Command Tower)
# 權限：Lv.16 Architect & The Clumsy Co-pilot

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

# ==========================================
# 2. 原生指令劫持 (Physical Engine Overrides)
# ==========================================
# (這裡將會實作進化的 cd, rm, cp 等指令)

# 原生指令劫持：TCT 專屬戰術雷達 (cd)
# ==========================================

function cd() {
    # 0 & 1. 模式鎖定與旁路判定 (OR Gate Bypass Circuit)
    if [ "$MUX_MODE" != "TCT" ] || [ "$#" -gt 0 ]; then
        builtin cd "$@"
        return $?
    fi

    local origin_pwd="$PWD"
    while true; do
        local dirs
        dirs=$(find . -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sed 's|^\./||' | sort)

        local menu_items=""
        
        menu_items+="${C_RED}[Revert to Origin]${C_RESET}\n"
        if [ "$PWD" != "/" ]; then
            menu_items+="${C_YELLOW}[Backto]${C_RESET}\n"
        fi
        
        if [ -n "$dirs" ]; then
            menu_items+="$dirs"
        fi

        local line_count=$(echo -e "$menu_items" | wc -l)
        local dynamic_height=$(( line_count + 4 ))

        local target
        target=$(echo -e "$menu_items" | fzf \
            --height="$dynamic_height" \
            --layout=reverse \
            --prompt=" :: $PWD › " \
            --info=hidden \
            --header=" :: Enter to Select, Esc to Return ::" \
            --border=bottom \
            --border-label=" :: TARGET DIRECTORY :: " \
            --pointer="››" \
            --color=fg:white,bg:-1,hl:211,fg+:white,bg+:235,hl+:240 \
            --color=info:240,prompt:211,pointer:red,marker:211,border:211,header:240 \
            --bind="resize:clear-screen"
            )

        if [ -z "$target" ]; then
            # 狀態：按下 ESC，直接原地登出雷達，不改變當前位置
            break
        elif [[ "$target" == *"[Revert to Origin]"* ]]; then
            # 狀態：觸發紅色彈射鈕
            # 動作：拉動安全繫繩，瞬間位移回原點，並切斷雷達
            builtin cd "$origin_pwd"
            break
        elif [[ "$target" == *"[Backto]"* ]]; then
            # 狀態：觸發黃色攀爬點
            # 動作：向上層跳躍
            builtin cd ..
        else
            # 狀態：鎖定目標資料夾
            # 動作：向內層跳躍 (因為 target 不含色碼，這裡可以直接跳躍)
            builtin cd "$target"
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