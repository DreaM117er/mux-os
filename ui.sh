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
        echo -e "\n\033[1;31m :: Neural Module (fzf) missing.\033[0m"
        return 1
    fi

    local cmd_list=$(
        {
            echo "0,0,Core,SYS,mux,,,Core Command Entry"
            cat "$SYSTEM_MOD" "$VENDOR_MOD" "$APP_MOD" 2>/dev/null
        } | awk -v FPAT='([^,]*)|("[^"]+")' '
        BEGIN {
            C_CMD="\x1b[1;37m"
            C_DESC="\x1b[1;30m"
            C_RST="\x1b[0m"
        }
        !/^#/ && NF >= 5 && $1 !~ /CATNO/ {
            c=$5; gsub(/^"|"$/, "", c);
            s=$6; gsub(/^"|"$/, "", s);
            d=$8; gsub(/^"|"$/, "", d);

            if (s != "") {
                full_cmd = c " " s
            } else {
                full_cmd = c
            }
            
            printf " %s%-18s\t%s%s\n", C_CMD, full_cmd, C_DESC, d
        }'
    )

    local total_cmds=$(echo "$cmd_list" | grep -c "^ ")
    
    local selected=$(echo "$cmd_list" | fzf --ansi \
        --height=10 \
        --layout=reverse \
        --border=bottom \
        --tabstop=4 \
        --prompt=" :: Neural Link › " \
        --header=" :: Slot Capacity: [6/$total_cmds] :: " \
        --info=hidden \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:yellow,prompt:cyan,pointer:red,marker:green,border:blue,header:240 \
        --bind="resize:clear-screen"
    )

    if [ -n "$selected" ]; then
        local raw_part=$(echo "$selected" | awk -F'\t' '{print $1}')
        local clean_base=$(echo "$raw_part" | sed "s/$(printf '\033')\[[0-9;]*m//g")
        local cmd_base=$(echo "$clean_base" | sed 's/^[ \t]*//;s/[ \t]*$//')

        echo -ne "\033[1;33m :: $cmd_base \033[1;30m(Params?): \033[0m"
        read -e user_params < /dev/tty
        
        local final_cmd="$cmd_base"
        [ -n "$user_params" ] && final_cmd="$cmd_base $user_params"
        
        history -s "$final_cmd"
        
        if [[ "$cmd_base" == "mux" ]]; then
            $final_cmd
        else
            echo -e "\033[1;30m     ›› Executing: $final_cmd\033[0m"
            eval "$final_cmd"
        fi
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
        echo -e ""
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
    echo -e "${F_GRAY}    --------------------------${F_RESET}"

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
        [ "$found_any" -eq 1 ] && echo -e "${F_GRAY}    --------------------------${F_RESET}"
        
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

    echo -e "${F_GRAY}    --------------------------${F_RESET}"
    
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
    local mode="${2:-VIEW}"
    local cat_filter="$3" 
    
    local target_file="$MUX_ROOT/app.csv.temp"
    if [ ! -f "$target_file" ]; then target_file="$MUX_ROOT/app.csv"; fi

    local border_color="208"
    local header_msg="NEURAL FORGE"
    
    case "$mode" in
        "DEL") border_color="196"; header_msg="DELETE MODE" ;;
        "NEW") border_color="46";  header_msg="CREATION MODE" ;;
        "EDIT") border_color="46"; header_msg="EDIT PROTOCOL" ;;
        *)     border_color="208"; header_msg="CONTROL DECK" ;;
    esac

    if [ -n "$cat_filter" ]; then
        header_msg="FOCUS: $cat_filter"
    fi

    local list=$(awk -v FPAT='([^,]*)|("[^"]+")' -v filter="$cat_filter" '
        BEGIN {
            C_RST="\033[0m"
            C_CMD="\033[1;37m"
            C_DESC="\033[1;30m"
            
            TAG_N="\033[1;36m[N]\033[0m " # Cyan   : New
            TAG_E="\033[1;33m[E]\033[0m " # Yellow : Edit
            TAG_S="\033[1;32m[S]\033[0m " # Green  : Saved
            TAG_F="\033[1;31m[F]\033[0m " # Red    : Fail
            TAG_P="\033[1;30m[P]\033[0m " # Gray   : Pass
        }
        
        !/^#/ && NF >= 5 && $1 !~ /CATNO/ {
            gsub(/^"|"$/, "", $3); cat = $3 
            
            if (filter != "" && cat != filter) next

            gsub(/^"|"$/, "", $5); cmd = $5
            gsub(/^"|"$/, "", $6); sub_cmd = $6
            gsub(/^"|"$/, "", $8); desc = $8
            gsub(/^"|"$/, "", $7); st = $7 

            if (st == "B" || st == "C") next

            prefix = TAG_P
            if (st == "N") prefix = TAG_N
            if (st == "E") prefix = TAG_E
            if (st == "S") prefix = TAG_S
            if (st == "F") prefix = TAG_F
            
            if (st == "")  prefix = TAG_P 

            if (sub_cmd != "") {
                display = cmd " \047" sub_cmd "\047"
            } else {
                display = cmd
            }

            printf " %s%s%-16s\t%s%s\n", prefix, C_CMD, display, C_DESC, desc
        }
    ' "$target_file")

    local total=$(echo "$list" | grep -c "^ ")

    local selected=$(echo "$list" | fzf --ansi \
        --height=12 \
        --layout=reverse \
        --border-label=" :: $header_msg :: " \
        --border=bottom \
        --tabstop=1 \
        --prompt=" :: $prompt_msg › " \
        --header=" :: Nodes: [$total] ::" \
        --info=hidden \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:$border_color,pointer:red,marker:208,border:$border_color,header:240 \
        --bind="resize:clear-screen"
    )

    if [ -n "$selected" ]; then
        local raw_part=$(echo "$selected" | awk -F'\t' '{print $1}')
        local clean_part=$(echo "$raw_part" | sed "s/$(printf '\033')\[[0-9;]*m//g")
        local key_only=$(echo "$clean_part" | sed 's/^[ \t]*\[.\][ \t]*//')
        echo "$key_only" | sed 's/^[ \t]*//;s/[ \t]*$//'
    fi
}

