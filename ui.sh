# ui.sh - Mux-OS 視覺顯示模組

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

# 等級進度條繪製 (Level Progress Bar Rendering)
function _draw_level_bar() {
    local lvl="${MUX_LEVEL:-1}"
    local xp="${MUX_XP:-0}"
    local next="${MUX_NEXT_XP:-2000}"
    local id="${MUX_ID:-Unknown}"
    
    # 1. 定義顏色與稱號
    local c_frame="\033[1;37m" # 白框
    local c_fill="\033[1;32m"  # 預設綠
    local c_empty="\033[1;30m" # 深灰底
    local c_xp="\033[1;30m"    # 數值灰
    local title="Init"
    local c_status="\033[1;32m"

    # 特殊狀態檢查 (Buffs)
    local buff_tag=""
    if command -v _check_active_buffs &> /dev/null; then
        _check_active_buffs
        buff_tag="$MUX_BUFF_TAG"
    fi

    case "$lvl" in
        1|2|3)      title="Novice";   c_status="\033[1;32m"; c_fill="\033[1;32m" ;; # Green
        4|5|6|7)    title="Operator"; c_status="\033[1;36m"; c_fill="\033[1;36m" ;; # Cyan
        8|9|10|11)  title="Vanguard"; c_status="\033[1;35m"; c_fill="\033[1;35m" ;; # Purple
        12|13|14|15)title="Elite";    c_status="\033[1;31m"; c_fill="\033[1;31m" ;; # Red
        *)          
            # L16+ Architect (Max Level Logic)
            title="Architect"
            c_status="\033[1;37m"; c_fill="\033[1;37m" # White
            lvl="16" # 鎖定顯示
            ;;
    esac

    # 2. 數學計算 (核心修正)
    local percent=0
    local bar_len=25
    local xp_display="${xp}/${next} XP"

    if [ "$lvl" -ge 16 ]; then
        # [滿等狀態]
        percent=100
        xp_display="MAXIMUM CAP"
        buff_tag=""
    else
        # [一般狀態]
        # 反推上一級門檻：Prev = (Next - 2000) / 1.5
        local prev=$(awk "BEGIN {print int(($next - 2000) / 1.5)}")
        
        # 區間總量 (Range)
        local range=$(( next - prev ))
        if [ "$range" -le 0 ]; then range=1; fi # 防除以零

        # 當前區間進度 (Current Progress)
        local current_prog=$(( xp - prev ))
        if [ "$current_prog" -lt 0 ]; then current_prog=0; fi # 保護機制

        # 計算百分比
        percent=$(( (current_prog * 100) / range ))
        if [ "$percent" -gt 100 ]; then percent=100; fi
    fi

    # 3. 繪製圖形
    local filled_len=$(( (percent * bar_len) / 100 ))
    local empty_len=$(( bar_len - filled_len ))

    local full_space=$(printf "%${bar_len}s")
    local bar_filled="${full_space:0:filled_len}"
    local bar_empty="${full_space:0:empty_len}"
    
    # 替換圖塊
    bar_filled="${bar_filled// /█}"
    bar_empty="${bar_empty// /░}"
    
    # 4. 輸出渲染
    echo -e " ${c_frame}║${c_fill}${bar_filled}${c_empty}${bar_empty}${c_frame}║${C_RESET}${buff_tag}"
    echo -e " ${c_frame}╚ ${c_xp}${xp_display}${C_RESET}"
    echo -e " ${c_status}[L${lvl}][${id}]${c_empty}-[${title}]${C_RESET}"
}

# 渲染核心 (Render Core)
function _render_badge() {
    local abbr="$1"
    local name="$2"
    local current="${3:-0}"
    local s1=$4; local s2=$5; local s3=$6; local s4=$7; local s5=$8
    local desc="$9"
        
    local stage="S0"
    local next_target="$s1"
    local C_GRAY="${C_BLACK}"    # 未解鎖 (Locked)
    local icon="🔒"

    if [ "$current" -ge "$s5" ]; then
        stage="S5"; next_target="MAX"; color="${C_PURPLE}"; icon="⚫" # 黑牌 (Onyx)
    elif [ "$current" -ge "$s4" ]; then
        stage="S4"; next_target="$s5"; color="${C_CYAN}"; icon="⚪"   # 白金 (Platinum)
    elif [ "$current" -ge "$s3" ]; then
        stage="S3"; next_target="$s4"; color="${C_YELLOW}"; icon="🟡" # 金牌 (Gold)
    elif [ "$current" -ge "$s2" ]; then
        stage="S2"; next_target="$s3"; color="${C_WHITE}"; icon="⚪"   # 銀牌 (Silver)
    elif [ "$current" -ge "$s1" ]; then
        stage="S1"; next_target="$s2"; color="${C_ORANGE}"; icon="🟤" # 銅牌 (Bronze)
    fi
        
    # 格式化輸出: [Fb:S2] Fabricator [35/100]
    # 使用 printf 確保對齊
    printf " ${color}[%s:%s]${C_RESET} %-12s ${color}[%s/%s]${C_RESET}\n" "$abbr" "$stage" "$name" "$current" "$next_target"
    echo -e "    ${C_GRAY}›› ${desc}${C_RESET}"
    echo ""
}

