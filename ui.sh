# ui.sh - Mux-OS 視覺顯示模組

# 繪製 Mux-OS Logo標誌
function _draw_logo() {
    echo -e "\033[1;36m"
    cat << "EOF"
  __  __                  ___  ____  
 |  \/  |_   ___  __     / _ \/ ___| 
 | |\/| | | | \ \/ /____| | | \___ \ 
 | |  | | |_| |>  <_____| |_| |___) |
 |_|  |_|\__,_/_/\_\     \___/|____/ 
EOF
    echo -e "\033[0m"
    echo -e " \033[1;30m:: Mux-OS Core v$MUX_VERSION :: Target: Android/Termux ::\033[0m"
    echo ""
}

# 系統檢測動畫顯示 - System Check Animation Display
function _system_check() {
    local C_CHECK="\033[1;32m✓\033[0m"
    local C_FAIL="\033[1;31m✗\033[0m"
    local C_WARN="\033[1;33m!\033[0m"
    local C_PROC="\033[1;33m⟳\033[0m"
    local DELAY_ANIM=0.08
    local DELAY_STEP=0.02

    function _run_step() {
        local msg="$1"
        local status="${2:-0}"
        echo -ne " $C_PROC $msg\r"; sleep $DELAY_ANIM
        if [ "$status" -eq 0 ]; then echo -e " $C_CHECK $msg                    ";
        elif [ "$status" -eq 1 ]; then echo -e " $C_FAIL $msg \033[1;31m[OFFLINE]\033[0m";
        else echo -e " $C_WARN $msg \033[1;33m[UNKNOWN]\033[0m"; fi
        sleep $DELAY_STEP
    }

    _run_step "Initializing Kernel Bridge..." 0
    local brand=$(getprop ro.product.brand | tr '[:lower:]' '[:upper:]')
    _run_step "Mounting Vendor Ecosystem [${brand:-UNKNOWN}]..." 0
    command -v fzf &> /dev/null && _run_step "Verifying Neural Link (fzf)..." 0 || _run_step "Verifying Neural Link (fzf)..." 1
    _run_step "Calibrating Touch Matrix..." 0
    _run_step "Bypassing Knox Security Layer..." 0
    _run_step "Establish Uplink..." 0
    echo ""
}

