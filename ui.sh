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
    local cols=$(tput cols)

case "$mode" in
        "factory")
            color_primary="\033[1;38;5;208m"
            color_sub="\033[1;30m"
            if [ "$cols" -lt 52 ]; then
                label=":: Mux-OS v$MUX_VERSION Factory ::"
            else
                label=":: Mux-OS v$MUX_VERSION Factory :: Neural Forge ::"
            fi
            ;;

        "gray")
            color_primary="\033[1;30m"
            color_sub="\033[1;30m"
            if [ "$cols" -lt 52 ]; then
                label=":: SYSTEM LOCKED ::"
            else
                label=":: SYSTEM LOCKED :: AUTHENTICATION REQUIRED ::"
            fi
            ;;

        *)
            color_primary="\033[1;36m"
            color_sub="\033[1;30m"
            if [ "$cols" -lt 52 ]; then
                label=":: Mux-OS v$MUX_VERSION Core ::"
            else
                label=":: Mux-OS v$MUX_VERSION Core :: Gate System ::"
            fi
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
        line1_k="HOST   "; line1_v="Commander"
        line2_k="TARGET "; line2_v="app.csv.temp"
        line3_k="STATUS "; line3_v="Unlocked"
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
    
    echo -ne " ${C_GREEN}:: Open GitHub Repository? [Y/n]: ${C_RESET}"
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
                printf "    \033[1;36m%-10s\033[0m%s\n", cmd_name, desc;
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
                printf "    \033[1;38;5;208m%-10s\033[0m%s\n", cmd_name, desc;
            }
        }
    }
    ' "$MUX_ROOT/factory.sh"
}