# 顯示勳章牆 (Medal Wall)
function _show_badges() {
    # 確保資料是最新的
    if [ -f "$HOME/mux-os/identity.sh" ]; then source "$HOME/mux-os/identity.sh"; fi
    if [ -f "$HOME/mux-os/.mux_identity" ]; then source "$HOME/mux-os/.mux_identity"; fi

    echo -e "${C_CYAN} :: Mux-OS Hall of Fame ::${C_RESET}"
    echo ""

    # === 常規獎牌 (Standard Medals) ===
    
    # [Hk] Hacker (Exec) - The Operator
    _render_badge "Hk" "Hacker" "$HEAP_ALLOCATION_IDX" \
        60 500 2500 10000 50000 \
        "Neural command execution cycles."

    # [Fb] Fabricator (Create) - The Maker (Rename from Architect)
    _render_badge "Fb" "Fabricator" "$IO_WRITE_CYCLES" \
        5 30 100 300 1000 \
        "Infrastructure node construction."

    # [En] Engineer (Edit) - The Tuner
    _render_badge "En" "Engineer" "$KERNEL_PANIC_OFFSET" \
        30 100 500 1500 3000 \
        "System parameter optimization."

    # [Cn] Connector (Deploy) - The Link
    _render_badge "Cn" "Connector" "$UPLINK_LATENCY_MS" \
        5 30 100 300 600 \
        "Cloud uplink synchronization events."

    # [Pu] Purifier (Delete) - The Cleaner
    _render_badge "Pu" "Purifier" "$ENTROPY_DISCHARGE" \
        3 10 50 150 500 \
        "Entropy reduction (node deletion)."

    # [Ex] Explorer (Neural) - The Seeker
    _render_badge "Ex" "Explorer" "$NEURAL_SYNAPSE_FIRING" \
        30 100 500 1000 3000 \
        "External neural network queries."

    # === 特殊獎牌 (Hidden / Special) ===
    echo -e "${C_RED} :: Special Operations ::${C_RESET}"
    echo ""

    local has_special=false

    # 1. Singularity (降維打擊)
    # 檢查 MUX_BADGES 字串中是否包含 "2D_STRIKE"
    if [[ "$MUX_BADGES" == *"2D_STRIKE"* ]]; then
        echo -e " ${C_RED}[Si:S5]${C_RESET} Singularity  ${C_RED}[MAX]${C_RESET}"
        echo -e "    ${C_GRAY}›› Survivor of Dimensional Collapse.${C_RESET}"
        echo ""
        has_special=true
    fi

    # 2. Time Lord (時間領主 - 隱藏成就範例)
    # 假設我們之後加一個 "TIME_LORD" 標籤
    if [[ "$MUX_BADGES" == *"TIME_LORD"* ]]; then
        echo -e " ${C_YELLOW}[Ti:S5]${C_RESET} Time Lord    ${C_YELLOW}[MAX]${C_RESET}"
        echo -e "    ${C_GRAY}›› Master of the temporal flow.${C_RESET}"
        echo ""
        has_special=true
    fi

    # 如果沒有任何特殊獎牌，顯示神祕訊息
    if [ "$has_special" = false ]; then
        echo -e " ${C_GRAY}[??:??] ???          [LOCKED]${C_RESET}"
        echo -e "    ${C_GRAY}›› Classified information.${C_RESET}"
        echo ""
    fi
}