# 顯示系統資訊 HUD - Display System Info HUD
function _show_hud() {
    local screen_width=$(tput cols)
    local box_width=$(( screen_width < 22 ? 22 : screen_width - 2 ))
    local content_limit=$(( box_width - 13 ))
    
    [ "$content_limit" -lt 5 ] && content_limit=5

    local android_ver=$(getprop ro.build.version.release)
    local brand_raw=$(getprop ro.product.brand | tr '[:lower:]' '[:upper:]' | cut -c1)$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]' | cut -c2-)
    local model=$(getprop ro.product.model)
    local host_str="$brand_raw $model (Android $android_ver)"
    local kernel_ver=$(uname -r | awk -F- '{print $1}')
    local mem_info=$(free -h | awk '/Mem:/ {print $3 "/" $2}')

    [ ${#host_str} -gt $content_limit ] && host_str="${host_str:0:$((content_limit - 2))}.."
    [ ${#kernel_ver} -gt $content_limit ] && kernel_ver="${kernel_ver:0:$((content_limit - 2))}.."

    local border_line=$(printf '═%.0s' $(seq 1 $((box_width - 2))))
    echo -e "\033[1;34m╔${border_line}╗\033[0m"
    printf "\033[1;34m║\033[0m \033[1;37mHOST   \033[0m: %-*s \033[1;34m║\033[0m\n" $content_limit "$host_str"
    printf "\033[1;34m║\033[0m \033[1;37mKERNEL \033[0m: %-*s \033[1;34m║\033[0m\n" $content_limit "$kernel_ver"
    printf "\033[1;34m║\033[0m \033[1;37mMEMORY \033[0m: %-*s \033[1;34m║\033[0m\n" $content_limit "$mem_info"
    echo -e "\033[1;34m╚${border_line}╝\033[0m"
    echo ""
}

# 顯示系統資訊詳情 - Display System Info Details
function _mux_show_info() {
    clear
    _draw_logo
    
    local C_CYAN="\033[1;36m"
    local C_WHITE="\033[1;37m"
    local C_GRAY="\033[1;30m"
    local C_RESET="\033[0m"
    local C_GREEN="\033[1;32m"

    echo -e " ${C_CYAN}:: SYSTEM MANIFEST ::${C_RESET}"
    echo ""
    echo -e "  ${C_GRAY}PROJECT    :${C_RESET} ${C_WHITE}Mux-OS (Terminal Environment)${C_RESET}"
    echo -e "  ${C_GRAY}VERSION    :${C_RESET} ${C_GREEN}v$MUX_VERSION${C_RESET}"
    echo -e "  ${C_GRAY}CODENAME   :${C_RESET} ${C_CYAN}Neural Link${C_RESET}"
    echo -e "  ${C_GRAY}ARCHITECT  :${C_RESET} ${C_WHITE}Commander${C_RESET}" 
    echo -e "  ${C_GRAY}BASE SYS   :${C_RESET} ${C_WHITE}Android $(getprop ro.build.version.release) / Linux $(uname -r | cut -d- -f1)${C_RESET}"
    echo ""
    echo -e " ${C_CYAN}:: PHILOSOPHY ::${C_RESET}"
    echo -e "  ${C_GRAY}\"Logic in mind, Hardware in hand.\"${C_RESET}"
    echo -e "  ${C_GRAY}Designed for efficiency, built for control.${C_RESET}"
    echo ""
    echo -e " ${C_CYAN}:: SOURCE CONTROL ::${C_RESET}"
    echo -e "  ${C_GRAY}Repo       :${C_RESET} ${C_WHITE}$MUX_REPO${C_RESET}"
    echo ""
    
    echo -ne " ${C_GREEN}:: Open GitHub Repository? (y/n): ${C_RESET}"
    read choice
    
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        if command -v wb &> /dev/null; then
            wb "$MUX_REPO"
        else
            am start -a android.intent.action.VIEW -d "$MUX_REPO" >/dev/null 2>&1
        fi
    else
        echo ""
        _bot_say "system" "Returning to command line..."
    fi
}

# 顯示指令選單儀表板 - Display Command Menu Dashboard
function _show_menu_dashboard() {
    echo -e "\n\033[1;33m" [" Mux-OS Command Center "]"\033[0m"
    
    awk '
    BEGIN {
        COLOR_CAT="\033[1;32m"
        COLOR_FUNC="\033[1;36m"
        RESET="\033[0m"
    }

    /^# ===|^# ---/ {
        clean_header = $0;
        gsub(/^# |^#===|^#---|===|---|^-+|-+$|^\s+|\s+$/, "", clean_header);
        if (length(clean_header) > 0 && clean_header !~ /^[=-]+$/) {
             print "\n" COLOR_CAT " [" clean_header "]" RESET
        }
    }
    
    /^function / {
        match($0, /function ([a-zA-Z0-9_]+)/, arr);
        func_name = arr[1];
        
        if (substr(func_name, 1, 1) != "_") {
            desc = "";
            if (prev_line ~ /^# :/) {
                desc = prev_line;
                gsub(/^# : /, "", desc);
            } else if (prev_line ~ /^# [0-9]+\./) {
                desc = prev_line;
                gsub(/^# [0-9]+\. /, "", desc);
            }

            if (length(desc) > 38) {
                desc = substr(desc, 1, 35) "..";
            }

            if (desc != "") {
                printf "  " COLOR_FUNC "%-12s" RESET " %s\n", func_name, desc;
            }
        }
    }
    { prev_line = $0 }
    ' "$CORE_MOD" "$SYSTEM_MOD" "$APP_MOD" "$VENDOR_MOD"
    
    echo -e "\n"
}

# 模糊指令選單介面 - Fuzzy Command Menu Interface
function _mux_fuzzy_menu() {
    if ! command -v fzf &> /dev/null; then
        echo -e "\n\033[1;31m :: Neural Search Module (fzf) is missing.\033[0m"
        echo -ne "\033[1;32m :: Install interactive interface? (y/n): \033[0m"
        read choice
        
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo "    ›› Installing fzf..."
            pkg install fzf -y
            
            echo -e "\033[1;32m    ›› Module installed. Initializing Neural Link... ✅\033[0m"
            sleep 1
            _mux_fuzzy_menu
            return
        else
            echo -e "\033[1;30m    ›› Keeping legacy menu.\033[0m"
            return
        fi
    fi

    local C_CMD="\033[1;37m"
    local C_DESC="\033[1;30m"
    local C_RESET="\033[0m"

    local cmd_list=$(awk -v C_CMD="$C_CMD" -v C_DESC="$C_DESC" '
        NR == 1 { gsub(/[^[:print:]]/, ""); }
        /^function / {
            match($0, /function ([a-zA-Z0-9_]+)/, arr);
            func_name = arr[1];
            if (substr(func_name, 1, 1) != "_") {
                desc = "";
                if (prev_line ~ /^# :/) {
                    desc = prev_line;
                    gsub(/^# : /, "", desc);
                    gsub(/[[:space:]]+$/, "", desc);
                    gsub(/[^[:print:]]/, "", desc);
                }
                if (desc != "") {
                    gsub(/[^[:print:]]/, "", func_name);
                    printf " %s%-12s %s%s\n", C_CMD, func_name, C_DESC, desc;
                }
            }
        }
        { prev_line = $0 }
    ' "$CORE_MOD" "$SYSTEM_MOD" "$APP_MOD" "$VENDOR_MOD")

    local total_cmds=$(echo "$cmd_list" | grep -c "^ ")

    local selected=$(echo "$cmd_list" | fzf --ansi \
        --height=10 \
        --layout=reverse \
        --border=horizontal \
        --prompt=" Neural Link › " \
        --header=" [Active Protocol Slots: 6] (Total: $total_cmds)" \
        --info=hidden \
        --pointer="▶" \
        --color=fg:white,bg:-1,hl:green,fg+:cyan,bg+:black,hl+:yellow,info:yellow,prompt:cyan,pointer:red,border:blue \
        --bind="resize:clear-screen"
    )

    if [ -n "$selected" ]; then
        local cmd_to_run=$(echo "$selected" | awk '{print $1}')
        
        echo -ne "\033[1;33m :: $cmd_to_run \033[1;30m(Params?): \033[0m"
        read -e params < /dev/tty
        
        local final_cmd="$cmd_to_run"
        [ -n "$params" ] && final_cmd="$cmd_to_run $params"
        
        history -s "$final_cmd"
        _bot_say "neural" "Executing: $final_cmd"
        eval "$final_cmd"
    fi
}