# 兵工廠指令選擇器 - Factory Category Scanner
function _factory_fzf_cat_selector() {
    local mode="${1:-VIEW}"
    local target_file="$MUX_ROOT/app.csv.temp"
    
    # --- 1. 樣式定義 ---
    local border_color="208"
    local prompt_color="208"
    local header_msg="CATEGORY FILTER MODE"
    local prompt_msg="Select Category"

    case "$mode" in
        "DEL")
            border_color="196"
            prompt_color="196"
            header_msg="DELETE CATEGORY MODE"
            prompt_msg="Choose"
            ;;
        *)
            border_color="208"
            ;;
    esac

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
        --border-label=" :: $header_msg :: " \
        --border=bottom \
        --info=hidden \
        --prompt=" :: $prompt_msg › " \
        --header=" :: Enter to Select, Esc to Return ::" \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:$prompt_color,pointer:red,marker:208,border:$border_color,header:240 \
        --bind="resize:clear-screen"
    )

    if [ -n "$selected" ]; then
        echo "$selected" | awk '{print $1}'
    fi
}

# 兵工廠指令選擇器 - Factory inCommand Scanner
function _factory_fzf_cmd_in_cat() {
    local target_cat_name="$1"
    local mode="${2:-VIEW}"
    local target_file="$MUX_ROOT/app.csv.temp"
    
    if [ -z "$target_cat_name" ]; then return 1; fi

    # --- 1. 樣式定義 ---
    local border_color="208"
    local prompt_msg="Select Command"
    
    case "$mode" in
        "DEL")
            border_color="196"
            prompt_msg="Delete Command"
            ;;
        *)
            border_color="208"
            ;;
    esac

    local cmd_list=$(awk -v FPAT='([^,]*)|("[^"]+")' -v target="$target_cat_name" '
        BEGIN {
            C_CMD="\x1b[1;37m"
            C_RST="\x1b[0m"
        }
        
        !/^#/ && NF >= 5 && $1 !~ /CATNO/ {
            csv_cat=$3; gsub(/^"|"$/, "", csv_cat)
            
            if (csv_cat == target) {
                gsub(/^"|"$/, "", $5); cmd = $5
                gsub(/^"|"$/, "", $6); sub_cmd = $6
                
                if (sub_cmd != "") {
                    printf " %s%s '"'"'%s'"'"'%s\n", C_CMD, cmd, sub_cmd, C_RST
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
        --border-label=" :: Category: [${target_cat_name}] [$total] :: " \
        --border=bottom \
        --info=hidden \
        --prompt=" :: $prompt_msg › " \
        --header=" :: Enter to Select, Esc to Return ::" \
        --pointer="››" \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:208,pointer:red,marker:208,border:$border_color,header:240 \
        --bind="resize:clear-screen"
    )

    if [ -n "$selected" ]; then
        echo "$selected" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[ \t]*//;s/[ \t]*$//'
    fi
}

# 詳細資料檢視器 - Detail Inspector
function _factory_fzf_detail_view() {
    local target_key="$1"
    local view_mode="${2:-VIEW}"

    if [ -z "$target_key" ]; then return; fi

    # 1. 呼叫核心讀取模組 (這會自動產生 _VAL_PKG, _VAL_TYPE 等變數)
    # 注意：這裡依賴 factory.sh 的函式，確保 factory.sh 已載入
    if ! command -v _fac_neural_read &> /dev/null; then
        echo "Error: Neural Reader not found."
        return
    fi

    # 讀取資料
    _fac_neural_read "$target_key" || return

    # 2. 定義樣式 (Bash Native)
    local C_LBL="\033[1;30m"
    local C_VAL="\033[1;37m"
    local C_TAG="\033[1;33m"
    local C_RST="\033[0m"
    local C_EMP_R="\033[1;31m[Empty]\033[0m"
    local C_EMP_Y="\033[1;33m[Empty]\033[0m"
    local C_UNK="\033[1;30m[Unknown]\033[0m"
    local SEP="----------"
    local S="\t"

    # 3. 資料正規化 (Display Logic)
    local d_sub="${_VAL_COM2:-[Empty]}"
    local d_type="${_VAL_TYPE:-[Empty]}"
    local d_hud="${_VAL_HUDNAME:-[Empty]}"
    local d_ui="${_VAL_UINAME:-[Empty]}"
    local d_pkg="${_VAL_PKG:-[Empty]}"
    local d_act="${_VAL_TARGET:-[Empty]}"
    local d_uri="${_VAL_URI:-[Empty]}"
    local d_eng="${_VAL_ENGINE:-[Empty]}"
    
    # 針對不同模式的特殊處理
    local cat_name_display="$_VAL_CATNAME"
    local cat_no_display=$(printf "%03d" "$_VAL_CATNO" 2>/dev/null || echo "$_VAL_CATNO")
    local com_no_display=$(printf "%3s" "$_VAL_COMNO" 2>/dev/null || echo "$_VAL_COMNO")
    
    if [ "$view_mode" == "NEW" ]; then
        cat_name_display="NEW NODE"
        cat_no_display="NEW"
        com_no_display="XX"
    fi

    # 錯誤標記邏輯 (Validation Highlight)
    if [[ "$view_mode" == "NEW" || "$view_mode" == "EDIT" ]]; then
        if [ "$_VAL_TYPE" == "NA" ]; then
             if [ -z "$_VAL_PKG" ]; then d_pkg="$C_EMP_R"; fi
             if [ -z "$_VAL_TARGET" ]; then d_act="$C_EMP_R"; fi
        elif [ "$_VAL_TYPE" == "NB" ]; then
             # NB 需要 PKG 或 URI
             if [ -z "$_VAL_PKG" ] && [ -z "$_VAL_URI" ] && [ -z "$_VAL_ENGINE" ]; then
                 d_pkg="$C_EMP_R"
                 d_uri="$C_EMP_R"
             fi
        fi
        if [ -z "$_VAL_HUDNAME" ]; then d_hud="$C_UNK"; fi
        if [ -z "$_VAL_UINAME" ]; then d_ui="$C_UNK"; fi
    fi

    local command_str="$_VAL_COM $d_sub"
    local final_uri="$d_uri"
    if [ -n "$_VAL_ENGINE" ]; then final_uri="$d_eng"; fi

    # 4. 生成報告 (Bash Printf)
    local report=""
    
    # Header Section
    report+="${C_TAG}[${cat_name_display}]${C_RST}${S}ROOM_INFO\n"
    report+="${C_TAG}[${cat_no_display}:${com_no_display}]${C_TAG}[TYPE: ${d_type}]${C_RST}${S}ROOM_INFO\n"
    
    # Common Section
    report+=" ${C_LBL}Command:${C_VAL} ${command_str} ${S}ROOM_CMD\n"
    report+=" ${C_LBL}Detail :${C_VAL} ${d_hud} ${S}ROOM_HUD\n"
    report+=" ${C_LBL}UI     :${C_VAL} ${d_ui} ${S}ROOM_UI\n"
    report+="${C_LBL}${SEP}${C_RST}\n"

    # Type Specific Section
    if [ "$_VAL_TYPE" == "NB" ]; then
        report+=" ${C_LBL}Intent :${C_VAL} ${_VAL_IHEAD} ${_VAL_IBODY}${S}ROOM_INTENT\n"
        report+=" ${C_LBL}URI    :${C_VAL} ${final_uri} ${S}ROOM_URI\n"
        report+=" ${C_LBL}Cate   :${C_VAL} ${_VAL_CATE:-[Empty]} ${S}ROOM_CATE\n"
        report+=" ${C_LBL}Mime   :${C_VAL} ${_VAL_MIME:-[Empty]} ${S}ROOM_MIME\n"
        report+=" ${C_LBL}Extra  :${C_VAL} ${_VAL_EX:-[Empty]} ${_VAL_EXTRA} ${S}ROOM_EXTRA\n"
        report+=" ${C_LBL}Package:${C_VAL} ${d_pkg} ${S}ROOM_PKG\n"
        report+=" ${C_LBL}Target :${C_VAL} ${d_act} ${S}ROOM_ACT\n"
    else
        # Default / NA / SYS
        report+=" ${C_LBL}Package:${C_VAL} ${d_pkg} ${S}ROOM_PKG\n"
        report+=" ${C_LBL}Target :${C_VAL} ${d_act} ${S}ROOM_ACT\n"
        report+=" ${C_LBL}Flag   :${C_VAL} ${_VAL_FLAG:-[Empty]} ${S}ROOM_FLAG\n"
    fi

    # Footer Actions
    if [[ "$view_mode" == "NEW" || "$view_mode" == "EDIT" ]]; then
        report+="${C_LBL}${SEP}${C_RST}\n"
        report+="\033[1;36m[Lookup] 'apklist'\033[0m${S}ROOM_LOOKUP\n"
        report+="\033[1;32m[Confirm]\033[0m${S}ROOM_CONFIRM\n"
    fi

    # 5. 輸出給 FZF
    # FZF 設定保持你原本的邏輯
    local header_text="DETAIL CONTROL"
    local border_color="208"
    local prompt_color="208"

    case "$view_mode" in
        "NEW") header_text="CONFIRM CREATION"; border_color="46"; prompt_color="46" ;;
        "EDIT") header_text="MODIFY PARAMETER"; border_color="46"; prompt_color="46" ;;
        "DEL") header_text="DELETE CATEGORY"; border_color="196"; prompt_color="196" ;;
    esac

    local line_count=$(echo -e "$report" | wc -l)
    local dynamic_height=$(( line_count + 4 ))

    echo -e "$report" | fzf --ansi \
        --delimiter="\t" \
        --with-nth=1 \
        --height="$dynamic_height" \
        --layout=reverse \
        --border-label=" :: $header_text :: " \
        --border=bottom \
        --header=" :: Enter to Select, Esc to Return ::" \
        --info=hidden \
        --prompt=" :: Details › " \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:$prompt_color,pointer:red,marker:208,border:$border_color,header:240 \
        --bind="resize:clear-screen"
}

