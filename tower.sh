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
        echo -e "${C_PINKMEOW} ✨ Eh? I don't know what '$cmd' is... 💦\033[0m"
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
    
    export PS1="\[${C_PINKMEOW}\]Tct\[${C_RESET}\] \w \033[5m›\033[0m "
    
    _system_unlock
}


function __tct_core() {
    local cmd="$1"
    
    case "$cmd" in
        "exit"|"logout")
            echo ""
            _assistant_voice "tower_ready" "Closing Tower Uplink. See you later, Commander! 👋"
            sleep 1
            _update_mux_state "MUX" "DEFAULT"
            _mux_reload_kernel
            ;;

        "help")
            echo -e "${C_PINKMEOW} :: Command Tower Protocols ::${C_RESET}"
            echo -e "    \033[1;37mcd\033[0m      Advanced Spatial Jump"
            echo -e "    \033[1;37mrm\033[0m      Tactical Annihilation"
            echo -e "    \033[1;37mcp\033[0m      Matter Transfer"
            echo -e "    \033[1;37mexit\033[0m    Return to Mux-OS"
            ;;

        *)
            if [ -z "$cmd" ]; then
                _assistant_voice "tower_ready" "I'm here! What's the plan?"
            else
                echo -e "${C_PINKMEOW} :: Unrecognized Tower Directive: '$cmd'.${C_RESET}"
            fi
            ;;
    esac
}

function tct() {
    __tct_core "$@"
}