# 顯示指令選單儀表板 - Display Command Menu Dashboard
function _show_menu_dashboard() {
    local search_filter="$1"
    
    local target_app_file="$APP_MOD"
    local title_text=":: Mux-OS Command Center ::"
    
    local C_TITLE="\033[1;35m"
    local C_CAT="\033[1;33m"
    local C_COM="\033[1;36m"
    local C_SUB="\033[1;34m"
    local C_DESC="\033[0;37m"
    local C_WARN="\033[1;31m"
    local C_RST="\033[0m"

    if [ "$__MUX_MODE" == "factory" ]; then
        title_text=":: Factory Sandbox Manifest ::"
        C_TITLE="\033[1;35m"
        C_CAT="\033[1;31m"
        C_COM="\033[1;37m"
        
        if [ -f "$MUX_ROOT/app.csv.temp" ]; then
            target_app_file="$MUX_ROOT/app.csv.temp"
        fi
    fi

    local data_files=("$SYSTEM_MOD" "$VENDOR_MOD" "$target_app_file")

    echo -e " ${C_TITLE}${title_text}${C_RST}"

    local collision_list=$(awk -v FPAT='([^,]*)|("[^"]+")' '
        !/^#/ && NF >= 5 && $1 !~ /CATNO/ {
            
            cmd = $5; gsub(/^"|"$/, "", cmd)
            
            sub_cmd = ""
            if (NF >= 6) {
                sub_cmd = $6; gsub(/^"|"$/, "", sub_cmd)
            }

            if (cmd != "") {
                if (length(sub_cmd) > 0) {
                    key = cmd " [" sub_cmd "]"
                } else {
                    key = cmd
                }

                count[key]++
            }
        }
        END {
            for (k in count) {
                if (count[k] > 1) printf "[%s] ", k
            }
        }
    ' "${data_files[@]}")

    # 顯示衝突警報
    if [ -n "$collision_list" ]; then
        echo ""
        echo -e " ${C_WARN}:: SYSTEM INTEGRITY WARNING :: Command Conflict Detected${C_RST}"
        echo -e " ${C_WARN}   Duplicate Entries: ${collision_list}${C_RST}"
        echo -e " ${C_DESC}   (Please remove duplicates from app.csv)${C_RST}"
    fi
    
    echo ""
    
    # 1. 預處理迴圈
    for ((i=0; i<${#data_files[@]}; i++)); do
        file="${data_files[$i]}"
        
        if [ -f "$file" ]; then
            awk -v FPAT='([^,]*)|("[^"]+")' -v FILE_IDX="$i" '
                !/^#/ && NF >= 5 && $1 !~ /CATNO/ {
                    
                    cat_no = $1;  gsub(/^"|"$/, "", cat_no)
                    com_no = $2;  gsub(/^"|"$/, "", com_no)
                    cat_name = $3; gsub(/^"|"$/, "", cat_name)
                    com = $5;     gsub(/^"|"$/, "", com)
                    com2 = $6;    gsub(/^"|"$/, "", com2)
                    desc = $8;    gsub(/^"|"$/, "", desc)

                    if (cat_no == "") cat_no = 999
                    if (com_no == "") com_no = 99
                    if (desc == "") desc = "System Command"

                    printf "%d|%03d|%03d|%s|%s|%s|%s\n", FILE_IDX, cat_no, com_no, cat_name, com, com2, desc
                }
            ' "$file"
        fi
    done | \
    
    # 2. 排序
    sort -t'|' -k1,1n -k2,2n -k3,3n | \
    
    # 3. 渲染
    awk -F'|' -v C_CAT="$C_CAT" -v C_COM="$C_COM" -v C_SUB="$C_COM" -v C_DESC="$C_DESC" -v C_RST="$C_RST" '
        {
            cat_no = $2
            cat_name = $4
            com = $5
            com2 = $6
            desc = $7

            if (cat_no != last_cat_no) {
                if (NR > 1) print ""
                print " " C_CAT ":: " cat_name " ::" C_RST
                last_cat_no = cat_no
            }

            if (com2 == "") {
                printf "    %s%-9s%s %s%s%s\n", C_COM, com, C_RST, C_DESC, desc, C_RST
            } else {
                printf "    %s%s %s%-7s %s%s%s\n", C_COM, com, C_SUB, com2, C_RST " ", C_DESC, desc, C_RST
            }
        }
    '
}

# 模糊指令選單介面 - Fuzzy Command Menu Interface
function _mux_fuzzy_menu() {
   if ! command -v fzf &> /dev/null; then
        echo -e "\n\033[1;31m :: Neural Search Module (fzf) is missing.\033[0m"
        echo -ne "\033[1;32m :: Install interactive interface? [Y/n]: \033[0m"
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

    local cmd_list=$(
        {
            echo "0,1,Core,MUX,mux,,,Core Command Entry"
            cat "$SYSTEM_MOD" "$VENDOR_MOD" "$APP_MOD" 2>/dev/null
        } | awk -v FPAT='([^,]*)|("[^"]+")' '
        BEGIN {
            C_CMD="\x1b[1;37m"
            C_DESC="\x1b[1;30m"
            C_RESET="\x1b[0m"
        }
        
        !/^#/ && NF >= 5 && $1 !~ /CATNO/ {
            
            cmd = ""; sub_cmd = ""; desc = ""

            gsub(/^"|"$/, "", $5); cmd = $5

            if (NF >= 6) {
                gsub(/^"|"$/, "", $6); sub_cmd = $6
            }

            if (NF >= 8) {
                gsub(/^"|"$/, "", $8); desc = $8
            }
            
            if (sub_cmd != "") {
                display_name = cmd " " sub_cmd ""
            } else {
                display_name = cmd
            }

            printf " %s%-12s %s%s\n", C_CMD, display_name, C_DESC, desc;
        }
    ')

    local total_cmds=$(echo "$cmd_list" | grep -c "^ ")

    local selected=$(echo "$cmd_list" | fzf --ansi \
        --height=10 \
        --layout=reverse \
        --border=bottom \
        --prompt=" :: Neural Link › " \
        --header=" :: Slot Capacity: [6/$total_cmds] :: " \
        --info=hidden \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:yellow,prompt:cyan,pointer:red,marker:green,border:blue,header:240 \
        --bind="resize:clear-screen"
    )

    if [ -n "$selected" ]; then
        local cmd_to_run=$(echo "$selected" | awk '{print $1}')
        local prompt_text=$'\033[1;33m :: '$cmd_to_run$' \033[1;30m(Params?): \033[0m'
        read -e -p "$prompt_text" params < /dev/tty
        
        local final_cmd="$cmd_to_run"
        [ -n "$params" ] && final_cmd="$cmd_to_run $params"
        history -s "$final_cmd"
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
        echo -e ""
        sleep 0.5
        _bot_say "neural" "Welcome to the Grid, Commander."
        
        sleep 1.4
        mux reload
    else
        _bot_say "error" "Link failed. Neural rejection detected."
    fi
}

# 顯示兵工廠狀態 - Display Factory Status
function _factory_show_status() {
    local F_MAIN="\033[1;38;5;208m"
    local F_SUB="\033[1;37m"
    local F_WARN="\033[1;33m"
    local F_ERR="\033[1;31m"
    local F_GRAY="\033[1;30m"
    local F_CYAN="\033[1;36m"
    local F_RESET="\033[0m"

    local temp_file="$MUX_ROOT/app.csv.temp"
    local bak_dir="${MUX_BAK:-$MUX_ROOT/bak}"

    echo -e "${F_MAIN} :: Neural Forge Status Report ::${F_RESET}"
    echo -e "${F_GRAY}    --------------------------------${F_RESET}"

    if [ -f "$temp_file" ]; then
        local line_count=$(wc -l < "$temp_file")
        local node_count=$(( line_count - 1 ))
        [ "$node_count" -lt 0 ] && node_count=0
        
        local size=$(du -h "$temp_file" | cut -f1)
        
        echo -e "${F_GRAY}    Target  : ${F_WARN}app.csv.temp${F_RESET}"
        echo -e "${F_GRAY}    Size    : $size"
        echo -e "${F_GRAY}    Nodes   : ${F_SUB}$node_count active commands${F_RESET}"
    else
        echo -e "${F_ERR}    Target  : CRITICAL ERROR (Sandbox Missing)${F_RESET}"
    fi

    echo -e ""
    echo -e "${F_SUB}    [Temporal Snapshots (Time Stone)]${F_RESET}"
    
    local found_any=0
    
    local session_bak=$(ls "$bak_dir"/app.csv.*.bak 2>/dev/null | head -n 1)
    if [ -n "$session_bak" ]; then
        local fname=$(basename "$session_bak")
        local raw_ts=$(echo "$fname" | awk -F'.' '{print $3}')
        local fmt_ts="${raw_ts:0:4}-${raw_ts:4:2}-${raw_ts:6:2} ${raw_ts:8:2}:${raw_ts:10:2}:${raw_ts:12:2}"
        local f_size=$(du -h "$session_bak" | cut -f1)

        echo -e "    ${F_CYAN}[Session Origin]${F_RESET}"
        echo -e "    ›› Time : $fmt_ts"
        echo -e "    ›› File : $fname ($f_size)"
        found_any=1
    fi

    local atb_files=$(ls -t "$bak_dir"/app.csv.*.atb 2>/dev/null | head -n 3)
    
    if [ -n "$atb_files" ]; then
        [ "$found_any" -eq 1 ] && echo -e "${F_GRAY}    --------------------------------${F_RESET}"
        
        SAVEIFS=$IFS
        IFS=$'\n'
        for f_path in $atb_files; do
            local fname=$(basename "$f_path")
            local raw_ts=$(echo "$fname" | awk -F'.' '{print $3}')
            local fmt_ts="${raw_ts:0:4}-${raw_ts:4:2}-${raw_ts:6:2} ${raw_ts:8:2}:${raw_ts:10:2}:${raw_ts:12:2}"
            local f_size=$(du -h "$f_path" | cut -f1)

            echo -e "    ${F_MAIN}[Auto Save]${F_RESET}"
            echo -e "    ›› Time : $fmt_ts"
            echo -e "    ›› Size : $f_size"
            found_any=1
        done
        IFS=$SAVEIFS
    fi

    if [ "$found_any" -eq 0 ]; then
        echo -e "${F_GRAY} :: No temporal snapshots found in $bak_dir.${F_RESET}"
    fi

    echo -e "${F_GRAY}    --------------------------------${F_RESET}"
    
    if command -v _bot_say &> /dev/null; then
        _bot_say "factory" "Status report generated."
    fi
}

# 顯示兵工廠資訊 - Display Factory Info Manifest
function _factory_show_info() {
    local F_MAIN="\033[1;38;5;208m"
    local F_SUB="\033[1;37m"
    local F_WARN="\033[1;33m"
    local F_GRAY="\033[1;30m"
    local F_RESET="\033[0m"
    local C_GREEN="\033[1;32m"

    clear
    _draw_logo "factory"
    
    echo -e " ${F_MAIN}:: INDUSTRIAL MANIFEST ::${F_RESET}"
    echo ""
    echo -e "  ${F_GRAY}PROTOCOL   :${F_RESET} ${F_SUB}Factory Mode${F_RESET}"
    echo -e "  ${F_GRAY}ACCESS     :${F_RESET} ${F_MAIN}COMMANDER${F_RESET}"
    echo -e "  ${F_GRAY}PURPOSE    :${F_RESET} ${F_SUB}Neural Link Construction & Modification${F_RESET}"
    echo -e "  ${F_GRAY}TARGET     :${F_RESET} ${F_WARN}app.csv.temp${F_RESET}"
    echo ""
    echo -e " ${F_MAIN}:: WARNING ::${F_RESET}"
    echo -e "  ${F_GRAY}\"With great power comes great possibility of breaking things.\"${F_RESET}"
    echo ""
    
    echo -ne " ${C_GREEN}:: Ready to returning to forge? [Y/n]: ${F_RESET}"
    read choice
    
    if [[ "$choice" == "y" || "$choice" == "Y" || -z "$choice" ]]; then
        fac reload
    else
        echo ""
        _bot_say "system" "Stay in info mode."
    fi
}

# 兵工廠指令選擇器 - Factory Command Scanner
function _factory_fzf_menu() {
    local prompt_msg="${1:-Select Target}"
    
    local target_file="$MUX_ROOT/app.csv.temp"

    local list=$(awk -v FPAT='([^,]*)|("[^"]+")' '
        BEGIN {
            C_CMD="\x1b[1;37m"
            C_DESC="\x1b[1;30m"
            C_RESET="\x1b[0m"
        }
        
        !/^#/ && NF >= 5 && $1 !~ /CATNO/ {
            
            gsub(/^"|"$/, "", $5); cmd = $5
            gsub(/^"|"$/, "", $6); sub_cmd = $6
            gsub(/^"|"$/, "", $8); desc = $8

            if (sub_cmd != "") {
                display = cmd " " sub_cmd ""
            } else {
                display = cmd
            }

            printf " %s%-12s %s%s\n", C_CMD, display, C_DESC, desc
        }
    ' "$target_file")

    local total=$(echo "$list" | grep -c "^ ")

    local selected=$(echo "$list" | fzf --ansi \
        --height=10 \
        --layout=reverse \
        --border=bottom \
        --prompt=" :: $prompt_msg › " \
        --header=" :: Slot Capacity: [6/$total] :: " \
        --info=hidden \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        --bind="resize:clear-screen"
    )

    if [ -n "$selected" ]; then
        echo "$selected" | awk '{print $1, $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'
    fi
}

# 兵工廠指令選擇器 - Factory Category Scanner
function _factory_fzf_cat_selector() {
    local target_file="$MUX_ROOT/app.csv.temp"
    
    local cat_list=$(awk -v FPAT='([^,]*)|("[^"]+")' '
        BEGIN {
            C_ID="\033[1;33m" 
            C_NAME="\033[1;37m"
        }
        !/^#/ && NF >= 5 && $1 !~ /CATNO/ {
            id=$1; gsub(/^"|"$/, "", id)
            name=$3; gsub(/^"|"$/, "", name)

            if (!seen[id]++) {
                printf "%03d|%s\n", id, name
            }
        }
    ' "$target_file" | sort -n)

    local selected=$(echo "$cat_list" | awk -F'|' '{printf " \033[1;33m%03d  \033[1;37m%s\n", $1, $2}' | fzf --ansi \
        --height=10 \
        --layout=reverse \
        --border=bottom \
        --info=hidden \
        --prompt=" :: Select Category › " \
        --header=" :: Category Filter Mode :: " \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        --bind="resize:clear-screen"
    )

    if [ -n "$selected" ]; then
        echo "$selected" | awk '{print $1}'
    fi
}

# 兵工廠指令選擇器 - Factory inCommand Scanner
function _factory_fzf_cmd_in_cat() {
    local target_cat_no="$1"
    local target_file="$MUX_ROOT/app.csv.temp"
    
    if [ -z "$target_cat_no" ]; then return 1; fi

    local cmd_list=$(awk -v FPAT='([^,]*)|("[^"]+")' -v target="$target_cat_no" '
        BEGIN {
            C_CMD="\x1b[1;37m"
            C_SUB="\x1b[1;34m"
            C_RST="\x1b[0m"
        }
        
        !/^#/ && NF >= 5 && $1 !~ /CATNO/ {
            cat=$1; gsub(/^"|"$/, "", cat)
            
            if ((cat+0) == (target+0)) {
                gsub(/^"|"$/, "", $5); cmd = $5
                gsub(/^"|"$/, "", $6); sub_cmd = $6

                if (sub_cmd != "") {
                    printf " %s%s %s[%s]%s\n", C_CMD, cmd, C_SUB, sub_cmd, C_RST
                } else {
                    printf " %s%s%s\n", C_CMD, cmd, C_RST
                }
            }
        }
    ' "$target_file")
    
    local total=$(echo "$cmd_list" | grep -c "^ ")

    local selected=$(echo "$cmd_list" | fzf --ansi \
        --height=10 \
        --layout=reverse \
        --border=bottom \
        --info=hidden \
        --prompt=" :: Select Command › " \
        --header=" :: Category: [$target_cat_no:$total] :: " \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        --bind="resize:clear-screen"
    )

    if [ -n "$selected" ]; then
        echo "$selected" | awk '{print $1, $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'
    fi
}

# 詳細資料檢視器 - Detail Inspector
function _factory_fzf_detail_view() {
    local target_key="$1"
    local view_mode="${2:-VIEW}"  # 預設為 VIEW 模式，傳入 "NEW" 則開啟構造模式
    local target_file="$MUX_ROOT/app.csv.temp"

    if [ -z "$target_key" ]; then return; fi

    local t_com=$(echo "$target_key" | awk '{print $1}')
    local t_sub=""
    if [[ "$target_key" == *\[*\] ]]; then
        t_sub=$(echo "$target_key" | awk -F'[][]' '{print $2}')
    fi

    local report=$(awk -v FPAT='([^,]*)|("[^"]+")' \
                       -v t_com="$t_com" \
                       -v t_sub="$t_sub" \
                       -v mode="$view_mode" '
        BEGIN {
            # 基礎色票
            C_LBL="\033[1;30m"
            C_VAL="\033[1;37m"
            C_TAG="\033[1;33m"
            C_RST="\033[0m"
            sep="----------"
            
            # 特殊狀態色 (只在 NEW 模式生效)
            C_EMP_R="\033[1;31m[Empty]\033[0m"  # 必填 (紅)
            C_EMP_Y="\033[1;33m[Empty]\033[0m"  # 選填 (黃)
            C_UNK="\033[1;30m[Unknown]\033[0m" # 未知 (灰)
        }

        !/^#/ && NF >= 5 {
            gsub(/^"|"$/, "", $5); c=$5
            gsub(/^"|"$/, "", $6); s=$6
            
            match_found = 0
            if (c == t_com) {
                if (t_sub == "" && s == "") match_found = 1
                if (t_sub != "" && s == t_sub) match_found = 1
            }

            if (match_found) {
                cat=$1;  gsub(/^"|"$/, "", cat)
                comno=$2; gsub(/^"|"$/, "", comno)
                catname=$3; gsub(/^"|"$/, "", catname)
                type=$4; gsub(/^"|"$/, "", type); if(type=="") type="[Empty]"
                
                hud=$8;  gsub(/^"|"$/, "", hud); if(hud=="") hud="[Empty]"
                ui=$9;   gsub(/^"|"$/, "", ui);  if(ui=="")  ui="[Empty]"
                pkg=$10; gsub(/^"|"$/, "", pkg); if(pkg=="") pkg="[Empty]"
                act=$11; gsub(/^"|"$/, "", act); if(act=="") act="[Empty]"
                
                ihead=$12; gsub(/^"|"$/, "", ihead); if(ihead=="") ihead="[Empty]"
                ibody=$13; gsub(/^"|"$/, "", ibody); if(ibody=="") ibody="[Empty]"
                uri=$14;   gsub(/^"|"$/, "", uri);   if(uri=="")   uri="[Empty]"
                mime=$15; gsub(/^"|"$/, "", mime); if(mime=="") mime="[Empty]"
                cate=$16; gsub(/^"|"$/, "", cate); if(cate=="") cate="[Empty]"
                flag=$17; gsub(/^"|"$/, "", flag); if(flag=="") flag="[Empty]"
                ex=$18; gsub(/^"|"$/, "", ex); if(ex=="") ex="[Empty]"
                extra=$19; gsub(/^"|"$/, "", extra); if(extra=="") extra="[Empty]"
                engine=$20; gsub(/^"|"$/, "", engine); if(engine=="") engine="[Empty]"

                if (s == "") s_disp = "[Empty]"; else s_disp = s
                
                if (mode == "NEW") {
                    catname = "\033[1;32mNEW NODE\033[0m"
                    cat = "NEW"
                    comno = "XX"
                    
                    if (type == "NA") {
                        if (c == "[Empty]") c = C_EMP_R
                        if (pkg == "[Empty]") pkg = C_EMP_R
                        if (act == "[Empty]") act = C_EMP_R
                        
                        if (hud == "[Empty]") hud = C_UNK
                        if (ui == "[Empty]") ui = C_UNK
                    }
                    else if (type == "NB") {
                        if (ihead == "[Empty]") ihead = C_EMP_R
                        if (pkg == "[Empty]") pkg = C_EMP_Y
                        if (act == "[Empty]") act = C_EMP_Y
                        
                        if (hud == "[Empty]") hud = C_UNK
                        if (ui == "[Empty]") ui = C_UNK
                    }
                }

                command_str = c " " s_disp
                final_uri = uri
                if (engine != "[Empty]") final_uri = engine

                if (type == "NA" || type == "NA") { # Hack for visual grouping
                    printf "%s[%s]%s\n", C_TAG, catname, C_RST
                    printf "%s[%3s:%2s]%s[%s: %s]%s\n", C_TAG, cat, comno, C_TAG, "TYPE", type, C_RST
                    printf " %sCommand:%s %s\n", C_LBL, C_VAL, command_str
                    printf " %sDetail :%s %s\n", C_LBL, C_VAL, hud
                    printf " %sUI     :%s %s\n", C_LBL, C_VAL, ui
                    printf "%s%s%s\n", C_LBL, sep, C_RST
                    printf " %sPackage:%s %s\n", C_LBL, C_VAL, pkg
                    printf " %sTarget :%s %s\n", C_LBL, C_VAL, act
                    printf " %sFlag   :%s %s\n", C_LBL, C_VAL, flag
                }
                else if (type == "NB") {
                    printf "%s[%s]%s\n", C_TAG, catname, C_RST
                    printf "%s[%3s:%2s]%s[%s: %s]%s\n", C_TAG, cat, comno, C_TAG, "TYPE", type, C_RST
                    printf " %sCommand:%s %s\n", C_LBL, C_VAL, command_str
                    printf " %sDetail :%s %s\n", C_LBL, C_VAL, hud
                    printf " %sUI     :%s %s\n", C_LBL, C_VAL, ui
                    printf "%s%s%s\n", C_LBL, sep, C_RST
                    printf " %sIntent :%s %s%s\n", C_LBL, C_VAL, ihead, ibody
                    printf " %sURI    :%s %s\n", C_LBL, C_VAL, final_uri
                    printf " %sCate   :%s %s\n", C_LBL, C_VAL, cate
                    printf " %sMime   :%s %s\n", C_LBL, C_VAL, mime
                    printf " %sEXTRA  :%s %s %s\n", C_LBL, C_VAL, ex, extra
                    printf " %sPackage:%s %s\n", C_LBL, C_VAL, pkg
                    printf " %sTarget :%s %s\n", C_LBL, C_VAL, act
                }
                
                #  NEW 模式顯示
                if (mode == "NEW") {
                    printf "%s%s%s\n", C_LBL, sep, C_RST
                    printf "  \033[1;32m[ Confirm ]\033[0m\n"
                }
                
                exit
            }
        }
    ' "$target_file")

    if [ -z "$report" ]; then return; fi

    # 動態計算 fzf 選單大小
    local line_count=$(echo "$report" | wc -l)
    local dynamic_height=$(( line_count + 4 ))

    echo -e "$report" | fzf --ansi \
        --height="$dynamic_height" \
        --layout=reverse \
        --border=bottom \
        --header=" :: Enter to return, Esc to exit ::" \
        --info=hidden \
        --prompt=" :: Details › " \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        --bind="resize:clear-screen" \
        > /dev/null
}

# 7. 類別編輯子選單 - Category Edit Submenu
# 用法: _factory_fzf_catedit_submenu "Category Name"
function _factory_fzf_catedit_submenu() {
    local cat_name="$1"
    
    # 選項定義
    local opt_title="Edit [${cat_name}]"
    local opt_cmds="Edit Command in [${cat_name}]"
    
    # 動態計算 fzf 選單大小
    local line_count=$(echo "$report" | wc -l)
    local dynamic_height=$(( line_count + 4 ))
    
    local selected=$(echo -e "${opt_title}\n${opt_cmds}" | fzf --ansi \
        --height="$dynamic_height" \
        --layout=reverse \
        --border=top \
        --border-label=" :: Sub-Menu :: " \
        --header=" :: Enter to return, Esc to exit :: " \
        --prompt=" Action › " \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:hidden,prompt:208,pointer:red,marker:208,border:208,header:240 \
        --bind="resize:clear-screen"
    )
    
    echo "$selected"
}

# 3. 創建神經連結選單 - Create Neural Link Selector
function _factory_fzf_template_selector() {
    # 預留的權限接口 (目前用 # 註解標記，未來可傳入 "true" 開啟)
    # local allow_sys="${1:-false}" 

    # 1. 定義基礎選項 (Type | Description)
    # 使用 | 來分隔顯示文字與後端邏輯(如果有的話)，這裡主要用於 awk 排版
    local list="Type NA|Native App\nType NB|(Default Browser)"

    # 2. 進階選項接口 (SYS / SSL) - 先用 # 標記起來
    # if [ "$allow_sys" == "true" ]; then
    #     list="$list\nType SYS|(System Command)\nType SSL|(Secure Shell Link)"
    # fi

    # 3. 底部選項
    # 分隔線與取消按鈕
    list="$list\n------|SEPARATOR\nCancel|Abort Operation"

    # 4. 渲染引擎 (Awk Rendering)
    local C_TYPE="\033[1;33m"
    local C_DESC="\033[1;37m"
    local C_SEP="\033[1;30m" 
    local C_CAN="\033[1;31m"  
    local C_RST="\033[0m"

    local menu_output=$(echo -e "$list" | awk -F'|' \
        -v C_TYPE="$C_TYPE" -v C_DESC="$C_DESC" \
        -v C_SEP="$C_SEP" -v C_CAN="$C_CAN" -v C_RST="$C_RST" '{
        
        key = $1
        desc = $2

        if (key == "------") {
            printf " %s----------%s\n", C_SEP, C_RST
        }
        else if (key == "Cancel") {
            printf " %s%-30s%s\n", C_CAN, key, C_RST
        }
        else {
            if (desc != "") {
                 printf " %s%-7s %s%s%s\n", C_TYPE, key, C_DESC, desc, C_RST
            } else {
                 printf " %s%-7s%s\n", C_TYPE, key, C_RST
            }
        }
    }')

    local line_count=$(echo "$menu_output" | wc -l)
    local dynamic_height=$(( line_count + 4 ))

    local selected=$(echo -e "$menu_output" | fzf --ansi \
        --height="$dynamic_height" \
        --layout=reverse \
        --border=bottom \
        --prompt=" :: Select Type › " \
        --header=" :: Create Neural Link :: " \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        --bind="resize:clear-screen"
    )
}

# 4. 通用修改界面 - Universal Edit Interface
# 用法: _factory_fzf_edit_field "欄位名" "當前值" "指令類型(NA/NB)"
function _factory_fzf_edit_field() {
    local field_name="$1"
    local current_val="$2"
    local node_type="$3"

    # === 1. 視覺定義 (Visual Assets) ===
    local C_TAG="\033[1;33m"      # 標題黃
    local C_LBL="\033[1;30m"      # 標籤灰
    local C_VAL="\033[1;37m"      # 數值白
    local C_RST="\033[0m"         # 重置
    local C_EMP_R="\033[1;31m[Empty]\033[0m"  # 紅色必填
    local C_EMP_Y="\033[1;33m[Empty]\033[0m"  # 黃色選填
    local C_UNK="\033[1;30m[Empty]\033[0m"    # 灰色未知
    
    # 分隔線 (嚴格遵守 ui.sh 標準長度)
    local sep="----------"

    # === 2. 顏色邏輯判定 (Color Logic) ===
    # 根據 node_type 與 field_name 決定 current_val 的顯示顏色
    local display_val="$current_val"

    # 如果值為空，先轉為標準標記
    if [ -z "$display_val" ] || [ "$display_val" == "[Empty]" ]; then
        if [ "$node_type" == "NA" ]; then
            # NA 模式: Command, Package, Target 為紅
            case "$field_name" in
                "Command"|"Package"|"Target") display_val="$C_EMP_R" ;;
                *) display_val="$C_UNK" ;;
            esac
        elif [ "$node_type" == "NB" ]; then
            # NB 模式: Intent 為紅, Pkg/Target 為黃
            case "$field_name" in
                "Intent"|"I-Head"|"I-Body") display_val="$C_EMP_R" ;;
                "Package"|"Target") display_val="$C_EMP_Y" ;;
                *) display_val="$C_UNK" ;;
            esac
        else
            display_val="$C_UNK"
        fi
    else
        # 有值的情況，顯示白色
        display_val="${C_VAL}${display_val}${C_RST}"
    fi

    # === 3. 介面構建 (Interface Construction) ===
    # FZF Header 結構: 
    # [欄位名]
    # ----------
    # - Current: 值
    # ----------
    
    local header_str="${C_TAG}[ ${field_name} ]${C_RST}\n${C_LBL}${sep}${C_RST}\n ${C_LBL}- Current:${C_RST} ${display_val}\n${C_LBL}${sep}${C_RST}"

    # === 4. 執行 FZF (Execution) ===
    # --print-query: 第一行輸出使用者輸入的文字 (New Value)
    # --disabled: 禁止過濾，確保 Confirm 按鈕不消失
    # List 中只放 Confirm，分隔線放在 Header 底部以保持結構穩固
    
    local result=$(echo -e "Confirm" | fzf --ansi \
        --disabled \
        --print-query \
        --layout=reverse \
        --height=10 \
        --border=bottom \
        --header-lines=0 \
        --header="$(echo -e $header_str)" \
        --prompt=" :: Modify  › " \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        --bind="resize:clear-screen"
    )

    # === 5. 結果處理 (Output Handling) ===
    # FZF 輸出格式:
    # Line 1: Query String (使用者輸入的新值)
    # Line 2: Selected Item (應該是 "Confirm")
    
    local new_input=$(echo "$result" | head -n 1)
    local selection=$(echo "$result" | tail -n 1)

    # 如果使用者按 ESC，result 會是空的 (或只有 query 但 exit code 非 0)
    # 但 fzf --print-query 即使按 ESC 有時也會輸出，需配合 exit code 判斷
    # 這裡由調用者 (Controller) 檢查 $?
    
    # 回傳輸入值
    echo "$new_input"
}