# 類別編輯子選單 - Category Edit Submenu
function _factory_fzf_catedit_submenu() {
    local cat_id="$1"
    local cat_name="${2:-Unknown}"
    local view_mode="${3:-EDIT}"
    
    # 定義色票
    local C_TAG="\033[1;33m"
    local C_RST="\033[0m"
    
    # 格式化顯示
    local fmt_id=$(printf "%03d" "$cat_id" 2>/dev/null || echo "$cat_id")
    local display_label="${C_TAG}[${fmt_id}]${C_RST} ${cat_name}"

    # 依模式切換選單
    local opt_title="Edit Name ${display_label}"
    local opt_cmds="Edit Command in ${display_label}"

    if [ "$view_mode" == "DEL" ]; then
        opt_title="Delete Category ${display_label}"
        opt_cmds="Delete Command in ${display_label}"
    fi
    
    local menu_content="${opt_title}\n${opt_cmds}"

    # 模式定義
    local header_text="MODIFY PARAMETER"
    local prompt_color="208"
    local border_color="208"
    
    case "$view_mode" in
        "NEW")
            # 綠色
            header_text="CONFIRM CREATION"
            border_color="46"  
            prompt_color="46"
            ;;
        "DEL")
            # 紅色
            header_text="DELETE CATEGORY"
            border_color="196" 
            prompt_color="196"
            ;;
        "EDIT"|*)
            # 橘色
            header_text="MODIFY PARAMETER"
            border_color="46"
            prompt_color="46"
            ;;
    esac
    
    # 動態計算高度
    local line_count=$(echo -e "$menu_content" | wc -l)
    local dynamic_height=$(( line_count + 4 ))
    
    local selected=$(echo -e "$menu_content" | fzf --ansi \
        --height="$dynamic_height" \
        --layout=reverse \
        --border=bottom \
        --border-label=" :: $header_text :: " \
        --header=" :: Enter to return, Esc to exit :: " \
        --prompt=" Action › " \
        --pointer="››" \
        --info=hidden \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:$prompt_color,pointer:red,marker:208,border:$border_color,header:240 \
        --bind="resize:clear-screen"
    )
    
    echo "$selected"
}

# 新增類型選擇器 - Add Type Selector
function _factory_fzf_add_type_menu() {
    local options="Command NA\nCommand NB"
    # 若要開啟 SYS/SSL，解除下方註解
    # options="Command NA\nCommand NB\nCommand SYS #\nCommand SSL"

    local selected=$(printf "%b" "$options" | fzf --ansi \
        --height=8 \
        --layout=reverse \
        --border-label=" :: CONFIRM CREATION :: " \
        --border=bottom \
        --header=" :: Enter to Choose, Esc to exit :: " \
        --prompt=" Create › " \
        --pointer="››" \
        --info=hidden \
        --color=fg:white,bg:-1,hl:240,fg+:white,bg+:235,hl+:240 \
        --color=info:240,prompt:46,pointer:red,marker:208,border:46,header:240 \
        --bind="resize:clear-screen"
    )

    echo "$selected"
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