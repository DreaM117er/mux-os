# ui.sh - Mux-OS 視覺顯示模組

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

# 繪製 Mux-OS Logo標誌
function _draw_logo() {
    local mode="${1:-core}"
    local color_primary=""
    local color_sub=""
    local label=""

    case "$mode" in
        "factory")
            color_primary="\033[1;38;5;208m"
            color_sub="\033[1;30m"
            label=":: Mux-OS v$MUX_VERSION Factory :: Neural Link Create ::"
            ;;

        "gray")
            color_primary="\033[1;30m"
            color_sub="\033[1;30m"
            label=":: SYSTEM LOCKED :: AUTHENTICATION REQUIRED ::"
            ;;

        *)
            color_primary="\033[1;36m"
            color_sub="\033[1;30m"
            label=":: Mux-OS v$MUX_VERSION Core :: Target: Android/Termux ::"
            ;;
    esac

    echo -e "${color_primary}"
    cat << "EOF"
  __  __                  ___  ____  
 |  \/  |_   ___  __     / _ \/ ___| 
 | |\/| | | | \ \/ /____| | | \___ \ 
 | |  | | |_| |>  <_____| |_| |___) |
 |_|  |_|\__,_/_/\_\     \___/|____/ 
EOF
    echo -e "\033[0m"
    echo -e " ${color_sub}${label}\033[0m"
    echo ""
}

# 系統檢測動畫顯示 - System Check Animation Display
function _system_check() {
    local mode="${1:-core}"
    
    local C_CHECK="\033[1;32m✓\033[0m"
    local C_FAIL="\033[1;31m✗\033[0m"
    local C_WARN="\033[1;33m!\033[0m"
    local C_PROC="\033[1;33m⟳\033[0m"
    local DELAY_ANIM=0.06
    local DELAY_STEP=0.02
    
    local steps=()
    if [ "$mode" == "factory" ]; then
        C_PROC="\033[1;35m⟳\033[0m"
        steps=(
            "Initializing Neural Forge..."
            "Overriding Read-Only Filesystem..."
            "Disabling Safety Interlocks..."
            "Mounting app.sh (Write-Mode)..."
            "Establishing Factory Uplink..."
        )
    else
        local brand=$(getprop ro.product.brand | tr '[:lower:]' '[:upper:]')
        steps=(
            "Initializing Kernel Bridge..."
            "Mounting Vendor Ecosystem [${brand:-UNKNOWN}]..."
            "Verifying Neural Link (fzf)..."
            "Calibrating Touch Matrix..."
            "Bypassing Knox Security Layer..."
            "Establish Uplink..."
        )
    fi

    function _run_step() {
        local msg="$1"
        local status="${2:-0}"
        echo -ne " $C_PROC $msg\r"; sleep $DELAY_ANIM
        if [ "$status" -eq 0 ]; then echo -e " $C_CHECK $msg                    ";
        elif [ "$status" -eq 1 ]; then echo -e " $C_FAIL $msg \033[1;31m[OFFLINE]\033[0m";
        else echo -e " $C_WARN $msg \033[1;33m[UNKNOWN]\033[0m"; fi
        sleep $DELAY_STEP
    }

    for step in "${steps[@]}"; do
        if [[ "$step" == *"fzf"* ]] && [ "$mode" == "core" ]; then
             command -v fzf &> /dev/null && _run_step "$step" 0 || _run_step "$step" 1
        else
             _run_step "$step" 0
        fi
    done
    echo ""
}

