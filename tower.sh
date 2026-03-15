# tower.sh - Mux-OS 指揮塔模組 (The Command Tower)
# 權限：Lv.16 Architect & The Clumsy Co-pilot

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

# 武器靜音協議 (Weapons Cold)
function command_not_found_handle() {
    local cmd="$1"
    
    # 呼叫小助理的錯誤提示
    if command -v _assistant_voice &> /dev/null; then
        _assistant_voice "error" "Command '$cmd' not found. We are in Weapons Cold mode!"
    else
        echo -e "${C_PINKMEOW} :: Eh? I don't know what '$cmd' is... (；´д｀)ゞ\033[0m"
    fi
    return 127
}

# ==========================================
# 2. 原生指令劫持 (Physical Engine Overrides)
# ==========================================
# (這裡將會實作進化的 cd, rm, cp 等指令)


# 指揮塔初始化 (Tower Initialization)
function _tct_init() {
    _system_lock
    _safe_ui_calc
    
    clear
    _draw_logo "tct"
    _system_check "tct"
    
    # 如果小助理出包了，這裡會畫出損壞的 HUD
    if command -v _show_hud &> /dev/null; then 
        _show_hud "tct"
    fi

    export MUX_INITIALIZED="true"
    export PS1="\[${C_PINKMEOW}\]Cmt\[${C_RESET}\] \w \033[5m›\033[0m "

    # 沒有出包，就說出歡迎詞
    if [ "${__MUX_CLUMSY_STATE:-0}" -eq 0 ]; then
        if command -v _assistant_voice &> /dev/null; then
            if [ "$__MUX_CAT_OS" == "1" ]; then
                _assistant_voice "cat_mode"
            else
                _assistant_voice "tower_ready"
            fi
        fi
    fi
    _system_unlock
}

# Mux-OS 指令入口 - Tower Command Entry
# === Tct ===

# : Tower Command Entry
function __tct_core() {
    local cmd="$1"
    
    case "$cmd" in
        # : Advanced directory navigation protocol
        "comedisk")
            # (未來實作 cd 外骨骼)
            ;;

        # : Destructive data dispersal
        "remove")
            # (未來實作 rm 外骨骼)
            ;;

        # : Override native copy mechanics
        "copy")
            # (未來實作 cp 外骨骼)
            ;;

        # : Reload Tower UI and state
        "reload")
            echo -e "${C_PINKMEOW} :: Refreshing Tower Interface! Hold on tight! (*≧ω≦)${C_RESET}"
            sleep 1
            _mux_reload_kernel
            ;;

        # : Emergency protocol override
        "reset")
            _mux_force_reset
            if [ $? -eq 0 ]; then
                _mux_reload_kernel
            fi
            ;;

        "help")
            if command -v _mux_dynamic_help_tower &> /dev/null; then
                _mux_dynamic_help_tower
            fi
            ;;

        "logout")
            echo -e "${C_PINKMEOW} :: Closing Tower Uplink. See you later, Commander! ( ´ ▽ \` )ﾉ${C_RESET}"
            sleep 1
            _update_mux_state "MUX" "DEFAULT"
            _mux_reload_kernel
            ;;

        *)
            if command -v "$cmd" &> /dev/null; then "$cmd" "${@:2}"; return; fi
            echo -e "${C_PINKMEOW} :: Eh? I don't know what '$cmd' is... (；´д｀)ゞ${C_RESET}"
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