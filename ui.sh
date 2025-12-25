# ui.sh - Mux-OS 視覺顯示模組

export C_RESET="\033[0m"
export C_CYAN="\033[1;36m"
export C_GREEN="\033[1;32m"
export C_RED="\033[1;31m"
export C_YELLOW="\033[1;33m"
export C_GRAY="\033[1;30m"
export C_WHITE="\033[1;37m"
export C_BLUE="\033[1;34m"

function _draw_logo() {
    echo -e "$C_CYAN"
    cat << "EOF"
  __  __                  ___  ____  
 |  \/  |_   ___  __     / _ \/ ___| 
 | |\/| | | | \ \/ /____| | | \___ \ 
 | |  | | |_| |>  <_____| |_| |___) |
 |_|  |_|\__,_/_/\_\     \___/|____/ 
EOF
    echo -e "$C_RESET"
    echo -e " ${C_GRAY}:: Mux-OS Core v$MUX_VERSION :: Target: Android/Termux ::$C_RESET"
    echo ""
}

function _show_hud() {
    local screen_width=$(tput cols)
    local box_width=$((screen_width - 2))
    local content_limit=$((box_width - 13))
    
    local android_ver=$(getprop ro.build.version.release)
    local brand_raw=$(getprop ro.product.brand | tr '[:lower:]' '[:upper:]' | cut -c1)$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]' | cut -c2-)
    local model=$(getprop ro.product.model)
    local host_str="$brand_raw $model (Android $android_ver)"
    local kernel_ver=$(uname -r | awk -F- '{print $1}')
    local mem_info=$(free -h | awk '/Mem:/ {print $3 "/" $2}')

    [ ${#host_str} -gt $content_limit ] && host_str="${host_str:0:$((content_limit - 2))}.."
    [ ${#kernel_ver} -gt $content_limit ] && kernel_ver="${kernel_ver:0:$((content_limit - 2))}.."

    local border_len=$((box_width - 2))
    local border_line=$(printf '═%.0s' $(seq 1 $border_len))
   
    echo -e "${C_BLUE}╔${border_line}╗${C_RESET}"
    printf "${C_BLUE}║${C_RESET} ${C_WHITE}HOST   ${C_RESET} : %-*s ${C_BLUE}║${C_RESET}\n" $content_limit "$host_str"
    printf "${C_BLUE}║${C_RESET} ${C_WHITE}KERNEL ${C_RESET} : %-*s ${C_BLUE}║${C_RESET}\n" $content_limit "$kernel_ver"
    printf "${C_BLUE}║${C_RESET} ${C_WHITE}MEMORY ${C_RESET} : %-*s ${C_BLUE}║${C_RESET}\n" $content_limit "$mem_info"
    echo -e "${C_BLUE}╚${border_line}╝${C_RESET}"
    echo ""
}

function _mux_show_info() {
    clear
    _draw_logo
    
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
    
    echo -ne " ${C_GREEN}👉 Open GitHub Repository? (y/n): ${C_RESET}"
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

function _show_menu_dashboard() {
    echo -e "\n${C_YELLOW} [" Mux-OS Command Center "]${C_RESET}"
    
    awk -v COLOR_CAT="$C_GREEN" -v COLOR_FUNC="$C_CYAN" -v RESET="$C_RESET" '
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
                desc = prev_line; gsub(/^# : /, "", desc);
            }
            if (length(desc) > 38) desc = substr(desc, 1, 35) "..";
            if (desc != "") printf "  " COLOR_FUNC "%-12s" RESET " %s\n", func_name, desc;
        }
    }
    { prev_line = $0 }
    ' "$0" "$SYSTEM_MOD" "$APP_MOD" "$VENDOR_MOD"
    echo -e "\n"
}

function _show_menu_dashboard() {
    echo -e "\n${C_YELLOW} [" Mux-OS Command Center "]${C_RESET}"
    
    awk -v COLOR_CAT="$C_GREEN" -v COLOR_FUNC="$C_CYAN" -v RESET="$C_RESET" '
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
        if (substr(func_name, 1, 1) != "_" && func_name != "mux") {
            desc = "";
            if (prev_line ~ /^# :/) {
                desc = prev_line; gsub(/^# : /, "", desc);
            }
            if (length(desc) > 38) desc = substr(desc, 1, 35) "..";
            if (desc != "") printf "  " COLOR_FUNC "%-12s" RESET " %s\n", func_name, desc;
        }
    }
    { prev_line = $0 }
    ' "$0" "$SYSTEM_MOD" "$APP_MOD" "$VENDOR_MOD"
    echo -e "\n"
}

function _mux_fuzzy_menu() {
    if ! command -v fzf &> /dev/null; then
        _show_menu_dashboard
        
        echo -e "\n\033[1;33m⚠️  Neural Search Module (fzf) is missing.\033[0m"
        echo -ne "\033[1;36m📥 Install now to enable interactive interface? (y/n): \033[0m"
        read choice
        
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo " > Installing fzf..."
            pkg install fzf -y
            
            echo -e "\033[1;32m✅ Module installed. Initializing Neural Link...\033[0m"
            sleep 1
            _mux_fuzzy_menu
            return
        else
            echo " > Keeping legacy menu."
            return
        fi
    fi

    local selected=$(
        awk '
        BEGIN {
            C_CMD="\033[1;36m"
            C_DESC="\033[1;30m"
            C_RESET="\033[0m"
        }
        
        /^function / {
            match($0, /function ([a-zA-Z0-9_]+)/, arr);
            func_name = arr[1];
            
            if (substr(func_name, 1, 1) != "_" && func_name != "mux") {
                desc = "";
                if (prev_line ~ /^# :/) {
                    desc = prev_line;
                    gsub(/^# : /, "", desc);
                }
                
                if (desc != "") {
                    printf C_CMD "%-12s" C_DESC " %s" C_RESET "\n", func_name, desc;
                }
            }
        }
        { prev_line = $0 }
        ' "$SYSTEM_MOD" "$APP_MOD" "$VENDOR_MOD" | \
        fzf --ansi --height=45% --layout=reverse --border \
            --prompt="🔍 Neural Link > " \
            --pointer="▶" \
            --marker="✓" \
            --header="[Select Protocol]" \
            --color=fg:white,bg:-1,hl:green,fg+:cyan,bg+:black,hl+:yellow,info:yellow,prompt:cyan,pointer:red
    )

    if [ -n "$selected" ]; then
        local cmd_to_run=$(echo "$selected" | awk '{print $1}')
        
        echo -ne "\033[1;33m⚡ $cmd_to_run \033[1;30m(Params?): \033[0m"
        
        read -e params < /dev/tty
        
        local final_cmd="$cmd_to_run"
        if [ -n "$params" ]; then
            final_cmd="$cmd_to_run $params"
        fi
        
        history -s "$final_cmd"
        _bot_say "neural" "Executing: $final_cmd"
        eval "$final_cmd"
    else
        :
    fi
}