# 5. 戰術輸入監視器 - Tactical Input Monitor (Standard CLI)
# 用法: _factory_input_monitor "欄位名稱" "當前數值" "節點類型(NA/NB)"
function _factory_input_monitor() {
    local field_name="$1"
    local current_val="$2"
    local node_type="$3"

    # === 1. 視覺資產 (Visual Assets) ===
    local C_TIT="\033[1;38;5;208m"    # 標題橘
    local C_TXT="\033[1;37m"          # 內文白
    local C_GRY="\033[1;30m"          # 註解灰
    local C_RED="\033[1;31m"          # 警告紅
    local C_YEL="\033[1;33m"          # 提示黃
    local C_RST="\033[0m"             # 重置
    local SEP="----------"            # 標準分隔線 (10 chars)

    # === 2. 戰術指導字典 (Tactical Notice Dictionary) ===
    # 針對 18 個可編輯欄位提供詳細說明
    local notice_msg=""

    case "$field_name" in
        # 基礎識別區
        "CATNO")   notice_msg="Category Group ID.\n - 1:Network, 2:System, 3:Media, 4:Social, 5:Game, 6:Coding\n - 99:Others (Auto-sorted)" ;;
        "COMNO")   notice_msg="Sorting Order Index.\n - Lower numbers appear first in the menu.\n - Range: 00-99" ;;
        "CATNAME") notice_msg="Visual Category Label.\n - Used for Menu Grouping (e.g., 'Network', 'CyberDeck').\n - Auto-mapped by CATNO usually." ;;
        
        # 指令觸發區
        "COM")     notice_msg="Primary Command Alias.\n - The main trigger keyword in terminal.\n - Keep it short (e.g., 'yt', 'fb')." ;;
        "COM2")    notice_msg="Secondary Alias (Optional).\n - Alternative trigger keyword.\n - Useful for abbreviations." ;;
        
        # 顯示互動區
        "HUDNAME") notice_msg="HUD / Voice Response Text.\n - What the Bot says when executing.\n - e.g., 'Launching Neural Link...'" ;;
        "UINAME")  notice_msg="FZF Menu Display Name.\n - The descriptive name shown in the selector.\n - e.g., 'YouTube Studio'" ;;
        
        # 核心執行區 (NA)
        "PKG")     notice_msg="Android Package Name (Application ID).\n - Required for NA mode.\n - e.g., 'com.termux', 'com.google.android.youtube'" ;;
        "TARGET")  notice_msg="Activity Class Name / Component.\n - Required for NA mode (Launch Target).\n - e.g., 'com.termux.app.TermuxActivity'" ;;
        
        # 核心執行區 (NB/SYS)
        "IHEAD")   notice_msg="Intent Namespace (Action Head).\n - Default: 'android.intent.action'\n - Can be customized for Broadcasts." ;;
        "IBODY")   notice_msg="Intent Action Body.\n - The specific action to fire.\n - e.g., 'VIEW', 'MAIN', 'SEND', 'DIAL'" ;;
        "URI")     notice_msg="Data URI / Scheme.\n - The target URL or Protocol.\n - e.g., 'https://google.com', 'tel:12345', 'file:///sdcard'" ;;
        "MIME")    notice_msg="MIME Type Specification.\n - Defines data type for Intent.\n - e.g., 'text/plain', 'image/png'" ;;
        "CATE")    notice_msg="Intent Category.\n - Default: 'android.intent.category.DEFAULT'\n - Browser: 'android.intent.category.BROWSABLE'" ;;
        "FLAG")    notice_msg="Launch Flags (Integer or Hex).\n - Control task behavior.\n - e.g., '0x10000000' (NEW_TASK), '0x04000000' (CLEAR_TOP)" ;;
        
        # 擴充參數區
        "EX")      notice_msg="Extra Key / Shell Argument.\n - For AM: '--es', '--ei', '--ez'\n - For Shell: Standard flags (e.g., '-f')" ;;
        "EXTRA")   notice_msg="Extra Value / Payload.\n - The data paired with the Key.\n - e.g., 'search_query', 'true', '100'" ;;
        "ENGINE")  notice_msg="Search Engine Pattern.\n - Used for Smart Query expansion.\n - e.g., 'https://www.google.com/search?q=%s'" ;;
        
        *) notice_msg="No specific manual available for this sector." ;;
    esac

    # === 3. 當前值著色邏輯 (Color Logic) ===
    local display_val="$current_val"
    local raw_display_val="$current_val" # 用於 read 的預設值 (如果需要)

    if [ -z "$display_val" ] || [ "$display_val" == "[Empty]" ]; then
        local C_EMP_R="\033[1;31m[Empty]\033[0m"
        local C_EMP_Y="\033[1;33m[Empty]\033[0m"
        local C_UNK="\033[1;30m[Empty]\033[0m"

        if [ "$node_type" == "NA" ]; then
            case "$field_name" in
                "COM"|"PKG"|"TARGET") display_val="$C_EMP_R" ;;
                *) display_val="$C_UNK" ;;
            esac
        elif [ "$node_type" == "NB" ]; then
            case "$field_name" in
                "IHEAD"|"IBODY") display_val="$C_EMP_R" ;;
                "PKG"|"TARGET") display_val="$C_EMP_Y" ;;
                *) display_val="$C_UNK" ;;
            esac
        else
            display_val="$C_UNK"
        fi
        raw_display_val="" # 如果是 Empty，輸入時預設為空
    else
        display_val="${C_TXT}${display_val}${C_RST}"
    fi

    # === 4. 介面渲染 (Rendering) ===
    clear
    _draw_logo "factory" # 保持 Logo 存在，維持系統感
    
    echo -e "${C_TIT} :: Notice :: ${C_RST}"
    echo -e "${C_TXT}${notice_msg}${C_RST}"
    echo -e "${C_GRY}${SEP}${C_RST}"
    echo -e " Current: ${display_val}"
    echo -e ""
    
    # === 5. 執行輸入 (Input Execution) ===
    # 使用 read -e 允許方向鍵編輯
    # -p 提示文字
    
    local new_input=""
    read -e -p " - Input: " new_input

    # === 6. 結果回傳 (Return) ===
    # 如果使用者直接按 Enter (空字串)，則回傳原始值(保持不變) 還是 回傳空值(刪除)?
    # 這裡依照一般 CLI 習慣：
    # 如果要刪除內容，通常需要輸入特定指令(如 "NULL")，或者我們約定好：
    # 既然是 "Input"，如果留空代表 "不想改"，所以回傳當前值。
    # **但是** 你的需求是 "可編輯的位置"，有時需要把原本有的字刪掉。
    # 為了最直覺的操作，這裡直接回傳使用者輸入的東西。
    # 邏輯層 (Controller) 必須判斷：如果輸入為空，是否要覆蓋舊值？
    # 建議：Controller 若收到空字串，視為 "保持原樣"。若要清空，需輸入空格或特定字元。
    # 或者，我們在這裡判斷：如果輸入為空，echo "$current_val" (保持不變)。
    
    if [ -z "$new_input" ]; then
        echo "$current_val"
    else
        echo "$new_input"
    fi
}