# 顯示系統資訊 HUD - Display System Info HUD
function _show_hud() {
    local mode="${1:-core}"
    local screen_width=$(tput cols)
    local box_width=$(( screen_width < 22 ? 22 : screen_width - 2 ))
    local content_limit=$(( box_width - 13 ))
    [ "$content_limit" -lt 5 ] && content_limit=5
    
    local border_color="\033[1;34m" 
    
    local text_color="\033[1;37m"
    local value_color="\033[0m"

    local line1_k=""
    local line1_v=""
    local line2_k=""
    local line2_v=""
    local line3_k=""
    local line3_v=""

    if [ "$mode" == "factory" ]; then
        line1_k="MODE   "; line1_v="FACTORY [ROOT]"
        line2_k="TARGET "; line2_v="app.sh"
        line3_k="STATUS "; line3_v="UNLOCKED"
    else
        local android_ver=$(getprop ro.build.version.release)
        local brand_raw=$(getprop ro.product.brand | tr '[:lower:]' '[:upper:]' | cut -c1)$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]' | cut -c2-)
        local model=$(getprop ro.product.model)
        local host_str="$brand_raw $model (Android $android_ver)"
        local kernel_ver=$(uname -r | awk -F- '{print $1}')
        local mem_info=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
        
        [ ${#host_str} -gt $content_limit ] && host_str="${host_str:0:$((content_limit - 2))}.."
        [ ${#kernel_ver} -gt $content_limit ] && kernel_ver="${kernel_ver:0:$((content_limit - 2))}.."
        
        line1_k="HOST   "; line1_v="$host_str"
        line2_k="KERNEL "; line2_v="$kernel_ver"
        line3_k="MEMORY "; line3_v="$mem_info"
    fi

    local border_line=$(printf '═%.0s' $(seq 1 $((box_width - 2))))
    
    echo -e "${border_color}╔${border_line}╗\033[0m"
    printf "${border_color}║\033[0m ${text_color}%s\033[0m: %-*s ${border_color}║\033[0m\n" "$line1_k" $content_limit "$line1_v"
    printf "${border_color}║\033[0m ${text_color}%s\033[0m: %-*s ${border_color}║\033[0m\n" "$line2_k" $content_limit "$line2_v"
    printf "${border_color}║\033[0m ${text_color}%s\033[0m: %-*s ${border_color}║\033[0m\n" "$line3_k" $content_limit "$line3_v"
    echo -e "${border_color}╚${border_line}╝\033[0m"
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

# 動態Help Core選單檢測 - Dynamic Help Core Detection
function _mux_dynamic_help_core() {
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "Unknown")

    echo -e "\033[1;35m :: Mux-OS Core v$MUX_VERSION Protocols :: @$current_branch :: \033[0m"
    
    awk '
    /function mux\(\) \{/ { inside_mux=1; next }
    /^}/ { inside_mux=0 }

    inside_mux {
        if ($0 ~ /^[[:space:]]*# :/) {
            desc = $0;
            sub(/^[[:space:]]*# :[[:space:]]*/, "", desc);
            
            getline;
            if ($0 ~ /"/) {
                split($0, parts, "\"");
                cmd_name = parts[2];
                printf "    \033[1;36m%-10s\033[0m : %s\n", cmd_name, desc;
            }
        }
    }
    ' "$CORE_MOD"
}

# 動態Help Factory選單檢測 - Dynamic Help Factory Detection
function _mux_dynamic_help_factory() {
echo -e "\033[1;35m :: Mux-OS Factory Protocols ::\033[0m"
    
    awk '
    /function fac\(\) \{/ { inside_fac=1; next }
    /^}/ { inside_fac=0 }

    inside_fac {
        if ($0 ~ /^[[:space:]]*# :/) {
            desc = $0;
            sub(/^[[:space:]]*# :[[:space:]]*/, "", desc);
            
            getline;
            if ($0 ~ /"/) {
                split($0, parts, "\"");
                cmd_name = parts[2];
                printf "    \033[1;38;5;208m%-10s\033[0m : %s\n", cmd_name, desc;
            }
        }
    }
    ' "$MUX_ROOT/factory.sh"
}

# 顯示指令選單儀表板 - Display Command Menu Dashboard
function _show_menu_dashboard() {
    local title_color="\033[1;33m"
    local cat_color="\033[1;32m"
    local func_color="\033[1;36m"
    local target_file="$APP_MOD" 

    if [ "$__MUX_MODE" == "factory" ]; then
        title_color="\033[1;35m"
        cat_color="\033[1;31m"
        func_color="\033[1;37m"
        target_file="$MUX_ROOT/app.sh.temp"
        
        echo -e "\n${title_color} [ Factory Sandbox Manifest ]${C_RESET}"
    else
        echo -e "\n${title_color} [ Mux-OS Command Center ]${C_RESET}"
    fi
    
    if [ ! -f "$target_file" ]; then
        echo -e " :: Error: Target manifest not found ($target_file)"
        return
    fi

    awk -v C_CAT="$cat_color" -v C_FUNC="$func_color" -v C_RST="\033[0m" '
    BEGIN {
        # awk 變數傳入
    }

    /^# ===|^# ---/ {
        clean_header = $0;
        gsub(/^# |^#===|^#---|===|---|^-+|-+$|^\s+|\s+$/, "", clean_header);
        if (length(clean_header) > 0 && clean_header !~ /^[=-]+$/) {
             print "\n" C_CAT " [" clean_header "]" C_RST
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
                printf "  " C_FUNC "%-12s" C_RST " %s\n", func_name, desc;
            }
        }
    }
    { prev_line = $0 }
    ' "$CORE_MOD" "$SYSTEM_MOD" "$target_file" "$VENDOR_MOD"
    
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

    local cmd_list=$(awk '
        BEGIN {
            C_CMD="\x1b[1;37m"
            C_DESC="\x1b[1;30m"
            C_RESET="\x1b[0m"
        }

        /^function / {
            match($0, /function ([a-zA-Z0-9_]+)/, arr);
            func_name = arr[1];
            
            if (substr(func_name, 1, 1) != "_") {
                desc = "";
                if (prev_line ~ /^# :/) {
                    desc = prev_line;
                    gsub(/^# : /, "", desc);
                    gsub(/[[:space:]]+$/, "", desc);
                }
                
                if (desc != "") {
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
        --border=bottom \
        --prompt=" :: Neural Link › " \
        --header=" :: Slot Capacity: [6/$total_cmds] :: " \
        --info=hidden \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:green,fg+:cyan,bg+:black,hl+:yellow,info:yellow,prompt:cyan,pointer:red,border:blue \
        --bind="resize:clear-screen"
    )

    if [ -n "$selected" ]; then
        local cmd_to_run=$(echo "$selected" | awk '{print $1}')
        local prompt_text=$'\033[1;33m :: '$cmd_to_run$' \033[1;30m(Params?): \033[0m'
        read -e -p "$prompt_text" params < /dev/tty
        
        local final_cmd="$cmd_to_run"
        [ -n "$params" ] && final_cmd="$cmd_to_run $params"
        history -s "$final_cmd"
        _bot_say "neural" "Executing: $final_cmd"
        eval "$final_cmd"
    fi
}

function _mux_uplink_sequence() {
    if command -v fzf &> /dev/null; then
        _bot_say "success" "Neural Link is already active. Signal stable."
        return
    fi

    _bot_say "system" "Initializing Neural Bridge Protocol..."
    sleep 0.5
    echo -e "\033[1;33m :: Scanning local synaptic ports...\033[0m"
    sleep 0.8
    echo -e "\033[1;36m :: Constructing interface matrix (fzf)...\033[0m"
    sleep 0.5

    pkg install fzf -y > /dev/null 2>&1

    if command -v fzf &> /dev/null; then
        echo -e "\033[1;35m :: SYNCHRONIZATION COMPLETE :: \033[0m"
        sleep 0.5
        _bot_say "neural" "Welcome to the Grid, Commander."
        
        sleep 1
        _mux_fuzzy_menu
    else
        _bot_say "error" "Link failed. Neural rejection detected."
    fi
}

# 顯示兵工廠狀態 - Display Factory Status
function _factory_show_status() {
    local func_count=$(grep -c "^function" "$MUX_ROOT/app.sh")
    local backup_count=$(ls "$MUX_ROOT/bak/" 2>/dev/null | wc -l)
    local last_sync=$(grep "Last Sync" "$MUX_ROOT/app.sh" | cut -d: -f2- | sed 's/::/\n/' | xargs)
    [ -z "$last_sync" ] && last_sync="Unknown"

    local F_MAIN="\033[1;38;5;208m"
    local F_SUB="\033[1;37m"
    local F_WARN="\033[1;33m"
    
    echo -e "${F_MAIN} :: Factory Operational Status \033[0m"
    echo -e "${F_SUB}    ›› Active Links  :\033[0m ${F_WARN}$func_count\033[0m"
    echo -e "${F_SUB}    ›› Secure Backups:\033[0m ${F_WARN}$backup_count\033[0m"
    echo -e "${F_SUB}    ›› Last Deploy   :\033[0m \033[1;36m$last_sync\033[0m"
}

# 顯示兵工廠資訊 - Display Factory Info Manifest
function _factory_show_info() {
    local F_MAIN="\033[1;38;5;208m"
    local F_SUB="\033[1;37m"
    local F_WARN="\033[1;33m"
    local F_GRAY="\033[1;30m"
    local F_RESET="\033[0m"

    clear
    _draw_logo "factory"
    
    echo -e " ${F_MAIN}:: INDUSTRIAL MANIFEST ::${F_RESET}"
    echo ""
    echo -e "  ${F_GRAY}PROTOCOL   :${F_RESET} ${F_SUB}Factory Mode${F_RESET}"
    echo -e "  ${F_GRAY}ACCESS     :${F_RESET} ${F_MAIN}ROOT / COMMANDER${F_RESET}"
    echo -e "  ${F_GRAY}PURPOSE    :${F_RESET} ${F_SUB}Neural Link Construction & Modification${F_RESET}"
    echo -e "  ${F_GRAY}TARGET     :${F_RESET} ${F_WARN}app.sh${F_RESET}"
    echo ""
    echo -e " ${F_MAIN}:: WARNING ::${F_RESET}"
    echo -e "  ${F_GRAY}\"With great power comes great possibility of breaking things.\"${F_RESET}"
    echo ""
    
    _bot_say "system" "Returning to forge..."
}