#!/bin/bash
# factory.sh - Mux-OS 兵工廠 v5.1.0 (State-Based)

F_MAIN="\033[1;35m"
F_SUB="\033[1;37m"
F_WARN="\033[1;33m"
F_RESET="\033[0m"

# 進入兵工廠模式 (State Switch)
function _enter_factory_mode() {
    # 設定全域模式變數
    export __MUX_MODE="factory"
    
    # 執行一次性的備份
    _factory_auto_backup > /dev/null 2>&1
    
    # 清除畫面，繪製介面，但之後就把控制權還給 Shell
    clear
    _draw_logo "factory"
    echo -e "${F_MAIN} :: Factory Mode Engaged.${F_RESET}"
    echo -e "${F_SUB} :: 'mux' commands locked. Use 'fac' to operate.${F_RESET}"
    echo ""
}

# 兵工廠主指令 (The new 'mux' equivalent)
function fac() {
    local cmd="$1"
    
    if [ "$__MUX_MODE" != "factory" ]; then
        echo -e "\033[1;31m :: Error: Factory Link Offline. Use 'mux fac' to connect.\033[0m"
        return 1
    fi

    if [ -z "$cmd" ]; then
        _factory_help
        return
    fi

    case "$cmd" in
        "menu"|"m")
            _factory_fzf_menu
            ;;
        "list"|"l")
            _factory_list_links
            ;;
        "help"|"h")
            _factory_help
            ;;
        "deploy"|"d"|"exit")
            _factory_deploy_sequence
            ;;
        *)
            echo -e "${F_WARN} :: Unknown Factory Directive: $cmd${F_RESET}"
            ;;
    esac
}

function _factory_auto_backup() {
    local bak_dir="$MUX_ROOT/bak"
    if [ ! -d "$bak_dir" ]; then mkdir -p "$bak_dir"; fi
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp "$MUX_ROOT/app.sh" "$bak_dir/app.sh_$timestamp"
    ls -t "$bak_dir"/app.sh_* 2>/dev/null | tail -n +4 | xargs rm -- 2>/dev/null
}

function _factory_deploy_sequence() {
    echo ""
    echo -e "${F_MAIN} :: Initiate Deployment Sequence?${F_RESET}"
    echo -ne "${F_WARN} :: Type 'CONFIRM' to save & exit: ${F_RESET}"
    read confirm
    
    if [ "$confirm" == "CONFIRM" ]; then
        echo ""
        _bot_say "success" "Neural map updated."
        
        # 寫入時間戳
        local time_str="# :: Last Sync: $(date '+%Y-%m-%d %H:%M:%S') ::"
        if grep -q "Last Sync" "$MUX_ROOT/app.sh"; then
            sed -i "1s|.*Last Sync.*|$time_str|" "$MUX_ROOT/app.sh"
        else
            sed -i "1i $time_str" "$MUX_ROOT/app.sh"
        fi
        
        # 解除 Factory 模式
        export __MUX_MODE="core"
        
        # 重整畫面
        sleep 1
        clear
        _draw_logo "core"
        echo -e "\033[1;36m :: System control returned to Core.\033[0m"
        echo -e "\033[1;30m    (Please manual 'mux reload')\033[0m"
    else
        echo -e "${F_WARN} :: Deploy canceled. Remaining in Factory.${F_RESET}"
    fi
}

function _factory_list_links() {
    echo -e "\n${F_MAIN} :: Current Neural Links:${F_RESET}"
    # 簡單的列出，不清除畫面
    grep "^function" "$MUX_ROOT/app.sh" | sed 's/function //' | sed 's/() {//' | column
    echo ""
}

function _factory_help() {
    echo -e "\n${F_MAIN} :: Factory Manual ::${F_RESET}"
    echo "  fac menu   : Open Neural Forge (FZF)"
    echo "  fac list   : List functions"
    echo "  fac deploy : Save changes & Return to Core"
}

function _factory_fzf_menu() {
    echo -e "\n${F_MAIN} :: Neural Forge (FZF) under construction...${F_RESET}"
}