# 編輯選單生成器 - Context-Aware Edit Menu
function _factory_fzf_edit_menu() {
    local type="$1"
    
    # === 1. 定義共用房間 (Common Rooms) ===
    # Format: "ID|Label|Description"
    local common_menu="R1|Identity & Position|Category, ID, Type\nR2|Command Aliases|Primary & Secondary Triggers\nR3|HUD Description|Menu Display Text\nR4|System Codename|Internal UI Reference"
    
    # === 2. 定義專屬房間 (Specific Rooms) ===
    local specific_menu=""
    
    if [ "$type" == "NA" ]; then
        # NA 地圖
        specific_menu="R5|Package ID|Application Package Name\nR6|Launch Target|Activity Class Name\nR7|Launch Flags|Intent Flags (Hex/Int)"
    elif [ "$type" == "NB" ]; then
        # NB 地圖
        specific_menu="R5|Intent Action|Namespace & Body\nR6|URI & Engine|Smart Link Injection\nR7|Category|Intent Category\nR8|Mime Type|Data Type Specification\nR9|Extra Data|Extended Arguments\nR10|Package ID|Application Package (Optional)\nR11|Launch Target|Activity Class (Optional)"
    fi

    # === 3. 合併與渲染 ===
    # 使用 awk 美化輸出，左邊是房間號，右邊是說明
    # 這裡我們用與 detail_view 一致的風格
    
    local C_ID="\033[1;33m"   # 黃色 ID
    local C_LBL="\033[1;37m"  # 白色標題
    local C_DSC="\033[1;30m"  # 灰色說明
    local C_RST="\033[0m"

    echo -e "${common_menu}\n${specific_menu}" | awk -F'|' \
        -v C_ID="$C_ID" -v C_LBL="$C_LBL" -v C_DSC="$C_DSC" -v C_RST="$C_RST" '{
        printf " %s%-4s%s %s%-20s%s %s%s%s\n", C_ID, $1, C_RST, C_LBL, $2, C_RST, C_DSC, $3, C_RST
    }' | fzf --ansi \
        --height=20 \
        --layout=reverse \
        --border=bottom \
        --header=" :: Neural Edit Matrix :: " \
        --prompt=" Select Room › " \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:208,header:240 \
        --bind="resize:clear-screen"
}

