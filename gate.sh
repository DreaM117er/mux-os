#!/bin/bash
# gate.sh - Mux-OS 星門啟動器

MUX_ROOT="$HOME/mux-os"
STATE_FILE="$MUX_ROOT/.mux_state"
TARGET_ARG="$1"

if [ -n "$TARGET_ARG" ]; then
    TARGET_SYSTEM="$TARGET_ARG"
else
    if [ -f "$STATE_FILE" ]; then
        LAST_STATE=$(cat "$STATE_FILE")
        TARGET_SYSTEM=$(echo "$LAST_STATE" | tr -d '[:space:]')
    fi
    
    if [ -z "$TARGET_SYSTEM" ]; then
        TARGET_SYSTEM="core"
    fi
fi

echo "$TARGET_SYSTEM" > "$STATE_FILE"

if [ "$TARGET_SYSTEM" == "factory" ]; then
    THEME_COLOR="\033[1;38;5;208m"
    THEME_TEXT="NEURAL FORGE"
    NEXT_STATE="factory"
    ICON=""
else
    THEME_COLOR="\033[1;36m"
    THEME_TEXT="SYSTEM CORE"
    NEXT_STATE="core"
    TARGET_SYSTEM="core"
    ICON=""
fi

C_TXT="\033[1;30m"
C_RESET="\033[0m"

tput civis
clear

# 注意：這裡移除重複寫入 STATE_FILE 的動作，上面已經寫過了

ROWS=$(tput lines)
COLS=$(tput cols)

BAR_LEN=$(( COLS * 45 / 100 ))
if [ "$BAR_LEN" -lt 15 ]; then BAR_LEN=15; fi

CENTER_ROW=$(( ROWS / 2 ))
BAR_START_COL=$(( (COLS - BAR_LEN - 2) / 2 ))
STATS_START_COL=$(( (COLS - 24) / 2 ))
TITLE_START_COL=$(( (COLS - 25) / 2 ))

tput cup $((CENTER_ROW - 2)) $TITLE_START_COL
echo -e "${C_TXT}:: GATE ${THEME_COLOR}${THEME_TEXT} ${ICON}${C_TXT}::${C_RESET}"

HEX_ADDR="0x0000"

for i in $(seq 1 "$BAR_LEN"); do
    PCT=$(( i * 100 / BAR_LEN ))
    
    tput cup $CENTER_ROW $BAR_START_COL
    echo -ne "${C_TXT}[${C_RESET}"
    
    if [ "$i" -gt 0 ]; then
        printf "${THEME_COLOR}%.0s#${C_RESET}" $(seq 1 "$i")
    fi
    
    REMAIN=$(( BAR_LEN - i ))
    if [ "$REMAIN" -gt 0 ]; then
        printf "%.0s " $(seq 1 "$REMAIN")
    fi
    echo -ne "${C_TXT}]${C_RESET}"

    tput cup $((CENTER_ROW + 2)) $STATS_START_COL
    if [ "$PCT" -lt 100 ]; then
        echo -ne "${C_TXT}:: SYSTEM UPLINK ... ${PCT}% ::${C_RESET}"
    else
        echo -ne "${C_TXT}:: UPLINK ESTABLISHED ::    ${C_RESET}"
    fi
    
    # sleep 0.005 # 可選：依需求開啟或關閉動畫延遲
done

sleep 0.2
tput cnorm
clear

# ==============================================================================
# [SYSTEM LOADER] 核心載入序列 (邏輯修正)
# ==============================================================================

# 1. [CRITICAL] 永遠先載入 Core 基礎設施
source "$MUX_ROOT/core.sh"

# 2. 根據目標載入 Factory
if [ "$TARGET_SYSTEM" == "factory" ]; then
    if [ -f "$MUX_ROOT/factory.sh" ]; then
        source "$MUX_ROOT/factory.sh"
        
        # 啟動 Factory 初始化 (建立 Temp 檔、備份等)
        if command -v _factory_system_boot &> /dev/null; then
            _factory_system_boot
        else
            echo -e "\033[1;31m[ERROR] Factory Bootloader Not Found.\033[0m"
        fi
    else
        echo -e "\033[1;31m[ERROR] Factory Module Missing.\033[0m"
        # Fallback to core if factory fails
    fi
else
    # Core 模式已經在上面 source 完成，無需額外動作
    :
fi