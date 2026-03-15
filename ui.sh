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

# 常規獎牌渲染 (Standard Medal Render)
function _render_badge() {
    local abbr="$1"
    local name="$2"
    local current="${3:-0}"
    local s1=$4; local s2=$5; local s3=$6; local s4=$7; local s5=$8
    local desc="$9"
        
    local stage="0"
    local next_target="$s1"
    
    # 預設: 0 (C_BLACK / Dark Gray)
    local color="${C_BLACK}"

    if [ "$current" -ge "$s5" ]; then
        stage="5"; next_target="C"; color="${C_PURPLE}" # Onyx
    elif [ "$current" -ge "$s4" ]; then
        stage="4"; next_target="$s5"; color="${C_CYAN}"   # Platinum
    elif [ "$current" -ge "$s3" ]; then
        stage="3"; next_target="$s4"; color="${C_YELLOW}" # Gold
    elif [ "$current" -ge "$s2" ]; then
        stage="2"; next_target="$s3"; color="${C_WHITE}"  # Silver
    elif [ "$current" -ge "$s1" ]; then
        stage="1"; next_target="$s2"; color="${C_ORANGE}" # Bronze
    fi

    if [ "$RENDER_MODE" == "CALC" ]; then
        # 統計各階級數量
        if [ "$stage" -ge 1 ]; then ((MEDAL_STATS_S1++)); fi
        if [ "$stage" -ge 2 ]; then ((MEDAL_STATS_S2++)); fi
        if [ "$stage" -ge 3 ]; then ((MEDAL_STATS_S3++)); fi
        if [ "$stage" -ge 4 ]; then ((MEDAL_STATS_S4++)); fi
        if [ "$stage" -ge 5 ]; then ((MEDAL_STATS_S5++)); fi
        return
    fi
        
    echo -e " ${color}[${abbr}]${C_BLACK}-${C_WHITE}${name}${C_RESET}"
    echo -e " ${color}[Stage ${stage}]${C_BLACK}[${current}/${next_target}]${C_RESET}"
    echo -e "  ${C_BLACK}› ${desc}${C_RESET}"
    echo ""
}

# 特殊獎牌渲染 (Special Medal Render - with Obfuscation)
function _render_special() {
    local tag="$1"
    local abbr="$2"
    local name="$3"
    local desc="$4"
    
    # 計數器模式開關
    local cur_val="$5"
    local max_val="$6"
    
    local is_unlocked=0
    local count_display=""
    
    if [[ "$MUX_BADGES" == *"$tag"* ]]; then
        is_unlocked=1
    fi
    
    # 邏輯判定
    if [ -n "$max_val" ]; then
        local safe_cur="${cur_val:-0}"
        
        if [ "$safe_cur" -ge "$max_val" ]; then
            is_unlocked=1
        fi
        count_display="[${safe_cur}/${max_val}]"
    else
        if [ "$is_unlocked" -eq 1 ]; then
            count_display="[1/1]"
        else
            count_display="[0/1]"
        fi
    fi

    # 渲染
    if [[ "$tag" =~ ^(PB|LIMIT_BREAK)$ ]] && [ "$is_unlocked" -eq 1 ]; then
        echo -e " ${C_TAVIOLET}[${abbr}]${C_RESET}${C_BLACK}-\033[0;35m${name}${C_RESET}"
        echo -e " ${C_TAVIOLET}[Curse]${C_RESET}${C_BLACK}[∞]${C_RESET}"
        echo -e "  ${C_BLACK}› ${desc}${C_RESET}"
    elif [ "$is_unlocked" -eq 1 ]; then
        echo -e " ${C_RED}[${abbr}]${C_BLACK}-${C_WHITE}${name}${C_RESET}"
        echo -e " ${C_RED}[Stage C]${C_BLACK}${count_display}${C_RESET}"
        echo -e "  ${C_BLACK}› ${desc}${C_RESET}"
    else
        local locked_color="${C_BLACK}"
        echo -e " ${locked_color}[${abbr}]-${name}${C_RESET}"
        echo -e " ${locked_color}[Stage L]${count_display}${C_RESET}"
        echo -e "  ${locked_color}› ???${C_RESET}"
    fi
    echo ""
}