# 偽・星門 - UI Mask / Fake Gate
function _ui_fake_gate() {
    local target_system="${1:-core}"
    local theme_color=""
    local theme_text=""
    local icon=""
    
    if [ "$target_system" == "factory" ]; then
        theme_color="\033[1;38;5;208m"
        theme_text="NEURAL FORGE"
        icon=""
    else
        theme_color="\033[1;36m"
        theme_text="SYSTEM CORE"
        icon=""
    fi

    local C_TXT="\033[1;30m"
    local C_RESET="\033[0m"

    stty -echo
    tput civis
    clear

    local rows=$(tput lines)
    local cols=$(tput cols)
    local bar_len=$(( cols * 45 / 100 ))
    if [ "$bar_len" -lt 15 ]; then bar_len=15; fi

    local center_row=$(( rows / 2 ))
    local bar_start_col=$(( (cols - bar_len - 2) / 2 ))
    local stats_start_col=$(( (cols - 24) / 2 ))
    local title_start_col=$(( (cols - 25) / 2 ))

    tput cup $((center_row - 2)) $title_start_col
    echo -e "${C_TXT}:: GATE ${theme_color}${theme_text} ${icon}${C_TXT}::${C_RESET}"

    local hex_addr="0x0000"

    for i in $(seq 1 "$bar_len"); do
        local pct=$(( i * 100 / bar_len ))
        
        tput cup $center_row $bar_start_col
        echo -ne "${C_TXT}[${C_RESET}"
        
        if [ "$i" -gt 0 ]; then
            printf "${theme_color}%.0s#${C_RESET}" $(seq 1 "$i")
        fi
        
        local remain=$(( bar_len - i ))
        if [ "$remain" -gt 0 ]; then
            printf "%.0s " $(seq 1 "$remain")
        fi
        echo -ne "${C_TXT}]${C_RESET}"

        tput cup $((center_row + 2)) $stats_start_col
        
        if [ $((i % 2)) -eq 0 ]; then
            hex_addr=$(printf "0x%04X" $((RANDOM%65535)))
        fi
        
        echo -ne "${C_TXT}:: ${theme_color}"
        printf "%3d%%" "$pct"
        echo -ne "${C_TXT} :: MEM: ${hex_addr}${C_RESET}\033[K"

        sleep 0.015
    done

    tput cnorm
    stty sane
    clear
}