# 繪製 Mux-OS Logo標誌
function _draw_logo() {
    local mode="${1:-core}"
    local color_primary=""
    local color_sub="$C_BLACK"
    local label=""
    local cols=$(tput cols 2>/dev/null || echo 80)

    # 1. 呼叫等級進度條
    _draw_level_bar

    # 2. 設定 Logo 樣式
    case "$mode" in
        "gray")
            color_primary="$C_BLACK"
            label=":: SYSTEM LOCKED ::"
            if [ "$cols" -ge 52 ]; then label+=" AUTHENTICATION REQUIRED ::"; fi
            ;;
        "factory")
            color_primary="$THEME_MAIN"
            label=":: Mux-OS v$MUX_VERSION Factory ::"
            if [ "$cols" -ge 52 ]; then label+=" Neural Forge ::"; fi
            ;;
        *)
            color_primary="$THEME_MAIN"
            label=":: Mux-OS v$MUX_VERSION Core ::"
            if [ "$cols" -ge 52 ]; then label+=" Gate System ::"; fi
            ;;
    esac

    # 3. 繪製 Logo
    echo -e "${color_primary}"
    echo "  __  __                  ___  ____  "
    echo " |  \/  |_   ___  __     / _ \/ ___| "
    echo " | |\/| | | | \ \/ /____| | | \___ \ "
    echo " | |  | | |_| |>  <_____| |_| |___) |"
    echo " |_|  |_|\__,_/_/\_\     \___/|____/ "
    echo -e "${C_RESET}"
    echo -e " ${color_sub}${label}${C_RESET}"
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
            "Mounting app.csv.temp (Write-Mode)..."
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
    
    local border_color="$THEME_MAIN" 
    
    local text_color="$THEME_SUB"
    local value_color="$C_RESET"

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
    
    local header_color="$THEME_DESC"
    local logo_mode="gray"

    if [ "$MUX_STATUS" == "LOGIN" ]; then
        header_color="$THEME_MAIN"
        logo_mode="core"
    fi

    _draw_logo "$logo_mode"

    echo -e " ${header_color}:: SYSTEM MANIFEST ::${C_RESET}"
    echo ""
    echo -e "  ${THEME_DESC}PROJECT    :${C_RESET} ${THEME_SUB}Mux-OS (Terminal Environment)${C_RESET}"
    echo -e "  ${THEME_DESC}VERSION    :${C_RESET} ${THEME_OK}v$MUX_VERSION${C_RESET}"
    echo -e "  ${THEME_DESC}CODENAME   :${C_RESET} ${header_color}Neural Link${C_RESET}"
    echo -e "  ${THEME_DESC}ARCHITECT  :${C_RESET} ${THEME_SUB}Commander${C_RESET}" 
    echo -e "  ${THEME_DESC}BASE SYS   :${C_RESET} ${THEME_SUB}Android $(getprop ro.build.version.release) / Linux $(uname -r | cut -d- -f1)${C_RESET}"
    echo ""
    echo -e " ${header_color}:: PHILOSOPHY ::${C_RESET}"
    echo -e "  ${THEME_DESC}\"Logic in mind, Hardware in hand.\"${C_RESET}"
    echo -e "  ${THEME_DESC}Designed for efficiency, built for control.${C_RESET}"
    echo ""
    echo -e " ${header_color}:: SOURCE CONTROL ::${C_RESET}"
    echo -e "  ${THEME_DESC}Repo       :${C_RESET} ${THEME_SUB}$MUX_REPO${C_RESET}"
    echo ""
    
    echo -ne " ${THEME_OK}:: Open GitHub Repository? [Y/n]: ${C_RESET}"
    read choice
    
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        if command -v wb &> /dev/null; then
            wb "$MUX_REPO"
        else
            am start -a android.intent.action.VIEW -d "$MUX_REPO" >/dev/null 2>&1
        fi
    else
        echo ""
        if [ "$MUX_STATUS" == "LOGIN" ]; then
            _voice_dispatch "system"
        else
            _commander_voice "system"
        fi
    fi
}

# 動態Help Core選單檢測 - Dynamic Help Core Detection
function _mux_dynamic_help_core() {
    local C_CMD=""
    
    if [ "$MUX_STATUS" == "LOGIN" ]; then
        C_CMD="\033[1;36m" 
    else
        C_CMD="\033[1;30m" 
    fi

    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "Unknown")

    echo -e "\033[1;35m :: Mux-OS Core v$MUX_VERSION Protocols :: @$current_branch :: ${C_RESET}"
    
    awk -v cmd_color="$C_CMD" '
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
                
                printf "    %s%-10s\033[0m%s\n", cmd_color, cmd_name, desc;
            }
        }
    }
    ' "$CORE_MOD"
}