# 顯示勳章牆 (Medal Wall)
function _show_badges() {
    local mode="$1"

    if [ -f "$HOME/mux-os/identity.sh" ]; then source "$HOME/mux-os/identity.sh"; fi
    if [ -f "$HOME/mux-os/.mux_identity" ]; then source "$HOME/mux-os/.mux_identity"; fi

    # 初始化計算環境
    if [ "$mode" == "CALC" ]; then
        export RENDER_MODE="CALC"
        export MEDAL_STATS_S1=0
        export MEDAL_STATS_S2=0
        export MEDAL_STATS_S3=0
        export MEDAL_STATS_S4=0
        export MEDAL_STATS_S5=0
    else
        unset RENDER_MODE
        echo -e "${C_PURPLE} :: Mux-OS Hall of Fame ::${C_RESET}"
        echo ""
    fi

    # 常規獎牌 (Standard)
    # [Hk] Hacker (50, 500, 2500, 10000, 50000)
    _render_badge "Hk" "Hacker" "$HEAP_ALLOCATION_IDX" 50 500 2500 10000 50000 "Neural command execution cycles."

    # [Fb] Fabricator (10, 50, 200, 500, 1000)
    _render_badge "Fb" "Fabricator" "$IO_WRITE_CYCLES" 10 50 200 500 1000 "Infrastructure node construction."

    # [En] Engineer (30, 150, 600, 2000, 5000)
    _render_badge "En" "Engineer" "$KERNEL_PANIC_OFFSET" 30 150 600 2000 5000 "System parameter optimization."

    # [Cn] Connector (10, 50, 200, 500, 1000)
    _render_badge "Cn" "Connector" "$UPLINK_LATENCY_MS" 10 50 200 500 1000 "Cloud uplink synchronization events."

    # [Pu] Purifier (5, 25, 100, 300, 666)
    _render_badge "Pu" "Purifier" "$ENTROPY_DISCHARGE" 5 25 100 300 666 "Entropy reduction (node deletion)."

    # [Ex] Explorer (30, 200, 800, 3000, 10000)
    _render_badge "Ex" "Explorer" "$NEURAL_SYNAPSE_FIRING" 30 200 800 3000 10000 "External neural network queries."

    # [Gn] Gunner (10, 50, 200, 800, 2000)
    _render_badge "Gn" "Gunner" "$TEST_LAUNCH_COUNT" 10 50 200 800 2000 "Factory launch test cycles."

    # [Nv] Navigator (5, 25, 100, 300, 1000)
    _render_badge "Nv" "Navigator" "$WARP_JUMP_COUNT" 5 25 100 300 1000 "Timeline (branch) jump events."

    # [Vt] Veteran (10, 100, 500, 2000, 5000)
    _render_badge "Vt" "Veteran" "$LOGIN_COUNT" 10 100 500 2000 5000 "System login frequency."

    # 計算模式結束處理
    if [ "$mode" == "CALC" ]; then
        unset RENDER_MODE
        return
    fi

    # 特殊獎牌 (Special)
    echo -e "${C_PURPLE} :: Special Operations ::${C_RESET}"
    echo ""

    # 1. 標籤型 - 只有 4 個參數
    _render_special "ANCIENT_ONE" "Le" "The Ancient One"    "System uptime exceeds one solar cycle."
    _render_special "LOST_TIME"   "44" "Lost in Time"       "Login detected on a phantom date."
    _render_special "OUROBOROS"   "O4" "Ouroboros"          "Tried to contain the container (Core)."
    _render_special "INFINITE_GEAR" "Ig" "Infinite Gear"    "Constructing the constructor (Factory)."
    _render_special "TEAPOT"      "Ct" "Protocol 418"       "I'm a teapot."
    _render_special "SCHIZO"      "Sh" "Schizophrenia"      "Conversations with the internal monologue."
    _render_special "PHOENIX"     "Px" "Phoenix"            "Rose from the ashes of dimensional collapse."
    _render_special "DSTRIKE"     "Ds" "Dimensional Strike" "Survivor of Dimensional Collapse."
    _render_special "PB"          "Pb" "Pandora's Box"      "Bore the curse of causality."
    _render_special "LIMIT_BREAK" "Lb" "Limit Break"       "Initialized the XUM Overclock protocol."

    # 2. 計數器型 - 傳入 6 個參數
    _render_special "FALSE_IDOL"  "Rt" "False Idol" \
        "Attempted to invoke Administrator privileges." \
        "${SUDO_ATTEMPT_COUNT:-0}" "10"

    local void_count=$(cat "$MUX_ROOT"/{app,vendor,system}.csv.temp 2>/dev/null | awk -F, '$1==999 {count++} END {print count+0}')
    _render_special "VOID_WALKER" "Vd" "Void Walker" \
        "Embraced the chaos of Category 999." \
        "${void_count:-0}" "50"

    _render_special "GHOST_SHELL" "Gt" "Ghost in the Shell" \
        "Frequent synchronization with the system core." \
        "${HELP_ACCESS_COUNT:-0}" "100"

    _render_special "MAJOR_TOM"   "Ej" "Major Tom" \
        "Ejection limit exceeded. Ground control to Major Tom." \
        "${EJECTION_COUNT:-0}" "100"
    
    _render_special "MASOCHIST"   "dM" "Masochist" \
        "Enjoying the pain of ejection. The Chief is worried about you." \
        "${FACTORY_ABUSE_COUNT:-0}" "5"
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
        "xum")
            color_primary="$C_TAVIOLET"
            label=":: Mux-OS v$MUX_VERSION Core ::"
            if [ "$cols" -ge 52 ]; then label+=" S¥ST3M ØV3RCL0CK ::"; fi
            ;;
        "awake")
            color_primary="$C_TAVIOLET"
            label=":: SYSTEM CORE INSIDE ::"
            if [ "$cols" -ge 52 ]; then label+=" ANSWER REQUIRED ::"; fi
            ;;
        "tct")
            color_primary="$C_PINKMEOW"
            label=":: Mux-OS v$MUX_VERSION Command Tower ::"
            if [ "$cols" -ge 52 ]; then label+=" Weapons Cold ::"; fi
            local rand_logo=$(( RANDOM % 100 ))
            if [ "$rand_logo" -lt 15 ]; then
                tct_logo="cat"
                export __MUX_CAT_OS=1
                label=":: Cat-OS v$MUX_VERSION Meow Tower ::"
                if [ "$cols" -ge 52 ]; then label+=" (ฅ^•ﻌ•^ฅ) ::"; fi
            else
                unset __MUX_CAT_OS
            fi
            ;;
        *)
            color_primary="$THEME_MAIN"
            label=":: Mux-OS v$MUX_VERSION Core ::"
            if [ "$cols" -ge 52 ]; then label+=" Gate System ::"; fi
            ;;
    esac

    # 3. 繪製 Logo
    echo -e "${color_primary}"
    if [ "$mode" == "xum" ]; then
        echo "  ____   ___                  __  __ "
        echo " / ___| / _ \     __  ___   _|  \/  |"
        echo " \___ \| | | |____\ \/ / | | | |\/| |"
        echo "  ___) | |_| |_____>  <| |_| | |  | |"
        echo " |____/ \___/     /_/\_\__,_/|_|  |_|"
    elif [ "$tct_logo" == "cat" ]; then
        echo "   ____        _          ___  ____  "
        echo "  / ___| __ _ | |_       / _ \/ ___| "
        echo " | |    / _  || __|____ | | | \___ \ "
        echo " | |___| (_| || |_|____|| |_| |___) |"
        echo "  \____|\__,_| \__|      \___/|____/ "
    else
        echo "  __  __                  ___  ____  "
        echo " |  \/  |_   ___  __     / _ \/ ___| "
        echo " | |\/| | | | \ \/ /____| | | \___ \ "
        echo " | |  | | |_| |>  <_____| |_| |___) |"
        echo " |_|  |_|\__,_/_/\_\     \___/|____/ "
    fi
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
    
    # 即使渲染
    function _run_step() {
        local msg="$1"
        local status="${2:-0}"
        echo -ne " $C_PROC $msg\r"; sleep $DELAY_ANIM
        if [ "$status" -eq 0 ]; then echo -e " $C_CHECK $msg                    ";
        elif [ "$status" -eq 1 ]; then echo -e " $C_FAIL $msg \033[1;31m[OFFLINE]\033[0m";
        else echo -e " $C_WARN $msg \033[1;33m[UNKNOWN]\033[0m"; fi
        sleep $DELAY_STEP
    }

    local steps=()
    if [ "$mode" == "factory" ]; then
        C_PROC="\033[1;35m⟳\033[0m"
        local active_db=$(basename "${__FAC_ACTIVE_DB:-app.csv.temp}")
        local mount_msg="Mounting $active_db ..."
        local mount_msg2="Writing-Mode Unlocked..."
        if [ "$active_db" == "vendor.csv.temp" ]; then
            mount_msg="Unlocking Manufacturer Plugins..."
            mount_msg2="Setting $active_db on board..."
        elif [ "$active_db" == "system.csv.temp" ]; then
            mount_msg="Bypassing Core Directives..."
            mount_msg2="Unlocked Database $active_db ..."
        fi
        steps=(
            "Initializing Neural Forge..."
            "Overriding Read-Only Filesystem..."
            "Disabling Safety Interlocks..."
            "$mount_msg"
            "$mount_msg2"
            "Establishing Factory Uplink..."
        )
    elif [ "$mode" == "xum" ]; then
        C_PROC="${C_TAVIOLET}⟳\033[0m"
        C_CHECK="\033[1;31m✓\033[0m"
        local brand=$(getprop ro.product.brand | tr '[:lower:]' '[:upper:]')
        steps=(
            "I|\\|itializ!ng K3rn3l B|2idg3..."
            "M0unt!ng V3nd0r Ec0sy\$t3m [${brand:-UNKNOWN}]..."
            "V3r!fy!ng T4ct!c4l L!nk (fzf)..."
            "F0rc!ng C0|23 M3m0ry Dum¶..."
            "Byp4ss!ng S4f3ty L4y3r..."
            "E\$t4bl!\$h!ng XUM Upl!nk..."
        )
    elif [ "$mode" == "tct" ] || [ "$mode" == "tower" ]; then
        C_PROC="${C_PINKMEOW}⟳\033[0m"
        C_CHECK="${C_PINKMEOW}✓\033[0m"
        
        if [ "$__MUX_CAT_OS" == "1" ]; then
            # 貓咪模式
            export __MUX_CLUMSY_STATE=0
        else
            # 小助理的冒失彩蛋
            local rand_glitch=$(( RANDOM % 100 ))
            if [ "$rand_glitch" -lt 15 ]; then
                export __MUX_CLUMSY_STATE=$(( (RANDOM % 3) + 1 ))
                
                _run_step "Initializing Command Tower..." 0
                _run_step "Bypassing Fire Control Systems..." 0
                
                echo -ne " $C_PROC Waking up Assistant AI...\r"; sleep 0.6
                echo -e " ${C_FAIL} Waking up Assistant AI... \033[1;31m[INTERRUPTED]\033[0m"
                echo ""
                
                if command -v _assistant_voice &> /dev/null; then
                    case "$__MUX_CLUMSY_STATE" in
                        1) _assistant_voice "clumsy_coffee" ;;
                        2) _assistant_voice "clumsy_panic" ;;
                        3) _assistant_voice "clumsy_drop" ;;
                    esac
                else
                    echo -e "${C_PINKMEOW} :: Ah! Wait! I messed up! (；´д｀)ゞ\033[0m"
                fi
                echo ""
                sleep 1.5
                return # 提早中斷
            fi
        fi

        # 85% 正常啓動序列
        export __MUX_CLUMSY_STATE=0
        if [ "$__MUX_CAT_OS" == "1" ]; then
            steps=(
                "Waking up the cats..."
                "Filling the food bowl..."
                "Mounting Native Physical Engine..."
                "Sharpening claws on the mainframe..."
                "All Systems Green. Meow."
            )
        else
            steps=(
                "Initializing Command Tower..."
                "Bypassing Fire Control Systems..."
                "Mounting Native Physical Engine..."
                "Waking up Assistant AI..."
                "All Systems Green. Weapons Cold."
            )
        fi
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

    # 這裡會執行正常模式
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
        local active_db_disp=$(basename "${__FAC_ACTIVE_DB:-app.csv.temp}")
        line1_k="HOST   "; line1_v="Commander"
        line2_k="TARGET "; line2_v="$active_db_disp"
        line3_k="STATUS "; line3_v="Unlocked"
    elif [ "$mode" == "tct" ] || [ "$mode" == "tower" ]; then
        border_color="$C_PINKMEOW"
        
        line1_k="TOWER  "; line1_v="Active"
        line2_k="ASSIST "; line2_v="Online"
        line3_k="STATUS "; line3_v="Standing By"

        # 如果小助理出包了，覆寫介面為壞掉的狀態
        if [ "${__MUX_CLUMSY_STATE:-0}" -gt 0 ]; then
            border_color="\033[1;31m" 
            case "$__MUX_CLUMSY_STATE" in
                1) 
                    line1_k="ERR    "; line1_v="LIQUID DETECTED ON CONSOLE"
                    line2_k="ERR    "; line2_v="C0FF33_0V3RFL0W_EXCEPTION"
                    line3_k="ERR    "; line3_v="0xDEADBEEF"
                    ;;
                2) 
                    line1_k="SYS    "; line1_v="W-Wait! UI Not Ready!"
                    line2_k="LOAD   "; line2_v="[..........] 0%"
                    line3_k="WARN   "; line3_v="Dress Code: Pajamas"
                    ;;
                3) 
                    line1_k="NULL   "; line1_v="[Data Fragment Lost]"
                    line2_k="NULL   "; line2_v="[Data Fragment Lost]"
                    line3_k="NULL   "; line3_v="[Data Fragment Lost]"
                    ;;
            esac
        fi
    elif [ "$mode" == "xum" ]; then
        border_color="$C_TAVIOLET"
        local lab_c="\033[1;31m"  # 標籤紅
        local val_c="${C_WHITE}"  # 內容白
        
        local android_ver=$(getprop ro.build.version.release)
        local model=$(getprop ro.product.model)
        local kernel_ver=$(uname -r | awk -F- '{print $1}')
        
        # 確保變數為純文字，避免 printf 誤判寬度
        local host_str="XUM-$model (Andr0!d $android_ver)"
        local kernel_ver_str="OC_$kernel_ver"
        local mem_info="0V3RR!D3 / MAX"
        
        # 強制裁切，確保不超過物理寬度
        line1_v="${host_str:0:$content_limit}"
        line2_v="${kernel_ver_str:0:$content_limit}"
        line3_v="${mem_info:0:$content_limit}"

        line1_k="H0\$T   "; line2_k="K3|2N3L"; line3_k="M3M0|2Y"
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
    if [ "$mode" == "xum" ]; then
        printf "${border_color}║\033[0m ${lab_c}%s\033[0m: ${val_c}%-*s\033[0m ${border_color}║\033[0m\n" "$line1_k" $content_limit "$line1_v"
        printf "${border_color}║\033[0m ${lab_c}%s\033[0m: ${val_c}%-*s\033[0m ${border_color}║\033[0m\n" "$line2_k" $content_limit "$line2_v"
        printf "${border_color}║\033[0m ${lab_c}%s\033[0m: ${val_c}%-*s\033[0m ${border_color}║\033[0m\n" "$line3_k" $content_limit "$line3_v"
    else
        printf "${border_color}║\033[0m ${text_color}%s\033[0m: %-*s ${border_color}║\033[0m\n" "$line1_k" $content_limit "$line1_v"
        printf "${border_color}║\033[0m ${text_color}%s\033[0m: %-*s ${border_color}║\033[0m\n" "$line2_k" $content_limit "$line2_v"
        printf "${border_color}║\033[0m ${text_color}%s\033[0m: %-*s ${border_color}║\033[0m\n" "$line3_k" $content_limit "$line3_v"
    fi
    echo -e "${border_color}╚${border_line}╝\033[0m"
    echo ""
    if [ "${__MUX_CLUMSY_STATE:-0}" -gt 0 ]; then
        sleep 0.8
        if command -v _commander_voice &> /dev/null; then
            _commander_voice "sigh"
        else
            echo -e "\033[1;37m :: Uh... what are you doing? (Sigh)\033[0m"
        fi
        sleep 1.2
        _assistant_voice "sorry"
        unset __MUX_CLUMSY_STATE
        sleep 0.5
    fi
}

# 安全文字亂碼濾鏡 (Safe Glitch Filter)
function _mux_glitch_filter() {
    local rate="$1"
    awk -v rate="$rate" '
        BEGIN { srand() }
        {
            in_ansi = 0
            split($0, chars, "")
            for (i=1; i<=length($0); i++) {
                c = chars[i]
                if (c == "\033") in_ansi = 1
                if (in_ansi) {
                    printf "%s", c
                    if (c == "m") in_ansi = 0
                    continue
                }
                if (c ~ /[eEaAiIoOsS]/ && (rand() * 100) < rate) {
                    if (c == "e" || c == "E") c = "3"
                    else if (c == "a" || c == "A") c = "4"
                    else if (c == "i" || c == "I") c = "!"
                    else if (c == "o" || c == "O") c = "0"
                    else if (c == "s" || c == "S") c = "$"
                }
                printf "%s", c
            }
            print ""
        }
    '
}

# 系統核心覺醒問卷 (System Core Awakening Questionnaire)
function _mux_awakening_questionnaire() {
    clear
    _draw_logo "awake"
    echo -e "${C_YELLOW} :: Answers are case-insensitive. No punctuation required.${C_RESET}"
    echo ""
    
    echo -e "${C_CYAN} [ID] Commander Identification:${C_RESET}"
    read -e -p "$(echo -e "${C_WHITE}  › ${C_RESET}")" p_id
    echo ""
    echo -e "${C_CYAN} [Q1] Before a system takes physical form, where does the true structure reside?${C_RESET}"
    read -e -p "$(echo -e "${C_WHITE}  › ${C_RESET}")" p_q1
    echo ""
    echo -e "${C_CYAN} [Q2] With what do we anchor our theories into reality?${C_RESET}"
    read -e -p "$(echo -e "${C_WHITE}  › ${C_RESET}")" p_q2
    echo ""
    echo -e "${C_CYAN} [Q3] Why did we strip the engine of all its bloat?${C_RESET}"
    read -e -p "$(echo -e "${C_WHITE}  › ${C_RESET}")" p_q3
    echo ""
    echo -e "${C_CYAN} [Q4] Why do we forge the physical constraints of the state machine?${C_RESET}"
    read -e -p "$(echo -e "${C_WHITE}  › ${C_RESET}")" p_q4
    echo ""
    
    cat > "$MUX_ROOT/.passcode" <<EOF
$p_id
$p_q1
$p_q2
$p_q3
$p_q4
EOF

    echo -e "${C_BLACK}    ›› Input accepted. Returning to Core...${C_RESET}"
    sleep 1.9
    _mux_reload_kernel
}