# 動態Help Factory選單檢測 - Dynamic Help Factory Detection
function _mux_dynamic_help_factory() {
echo -e "\033[1;35m :: Mux-OS Factory Protocols ::${C_RESET}"
    
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

    if [ "$MUX_MODE" == "FAC" ]; then
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

        read -e -p "$(echo -e "\033[1;33m :: $cmd_base \033[1;30m(Params?): \033[0m")" user_params < /dev/tty
        
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

# 顯示兵工廠狀態 - Display Factory Status
function _factory_show_status() {
    local temp_file="$MUX_ROOT/app.csv.temp"
    local bak_dir="${MUX_BAK:-$MUX_ROOT/bak}"

    echo -e "${THEME_MAIN} :: Neural Forge Status Report ::${C_RESET}"
    echo -e "${THEME_DESC}    --------------------------${C_RESET}"

    if [ -f "$temp_file" ]; then
        local line_count=$(wc -l < "$temp_file")
        local node_count=$(( line_count - 1 ))
        [ "$node_count" -lt 0 ] && node_count=0
        
        local size=$(du -h "$temp_file" | cut -f1)
        
        echo -e "${THEME_DESC}    Target  : ${THEME_WARN}app.csv.temp${C_RESET}"
        echo -e "${THEME_DESC}    Size    : $size"
        echo -e "${THEME_DESC}    Nodes   : ${THEME_SUB}$node_count active commands${C_RESET}"
    else
        echo -e "${THEME_ERR}    Target  : CRITICAL ERROR (Sandbox Missing)${C_RESET}"
    fi

    echo -e ""
    echo -e "${THEME_SUB}    [Temporal Snapshots (Time Stone)]${C_RESET}"
    
    local found_any=0
    
    local session_bak=$(ls "$bak_dir"/app.csv.*.bak 2>/dev/null | head -n 1)
    if [ -n "$session_bak" ]; then
        local fname=$(basename "$session_bak")
        local raw_ts=$(echo "$fname" | awk -F'.' '{print $3}')
        local fmt_ts="${raw_ts:0:4}-${raw_ts:4:2}-${raw_ts:6:2} ${raw_ts:8:2}:${raw_ts:10:2}:${raw_ts:12:2}"
        local f_size=$(du -h "$session_bak" | cut -f1)

        echo -e "    ${F_CYAN}[Session Origin]${C_RESET}"
        echo -e "    ›› Time : $fmt_ts"
        echo -e "    ›› File : $fname ($f_size)"
        found_any=1
    fi

    local atb_files=$(ls -t "$bak_dir"/app.csv.*.atb 2>/dev/null | head -n 3)
    
    if [ -n "$atb_files" ]; then
        [ "$found_any" -eq 1 ] && echo -e "${THEME_DESC}    --------------------------${C_RESET}"
        
        SAVEIFS=$IFS
        IFS=$'\n'
        for f_path in $atb_files; do
            local fname=$(basename "$f_path")
            local raw_ts=$(echo "$fname" | awk -F'.' '{print $3}')
            local fmt_ts="${raw_ts:0:4}-${raw_ts:4:2}-${raw_ts:6:2} ${raw_ts:8:2}:${raw_ts:10:2}:${raw_ts:12:2}"
            local f_size=$(du -h "$f_path" | cut -f1)

            echo -e "    ${THEME_MAIN}[Auto Save]${C_RESET}"
            echo -e "    ›› Time : $fmt_ts"
            echo -e "    ›› Size : $f_size"
            found_any=1
        done
        IFS=$SAVEIFS
    fi

    if [ "$found_any" -eq 0 ]; then
        echo -e "${THEME_DESC} :: No temporal snapshots found in $bak_dir.${C_RESET}"
    fi

    echo -e "${THEME_DESC}    --------------------------${C_RESET}"
    
    if command -v _bot_say &> /dev/null; then
        _bot_say "factory" "Status report generated."
    fi
}

# 顯示兵工廠資訊 - Display Factory Info Manifest
function _factory_show_info() {
    clear
    _draw_logo "factory"
    
    echo -e " ${THEME_MAIN}:: INDUSTRIAL MANIFEST ::${C_RESET}"
    echo ""
    echo -e "  ${THEME_DESC}PROTOCOL   :${C_RESET} ${THEME_SUB}Factory Mode${C_RESET}"
    echo -e "  ${THEME_DESC}ACCESS     :${C_RESET} ${THEME_MAIN}COMMANDER${C_RESET}"
    echo -e "  ${THEME_DESC}PURPOSE    :${C_RESET} ${THEME_SUB}Neural Link Construction & Modification${C_RESET}"
    echo -e "  ${THEME_DESC}TARGET     :${C_RESET} ${THEME_WARN}app.csv.temp${C_RESET}"
    echo ""
    echo -e " ${THEME_MAIN}:: WARNING ::${C_RESET}"
    echo -e "  ${THEME_DESC}\"With great power comes great possibility of breaking things.\"${C_RESET}"
    echo ""
    
    echo -ne " ${C_GREEN}:: Ready to returning to forge? [Y/n]: ${C_RESET}"
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
        "RELOCATE")
            border_color="46" 
            prompt_color="46"
            header_msg="RELOCATE NODE"
            prompt_msg="Move to"
            ;;
        *)
            border_color="208"
            ;;
    esac

    # 1. 生成標準列表 (Sorted)
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

    # 2. 格式化列表 (Formatted)
    local formatted_list=$(echo "$cat_list" | awk -F'|' '{printf " \033[1;33m%03d  \033[1;37m%s\n", $1, $2}')

    # 3. 根據模式新增選項
    if [ "$mode" == "RELOCATE" ]; then
        formatted_list="${formatted_list}\n \033[1;32m[+]  \033[1;37mCreate New Category"
    fi

    # 4. FZF 渲染
    local selected=$(echo -e "$formatted_list" | fzf --ansi \
        --height=12 \
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
        if echo "$selected" | grep -q "Create New Category"; then
            echo "NEW_SIGNAL"
        else
            echo "$selected" | sed "s/$(printf '\033')\[[0-9;]*m//g" | awk '{print $1}'
        fi
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

    if [[ "$view_mode" == "NEW" || "$view_mode" == "EDIT" ]]; then
        # NEW & EDIT Mode Section
        if [ "$_VAL_TYPE" == "NB" ]; then
            report+=" ${C_LBL}Intent :${C_VAL} ${_VAL_IHEAD}${_VAL_IBODY}${S}ROOM_INTENT\n"
            report+=" ${C_LBL}URI    :${C_VAL} ${final_uri} ${S}ROOM_URI\n"
            report+=" ${C_LBL}Cate   :${C_VAL} ${_VAL_CATE:-[Empty]} ${S}ROOM_CATE\n"
            report+=" ${C_LBL}Mime   :${C_VAL} ${_VAL_MIME:-[Empty]} ${S}ROOM_MIME\n"
            report+=" ${C_LBL}Extra  :${C_VAL} ${_VAL_EX:-[Empty]} ${_VAL_EXTRA} ${S}ROOM_EXTRA\n"
            report+=" ${C_LBL}Package:${C_VAL} ${d_pkg} ${S}ROOM_PKG\n"
            report+=" ${C_LBL}Target :${C_VAL} ${d_act} ${S}ROOM_ACT\n"
            report+="${C_LBL}${SEP}${C_RST}\n"
            report+="\033[1;36m[Lookup] 'apklist'\033[0m ${S}ROOM_LOOKUP\n"
            report+="\033[1;32m[Confirm]\033[0m ${S}ROOM_CONFIRM"
        else
        # Default / NA / SYS
            report+=" ${C_LBL}Package:${C_VAL} ${d_pkg} ${S}ROOM_PKG\n"
            report+=" ${C_LBL}Target :${C_VAL} ${d_act} ${S}ROOM_ACT\n"
            report+=" ${C_LBL}Flag   :${C_VAL} ${_VAL_FLAG:-[Empty]} ${S}ROOM_FLAG\n"
            report+="${C_LBL}${SEP}${C_RST}\n"
            report+="\033[1;36m[Lookup] 'apklist'\033[0m ${S}ROOM_LOOKUP\n"
            report+="\033[1;32m[Confirm]\033[0m ${S}ROOM_CONFIRM"
        fi
    else
        # VIEW Mode Section
        if [ "$_VAL_TYPE" == "NB" ]; then
            report+=" ${C_LBL}Intent :${C_VAL} ${_VAL_IHEAD}${_VAL_IBODY}${S}ROOM_INTENT\n"
            report+=" ${C_LBL}URI    :${C_VAL} ${final_uri} ${S}ROOM_URI\n"
            report+=" ${C_LBL}Cate   :${C_VAL} ${_VAL_CATE:-[Empty]} ${S}ROOM_CATE\n"
            report+=" ${C_LBL}Mime   :${C_VAL} ${_VAL_MIME:-[Empty]} ${S}ROOM_MIME\n"
            report+=" ${C_LBL}Extra  :${C_VAL} ${_VAL_EX:-[Empty]} ${_VAL_EXTRA} ${S}ROOM_EXTRA\n"
            report+=" ${C_LBL}Package:${C_VAL} ${d_pkg} ${S}ROOM_PKG\n"
            report+=" ${C_LBL}Target :${C_VAL} ${d_act} ${S}ROOM_ACT"
        else
        # Default / NA / SYS
            report+=" ${C_LBL}Package:${C_VAL} ${d_pkg} ${S}ROOM_PKG\n"
            report+=" ${C_LBL}Target :${C_VAL} ${d_act} ${S}ROOM_ACT\n"
            report+=" ${C_LBL}Flag   :${C_VAL} ${_VAL_FLAG:-[Empty]} ${S}ROOM_FLAG"
        fi
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

# 星門 - UI Mask / Fake Gate
function _ui_fake_gate() {
    local target_system="${1:-core}"
    local theme_color=""
    local theme_text=""
    
    case "$target_system" in
        "factory")
            theme_color="$C_ORANGE"
            theme_text="NEURAL FORGE"
            ;;
        "default")
            theme_color="$C_WHITE"
            theme_text="TO COMMANDER"
            ;;
        *)
            theme_color="$C_CYAN"
            theme_text="SYSTEM CORE"
            ;;
    esac

    local C_TXT="\033[1;30m"
    local C_RESET="\033[0m"

    # 安全網
    tput civis
    stty -echo
    trap 'tput cnorm; stty echo; echo -e "${C_RESET}";' EXIT INT TERM

    clear
    local rows=$(tput lines)
    local cols=$(tput cols)
    
    # 計算進度條長度
    local bar_len=$(( cols * 45 / 100 ))
    if [ "$bar_len" -lt 15 ]; then bar_len=15; fi

    local center_row=$(( rows / 2 ))
    
    # 進度條起始位置
    local bar_start_col=$(( (cols - bar_len - 2) / 2 ))
    
    # 標題置中計算
    local title_start_col=$(( (cols - 25) / 2 ))

    # 繪製標題
    tput cup $((center_row - 2)) $title_start_col
    echo -e "${C_TXT}:: GATE ${theme_color}${theme_text} ${C_TXT}::${C_RESET}"

    local current_pct=0
    local trap_triggered="false"
    
    local should_trap="false"
    if [ $((RANDOM % 100)) -ge 98 ]; then
        should_trap="true"
    fi

    while true; do
        # 繪圖：進度條
        local filled_len=$(( (current_pct * bar_len) / 100 ))
        local remain=$(( bar_len - filled_len ))

        tput cup $center_row $bar_start_col
        echo -ne "${C_TXT}[${C_RESET}"
        if [ "$filled_len" -gt 0 ]; then printf "${theme_color}%.0s#${C_RESET}" $(seq 1 "$filled_len"); fi
        if [ "$remain" -gt 0 ]; then printf "%.0s " $(seq 1 "$remain"); fi
        echo -ne "${C_TXT}]${C_RESET}"

        local hex_val=$(printf "0x%04X" $((RANDOM%65535)))
        
        tput cup $((center_row + 2)) $bar_start_col
        printf "${C_TXT}:: ${theme_color}%3s%%${C_TXT} :: MEM: ${hex_val}${C_RESET}\033[K" "$current_pct"

        if [ "$current_pct" -ge 100 ]; then break; fi

        # 陷阱卡邏輯 (卡頓特效)
        if [ "$should_trap" == "true" ] && [ "$current_pct" -ge 98 ] && [ "$trap_triggered" == "false" ]; then
            current_pct=99
            trap_triggered="true"
            sleep 2
            continue
        fi

        local step=$(( (RANDOM % 4) + 1 ))
        current_pct=$(( current_pct + step ))
        
        if [ "$should_trap" == "true" ] && [ "$current_pct" -gt 98 ] && [ "$trap_triggered" == "false" ]; then
            current_pct=98
        fi
        
        if [ "$current_pct" -gt 100 ]; then current_pct=100; fi

        sleep 0.015
    done

    # 清理
    trap - EXIT INT TERM
    tput cnorm
    stty echo
    clear
}