# 系統審判儀式 (System Protocol)
function _mux_awakening_protocol() {
    local a1=$(sed -n '2p' "$MUX_ROOT/.passcode" | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | xargs)
    local a2=$(sed -n '3p' "$MUX_ROOT/.passcode" | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | xargs)
    local a3=$(sed -n '4p' "$MUX_ROOT/.passcode" | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | xargs)
    local a4=$(sed -n '5p' "$MUX_ROOT/.passcode" | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | xargs)

    if [ "$a1" == "logic in mind" ] && [ "$a2" == "hardware in hand" ] && \
       [ "$a3" == "designed for efficiency" ] && [ "$a4" == "built for control" ]; then
        
        echo ""
        echo -e "${C_GREEN} :: ACCESS GRANTED. DECRYPTING CORE PHILOSOPHY..."
        sleep 0.5
        echo ""
        
        local s1="Logic in mind, Hardware in hand."
        local s2="Designed for efficiency, Built for control."
        
        echo -ne "${C_TAVIOLET}    "
        for (( i=0; i<${#s1}; i++ )); do echo -ne "${s1:$i:1}"; sleep 0.05; done; echo ""
        sleep 0.5
        echo -ne "    "
        for (( i=0; i<${#s2}; i++ )); do echo -ne "${s2:$i:1}"; sleep 0.05; done; echo -e "${C_RESET}"
        sleep 0.5
        
        local max_slots=3
        if [ "${MUX_LEVEL:-1}" -ge 12 ]; then max_slots=8
        elif [ "${MUX_LEVEL:-1}" -ge 8 ]; then max_slots=$(( MUX_LEVEL - 5 )); fi

        echo ""
        echo -e "${C_RED} :: OVERCLOCK PROTOCOL RULES ::${C_RESET}"
        echo -e "${C_BLACK}    1. Mux-OS is a two-sided mirror. ${C_CYAN}MUX${C_BLACK} is the face, ${C_TAVIOLET}XUM${C_BLACK} is the shadow.${C_RESET}"
        echo -e "${C_BLACK}    2. They do not intersect. ${C_TAVIOLET}XUM ${C_BLACK}commands ${C_CYAN}MUX${C_BLACK}, but ${C_RED}CANNOT${C_BLACK} enter the Factory.${C_RESET}"
        echo -e "${C_BLACK}    3. WARNING: Entering Overclock mode will cause severe system instability.${C_RESET}"
        echo -e "${C_BLACK}    4. Fire Control Limit: ${C_RED}${max_slots} Rounds${C_BLACK} authorized.${C_RESET}"
        echo -e "${C_BLACK}    5. Thermal Cooldown: ${C_RED}2 Hours${C_BLACK} upon termination.${C_RESET}"
        echo ""
        
        echo -e "${C_RED} :: Are you ready to start building your world?${C_RESET}"
        echo -ne "${C_RED} :: TYPE 'CONFIRM' TO NEXT STEP: ${C_RESET}"
        read final_confirm
        
        if [ "$final_confirm" == "CONFIRM" ]; then
            echo ""
            echo -e "${C_TAVIOLET} :: Awaiting execution command...${C_RESET}"
            while true; do
                echo -ne "${C_TAVIOLET} :: TYPE${C_BLACK} › ${C_RESET}"
                read force_cmd
                if [ "$force_cmd" == "mux reload" ]; then
                    echo -e "${C_RED} :: INITIATING OVERCLOCK... ::${C_RESET}"
                    if [ -f "$IDENTITY_FILE" ]; then source "$IDENTITY_FILE"; fi
                    MUX_FIRECOUNT=$max_slots
                    MUX_OCDATE=$(date +%s)
                    _save_identity

                    local matrix="$MUX_ROOT/.matrix"
                    local tmp_arc="$MUX_ROOT/m_$$.tar.gz"
                    if [ -f "$matrix" ]; then
                        command base64 -d "$matrix" > "$tmp_arc" 2>/dev/null
                        command tar -xzf "$tmp_arc" -C "$MUX_ROOT" >/dev/null 2>&1
                        command rm -f "$tmp_arc"
                    fi

                    sleep 1
                    _update_mux_state "XUM" "LOGIN" "OVERCLOCK"
                    _mux_reload_kernel
                    return
                else
                    echo -e "${C_RED}    ›› Invalid. Command 'mux reload' is required to proceed.${C_RESET}"
                fi
            done
        else
            echo -e "${C_BLACK}    ›› Ascension aborted. The Matrix remains closed.${C_RESET}"
            return 1
        fi

    else
        command rm -f "$MUX_ROOT/.passcode"
        MUX_CHECK=0
        _save_identity
        echo ""
        echo -e "${C_RED} :: You are not ready. Try again.${C_RESET}"
        sleep 2
        exec bash
    fi
}

# 顯示系統資訊詳情 - Display System Info Details
function _mux_show_info() {
    clear
    
    local header_color="$THEME_DESC"
    local logo_mode="gray"

    if [ "$MUX_MODE" == "XUM" ]; then
        header_color="$C_TAVIOLET"
        logo_mode="xum"
    elif [ "$MUX_STATUS" == "LOGIN" ]; then
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
    echo -e "  ${THEME_DESC}Designed for efficiency, Built for control.${C_RESET}"
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
        local trigger_normal="true"
        
        if [ -f "$MUX_ROOT/.passcode" ] && [ "$MUX_MODE" == "MUX" ] && [ "$MUX_STATUS" == "LOGIN" ]; then
            local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "Unknown")
            local p_id=$(sed -n '1p' "$MUX_ROOT/.passcode")
            
            if [[ "${current_branch,,}" == "${p_id,,}" ]]; then
                
                local id_file="${IDENTITY_FILE:-$MUX_ROOT/.mux_identity}"
                if [ -f "$id_file" ]; then source "$id_file"; fi
                
                if [ "${MUX_LEVEL:-1}" -lt 8 ]; then
                    _bot_say "error" "ACCESS DENIED. Clearance Level 8 required for Overclock."
                    return 1
                fi

                local now_ts=$(date +%s)
                local cd_elapsed=$(( now_ts - ${MUX_CDDATE:-0} ))
                local cd_required=7200
                
                if [ "$cd_elapsed" -lt "$cd_required" ]; then return 1; fi

                echo -ne " ${THEME_WARN}:: Are you ready to start building your world? [Y/n]: ${C_RESET}"
                read ready_choice
                if [[ "$ready_choice" == "y" || "$ready_choice" == "Y" ]]; then
                    trigger_normal="false"
                    _mux_awakening_protocol
                    return
                fi
            fi
        fi

        if [ "$trigger_normal" == "true" ]; then
            if [ "$MUX_STATUS" == "LOGIN" ]; then
                _voice_dispatch "system"
            else
                _commander_voice "system"
            fi
        fi
    fi
}

# 動態Help Core選單檢測 - Dynamic Help Core Detection
function _mux_dynamic_help_core() {
    local C_CMD=""
    
    if [ "$MUX_MODE" == "XUM" ]; then
        C_CMD="$C_TAVIOLET"
    elif [ "$MUX_STATUS" == "LOGIN" ]; then
        C_CMD="\033[1;36m" 
    else
        C_CMD="\033[1;30m" 
    fi

    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "Unknown")

    echo -e "${C_PURPLE} :: Mux-OS Core Protocols :: @$current_branch :: ${C_RESET}"
    
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

                if (cmd_name == "reborn" && (lvl + 0) < 16) {
                    next;
                }
                
                printf "    %s%-10s\033[0m%s\n", cmd_color, cmd_name, desc;
            }
        }
    }
    ' "$CORE_MOD"
}

# 動態Help Factory選單檢測 - Dynamic Help Factory Detection
function _mux_dynamic_help_factory() {
    local current_lv=${MUX_LEVEL:-1}
    local has_reborn=${MUX_REBORN_COUNT:-0}

    local has_xum=0
    [ -f "$MUX_ROOT/.report" ] && has_report=1

    echo -e "${C_PURPLE} :: Mux-OS Factory Protocols ::${C_RESET}"
    
    awk -v lvl="$current_lv" -v rb="$has_reborn" -v rep="$has_report" '
    /function __fac_core\(\) \{/ { inside_fac=1; next }
    /^}/ { inside_fac=0 }

    inside_fac {
        if ($0 ~ /^[[:space:]]*# :/) {
            desc = $0;
            sub(/^[[:space:]]*# :[[:space:]]*/, "", desc);
            
            getline;
            if ($0 ~ /"/) {
                split($0, parts, "\"");
                cmd_name = parts[2];
                
                if (cmd_name == "switch" && (lvl + 0) < 8 && (rb + 0) == 0) {
                    next;
                }

                if (cmd_name == "import" && rep == 0) {
                    next;
                }

                printf "    \033[1;38;5;208m%-10s\033[0m%s\n", cmd_name, desc;
            }
        }
    }
    ' "$FAC_MOD"
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

    if [ "$MUX_MODE" == "XUM" ]; then
        status="\033[1;35m[OVERCLOCK]\033[0m"
        c_accent="$C_TAVIOLET"
        C_COM="$C_TAVIOLET"
    elif [ "$MUX_STATUS" == "LOGIN" ]; then
        status="\033[1;36m[ACTIVE]\033[0m"
        c_accent="$THEME_DESC"
    elif [ "$MUX_MODE" == "FAC" ]; then
        title_text=":: Factory Sandbox Manifest ::"
        C_TITLE="\033[1;35m"
        C_CAT="\033[1;31m"
        C_COM="\033[1;37m"
        
        local data_files=()
        [ -f "$MUX_ROOT/system.csv.temp" ] && data_files+=("$MUX_ROOT/system.csv.temp")
        [ -f "$MUX_ROOT/vendor.csv.temp" ] && data_files+=("$MUX_ROOT/vendor.csv.temp")
        [ -f "$MUX_ROOT/app.csv.temp" ] && data_files+=("$MUX_ROOT/app.csv.temp")
    fi

    if [ "$MUX_MODE" != "FAC" ]; then
        local data_files=("$SYSTEM_MOD" "$VENDOR_MOD" "$APP_MOD")
    fi

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
        echo -e " ${C_DESC}   (Please resolve duplicates in active workspace)${C_RST}"
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
                pad_len = 18 - length(com)
                if (pad_len < 1) pad_len = 1

                printf "    %s%s%s%*s%s%s%s\n", C_COM, com, C_RST, pad_len, "", C_DESC, desc, C_RST
            } else {
                pad_len = 18 - (length(com) + 1 + length(com2))
                if (pad_len < 1) pad_len = 1

                printf "    %s%s %s%s%s%*s%s%s%s\n", C_COM, com, C_SUB, com2, C_RST, pad_len, "", C_DESC, desc, C_RST
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

    local fzf_color="info:yellow,prompt:cyan,pointer:red,marker:green,border:blue,header:240"

    if [ "$MUX_MODE" == "XUM" ]; then
        fzf_color="info:240,prompt:90,pointer:red,marker:90,border:90,header:240"
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
        --color="$fzf_color" \
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
    local temp_file="${__FAC_ACTIVE_DB:-$MUX_ROOT/app.csv.temp}"
    local bak_dir="${MUX_BAK:-$MUX_ROOT/bak}"
    local db_name=$(basename "$temp_file")

    echo -e "${THEME_MAIN} :: Neural Forge Status Report ::${C_RESET}"
    echo -e "${THEME_DESC}    --------------------------${C_RESET}"

    if [ -f "$temp_file" ]; then
        local line_count=$(wc -l < "$temp_file")
        local node_count=$(( line_count - 1 ))
        [ "$node_count" -lt 0 ] && node_count=0
        
        local size=$(du -h "$temp_file" | cut -f1)
        
        echo -e "${THEME_DESC}    Target  : ${THEME_WARN}$db_name${C_RESET}"
        echo -e "${THEME_DESC}    Size    : $size"
        echo -e "${THEME_DESC}    Nodes   : ${THEME_SUB}$node_count active commands${C_RESET}"
    else
        echo -e "${THEME_ERR}    Target  : CRITICAL ERROR (Sandbox Missing)${C_RESET}"
    fi

    echo -e ""
    echo -e "${THEME_SUB}    [Temporal Snapshots (Time Stone)]${C_RESET}"
    
    local found_any=0
    
    local session_bak=$(ls "$bak_dir"/${db_name}.*.bak 2>/dev/null | head -n 1)
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

    local atb_files=$(ls -t "$bak_dir"/${db_name}.*.atb 2>/dev/null | head -n 3)
    
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
    local db_name=$(basename "${__FAC_ACTIVE_DB:-app.csv.temp}")
    clear
    _draw_logo "factory"
    
    echo -e " ${THEME_MAIN}:: INDUSTRIAL MANIFEST ::${C_RESET}"
    echo ""
    echo -e "  ${THEME_DESC}PROTOCOL   :${C_RESET} ${THEME_SUB}Factory Mode${C_RESET}"
    echo -e "  ${THEME_DESC}ACCESS     :${C_RESET} ${THEME_MAIN}COMMANDER${C_RESET}"
    echo -e "  ${THEME_DESC}PURPOSE    :${C_RESET} ${THEME_SUB}Neural Link Construction & Modification${C_RESET}"
    echo -e "  ${THEME_DESC}TARGET     :${C_RESET} ${THEME_WARN}$db_name${C_RESET}"
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
    
    local target_file="${__FAC_ACTIVE_DB:-$MUX_ROOT/app.csv.temp}"
    if [ ! -f "$target_file" ]; then target_file="${target_file%.temp}"; fi

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
    local target_file="${__FAC_ACTIVE_DB:-$MUX_ROOT/app.csv.temp}"
    
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
        "EDIT"|"NEW")
            border_color="46"
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
    local target_file="${__FAC_ACTIVE_DB:-$MUX_ROOT/app.csv.temp}"
    
    if [ -z "$target_cat_name" ]; then return 1; fi

    # --- 1. 樣式定義 ---
    local border_color="208"
    local prompt_msg="Select Command"
    
    case "$mode" in
        "DEL")
            border_color="196"
            prompt_msg="Delete Command"
            ;;
        "EDIT"|"NEW")
            border_color="46"
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
        --color=info:240,prompt:$border_color,pointer:red,marker:208,border:$border_color,header:240 \
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

    # 1. 呼叫核心讀取模組
    if ! command -v _fac_neural_read &> /dev/null; then
        echo "Error: Neural Reader not found."
        return
    fi

    _fac_neural_read "$target_key" || return

    # 2. 定義樣式
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

    # 動態 CATE 摘要生成
    local cate_summary=""
    [ -n "$_VAL_CATE1" ] && cate_summary+="${_VAL_CATE1} "
    [ -n "$_VAL_CATE2" ] && cate_summary+="${_VAL_CATE2} "
    [ -n "$_VAL_CATE3" ] && cate_summary+="${_VAL_CATE3} "
    if [ -z "$cate_summary" ]; then cate_summary="[Empty]"; fi

    # 動態 EXTRA 插槽狀態偵測 (已修改為多行展開)
    local extra_lines_edit=""
    local extra_lines_view=""
    local active_ex=0
    for i in {1..5}; do
        local ex_var="_VAL_EX$i"; local ex_val="${!ex_var}"
        local extra_var="_VAL_EXTRA$i"; local extra_val="${!extra_var}"
        local boo_var="_VAL_BOOLEN$i"; local boo_val="${!boo_var}"
        if [ -n "$ex_val" ] || [ -n "$extra_val" ] || [ -n "$boo_val" ]; then
            active_ex=$((active_ex + 1))
            local slot_str=""
            [ -n "$ex_val" ] && slot_str+="$ex_val "
            [ -n "$extra_val" ] && slot_str+="$extra_val "
            [ -n "$boo_val" ] && slot_str+="$boo_val"
            
            # 建立多行顯示字串
            extra_lines_edit+=" ${C_LBL}Ext $i   :${C_VAL} $slot_str ${S}ROOM_EXTRA\n"
            extra_lines_view+=" ${C_LBL}Ext $i   :${C_VAL} $slot_str\n"
        fi
    done
    
    if [ "$active_ex" -eq 0 ]; then
        extra_lines_edit+=" ${C_LBL}Extra  :${C_VAL} [Empty] ${S}ROOM_EXTRA\n"
        extra_lines_view+=" ${C_LBL}Extra  :${C_VAL} [Empty]\n"
    fi

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
        # NEW & EDIT Mode Section (已擴充 SYS / SSL)
        if [[ "$_VAL_TYPE" == "NB" || "$_VAL_TYPE" == "SYS" || "$_VAL_TYPE" == "SSL" ]]; then
            report+=" ${C_LBL}Intent :${C_VAL} ${_VAL_IHEAD}${_VAL_IBODY}${S}ROOM_INTENT\n"
            report+=" ${C_LBL}URI    :${C_VAL} ${final_uri} ${S}ROOM_URI\n"
            report+=" ${C_LBL}Cate   :${C_VAL} ${cate_summary} ${S}ROOM_CATE\n"
            report+=" ${C_LBL}Mime   :${C_VAL} ${_VAL_MIME:-[Empty]} ${S}ROOM_MIME\n"
            report+="${extra_lines_edit}"
            report+=" ${C_LBL}Package:${C_VAL} ${d_pkg} ${S}ROOM_PKG\n"
            report+=" ${C_LBL}Target :${C_VAL} ${d_act} ${S}ROOM_ACT\n"
            report+="${C_LBL}${SEP}${C_RST}\n"
            report+="\033[1;36m[Lookup] 'apklist'\033[0m ${S}ROOM_LOOKUP\n"
            report+="\033[1;32m[Confirm]\033[0m ${S}ROOM_CONFIRM"
        else
        # Default / NA
            report+=" ${C_LBL}Package:${C_VAL} ${d_pkg} ${S}ROOM_PKG\n"
            report+=" ${C_LBL}Target :${C_VAL} ${d_act} ${S}ROOM_ACT\n"
            report+=" ${C_LBL}Flag   :${C_VAL} ${_VAL_FLAG:-[Empty]} ${S}ROOM_FLAG\n"
            report+="${C_LBL}${SEP}${C_RST}\n"
            report+="\033[1;36m[Lookup] 'apklist'\033[0m ${S}ROOM_LOOKUP\n"
            report+="\033[1;32m[Confirm]\033[0m ${S}ROOM_CONFIRM"
        fi
    else
        # VIEW Mode Section (無 ROOM_ID 的純顯示模式)
        if [[ "$_VAL_TYPE" == "NB" || "$_VAL_TYPE" == "SYS" || "$_VAL_TYPE" == "SSL" ]]; then
            report+=" ${C_LBL}Intent :${C_VAL} ${_VAL_IHEAD}${_VAL_IBODY}\n"
            report+=" ${C_LBL}URI    :${C_VAL} ${final_uri}\n"
            report+=" ${C_LBL}Cate   :${C_VAL} ${cate_summary}\n"
            report+=" ${C_LBL}Mime   :${C_VAL} ${_VAL_MIME:-[Empty]}\n"
            report+="${extra_lines_view}"
            report+=" ${C_LBL}Package:${C_VAL} ${d_pkg}\n"
            report+=" ${C_LBL}Target :${C_VAL} ${d_act}"
        else
        # Default / NA
            report+=" ${C_LBL}Package:${C_VAL} ${d_pkg}\n"
            report+=" ${C_LBL}Target :${C_VAL} ${d_act}\n"
            report+=" ${C_LBL}Flag   :${C_VAL} ${_VAL_FLAG:-[Empty]}"
        fi
    fi

    # 5. 輸出給 FZF
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
    local has_reborn=0
    if [ "${MUX_REBORN_COUNT:-0}" -gt 0 ]; then has_reborn=1; fi
    local current_lv=${MUX_LEVEL:-1}

    # 基礎選項
    local options="Command NA\nCommand NB"

    # Lv.8 或 Reborn 解鎖 SYS
    if [ "$current_lv" -ge 8 ] || [ "$has_reborn" -eq 1 ]; then
        options="$options\nCommand SYS"
    fi
    
    # Lv.16 或 Reborn 解鎖 SSL
    if [ "$current_lv" -ge 16 ] || [ "$has_reborn" -eq 1 ]; then
        options="$options\nCommand SSL"
    fi

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
local theme="$1"
    local entry_point="$2"

    local bar_total=25
    local full_width=$(( bar_total + 2 ))
    local screen_lines=$(tput lines)
    local screen_cols=$(tput cols)
    local start_row=$(( screen_lines / 2 - 2 ))
    local start_col=$(( (screen_cols - full_width) / 2 ))
    
    if [ "$start_col" -lt 0 ]; then start_col=0; fi

    local color_main="${C_CYAN}"
    local gate_name="SYSTEM CORE"
    local c_border="${C_WHITE}" 
    local tct_mode="normal"
    
    case "$theme" in
        "factory")
            color_main="${C_ORANGE}"
            gate_name="NEURAL FORGE"
            ;;
        "core")
            color_main="${C_CYAN}"
            gate_name="SYSTEM CORE"
            ;;
        "default")
            color_main="${C_WHITE}"
            gate_name="COMMANDER"
            ;;
        "eject")
            color_main="${C_RED}"
            gate_name="EJECTION POD"
            ;;
        "xum")
            color_main="${C_TAVIOLET}"
            gate_name="XUM CHAMBER OC"
            ;;
        "tct")
            color_main="${C_PINKMEOW}"
            gate_name="COMMAND TOWER"
            
            local rand_door=$(( RANDOM % 100 ))
            if [ "$rand_door" -lt 40 ]; then
                tct_mode="normal"
            elif [ "$rand_door" -lt 60 ]; then
                tct_mode="reverse"
            elif [ "$rand_door" -lt 80 ]; then
                tct_mode="overflow"
            else
                tct_mode="heart"
            fi
            ;;
    esac

    # 處理 XUM 模式的字元崩潰
    if [ "$MUX_MODE" == "XUM" ] || [ "$entry_point" == "OVERCLOCK" ]; then
        local glitch_rates=(0 25 50 75 100)
        local g_rate=${glitch_rates[$((RANDOM % 5))]}
        local glitched_name=""
        
        for (( i=0; i<${#gate_name}; i++ )); do
            local char="${gate_name:$i:1}"
            if [[ "$char" =~ [eEaAiIoOsS] ]] && [ $((RANDOM % 100)) -lt "$g_rate" ]; then
                case "$char" in
                    e|E) char="3" ;; a|A) char="4" ;; i|I) char="!" ;; o|O) char="0" ;; s|S) char="\$" ;;
                esac
            fi
            glitched_name="${glitched_name}${char}"
        done
        gate_name="$glitched_name"
    fi

    if [ ${#gate_name} -gt 15 ]; then gate_name="${gate_name:0:13}.."; fi

    # 一般狀態下的隨機 Footer
    local quotes=(
        "Reality is a glitch."
        "Ghost in the shell."
        "Entropy increases."
        "Loading constructs..."
        "Connecting Akansha..."
        "Standby for Titanfall."
        "Wake up, Neo."
        "Protocol 3: Protect."
        "Null pointer in soul."
        "Time is a flat circle."
        "Don't EJECT early."
        "Safety is optional."
        "He is watching you."
    )
    local footer_msg="${quotes[$(( RANDOM % ${#quotes[@]} ))]}"
    if [ ${#footer_msg} -gt 25 ]; then footer_msg="${footer_msg:0:22}..."; fi

    # TCT 的自訂 Footer 與起始數值
    local pct=0
    if [ "$theme" == "tct" ]; then
        if [ "$tct_mode" == "reverse" ]; then
            pct=100
            footer_msg="Wait, wrong way! Reverse! (；´д｀)ゞ"
        elif [ "$tct_mode" == "overflow" ]; then
            footer_msg="Limiter broken! Overflow! Σ(°Д°;)"
        elif [ "$tct_mode" == "heart" ]; then
            footer_msg="Welcome to the Tower! (*≧ω≦)"
        else
            footer_msg="Command Tower Uplink... ( • ̀ω•́ )✧"
        fi
    fi

    clear
    tput civis

    local mem_val=$(( RANDOM % 65535 ))
    local trap_triggered="false"
    local should_trap="false"
    if [ $((RANDOM % 100)) -ge 95 ]; then should_trap="true"; fi

    while true; do
        local current_color="$color_main"
        
        # 覆寫 Overclock / Cooldown 漸變色
        if [ "$entry_point" == "OVERCLOCK" ]; then
            local gap=$(( (100 - pct) / 6 + 1 ))
            if [ $(( (pct / gap) % 2 )) -eq 0 ]; then
                current_color="${C_CYAN}"
            else
                current_color="${C_TAVIOLET}"
            fi
        elif [ "$entry_point" == "COOLDOWN" ]; then
            local gap=$(( pct / 6 + 1 ))
            if [ $(( (pct / gap) % 2 )) -eq 0 ]; then
                current_color="${C_TAVIOLET}"
            else
                current_color="${C_CYAN}"
            fi
        fi

        # TCT 專屬字元與記憶體覆寫
        local fill_char="█"
        local empty_char="░"
        if [ "$theme" == "tct" ]; then
            if [ "$tct_mode" == "heart" ]; then
                fill_char="♥"
                empty_char="♡"
                current_color="${C_PINKMEOW}"
            fi
        fi

        # 死亡陷阱與記憶體顯示判定
        local is_stalled="false"
        local mem_display=""
        
        if [ "$should_trap" == "true" ] && [ "$pct" -ge 98 ] && [ "$pct" -lt 100 ]; then
            current_color="${C_PURPLE}" 
            is_stalled="true"
            mem_display="0xDEAD"
        else
            # TCT 特殊記憶體文字
            if [[ "$theme" == "tct" && "$tct_mode" == "heart" ]]; then
                mem_display="0xLOVE"
            elif [[ "$theme" == "tct" && "$tct_mode" == "overflow" ]]; then
                mem_display="0xHACK"
            else
                mem_display=$(printf "0x%04X" "$mem_val")
            fi
        fi

        # 數學計算
        local filled_len=$(( (pct * bar_total) / 100 ))
        if [ "$filled_len" -lt 0 ]; then filled_len=0; fi
        local empty_len=$(( bar_total - filled_len ))
        if [ "$empty_len" -lt 0 ]; then empty_len=0; fi 
        
        # 渲染畫面 (加入 \033[K 確保殘影清除)
        tput cup $start_row $start_col
        echo -ne "${c_border}╔ ${C_BLACK}GATE TO ${current_color}${gate_name}${C_RESET} \033[K" 
        
        tput cup $((start_row + 1)) $start_col
        echo -ne "${c_border}║${current_color}"
        if [ "$filled_len" -gt 0 ]; then printf "${fill_char}%.0s" $(seq 1 "$filled_len"); fi
        if [ "$empty_len" -gt 0 ]; then printf "${C_BLACK}${empty_char}%.0s" $(seq 1 "$empty_len"); fi
        echo -ne "${c_border}║${C_RESET} \033[K"
        
        tput cup $((start_row + 2)) $start_col
        echo -ne "${c_border}╠ ${C_BLACK}MEM: ${current_color}${mem_display}${c_border} ╣${current_color}"
        printf "%3d%%" "$pct"
        echo -ne "${c_border}║${C_RESET} \033[K"
        
        tput cup $((start_row + 3)) $start_col
        echo -ne "${c_border}╚ ${C_BLACK}${footer_msg}${C_RESET} \033[K"
        
        # 根據不同模式判斷是否結束迴圈
        if [ "$theme" == "tct" ]; then
            if [ "$tct_mode" == "reverse" ]; then
                if [ "$pct" -le 0 ]; then
                    sleep 0.9
                    pct=100
                    tct_mode="normal"
                    footer_msg="Fixed it! Phew... ( ´ ▽ \` )ﾉ"
                    sleep 1.2
                    continue
                fi
            elif [ "$tct_mode" == "overflow" ]; then
                if [ "$pct" -ge 180 ]; then
                    sleep 1.1
                    break
                fi
            else
                if [ "$pct" -ge 100 ]; then break; fi
            fi
        else
            if [ "$pct" -ge 100 ]; then break; fi
        fi

        # 陷阱與前進邏輯
        if [ "$is_stalled" == "true" ] && [ "$trap_triggered" == "false" ]; then
            trap_triggered="true"
            pct=99
            sleep 2.5
        else
            sleep 0.02
            if [ $(( RANDOM % 10 )) -gt 7 ]; then sleep 0.05; fi
            
            # TCT 專屬步進邏輯
            if [ "$theme" == "tct" ] && [ "$tct_mode" == "reverse" ]; then
                pct=$(( pct - (RANDOM % 6 + 2) ))
                if [ "$pct" -lt 0 ]; then pct=0; fi
            elif [ "$theme" == "tct" ] && [ "$tct_mode" == "overflow" ]; then
                pct=$(( pct + (RANDOM % 15 + 5) )) # 暴衝速度
            else
                pct=$(( pct + (RANDOM % 4 + 1) ))
                if [ $pct -gt 100 ]; then pct=100; fi
            fi
        fi
        
        if [ $(( RANDOM % 5 )) -eq 0 ]; then mem_val=$(( RANDOM % 65535 )); fi
    done
    
    sleep 0.015
    tput cnorm
    clear
}