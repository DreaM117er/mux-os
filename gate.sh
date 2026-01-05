#!/bin/bash
# gate.sh - Mux-OS Stargate Protocol v5.0.1

TARGET_SYSTEM="$1"
MUX_ROOT="$HOME/mux-os"
STATE_FILE="$MUX_ROOT/.mux_state"

# 系統選擇與主題設定
if [ "$TARGET_SYSTEM" == "factory" ]; then
    THEME_COLOR="\033[1;38;5;208m"
    THEME_TEXT="NEURAL FORGE"
    NEXT_STATE="factory"
    ICON="⚙️"
else
    THEME_COLOR="\033[1;36m"
    THEME_TEXT="SYSTEM CORE"
    NEXT_STATE="core"
    TARGET_SYSTEM="core"
    ICON="💠"
fi

C_TXT="\033[1;30m"
C_RESET="\033[0m"

# 系統準備 - 隱藏游標與清屏
tput civis
clear

echo "$NEXT_STATE" > "$STATE_FILE"

# 動畫序列 - Data Stream 模擬
ROWS=$(tput lines)
COLS=$(tput cols)
CENTER_ROW=$(( ROWS / 2 ))
CENTER_COL=$(( (COLS - 30) / 2 ))

# 1. 標題與圖標
tput cup $((CENTER_ROW - 2)) $CENTER_COL
echo -e "${C_TXT}:: ACCESSING ${THEME_COLOR}${THEME_TEXT} ${ICON}${C_TXT} ::${C_RESET}"

# 2. 數據流模擬 (Data Stream)
BAR_LEN=30
for i in {1..30}; do
    PCT=$(( i * 100 / 30 )) 
    
    tput cup $CENTER_ROW $CENTER_COL
    
    echo -ne "${C_TXT}[${C_RESET}"
    
    for ((j=0; j<i; j++)); do 
        if [ $((j % 5)) -eq 0 ]; then
            echo -ne "${C_RESET}#${THEME_COLOR}"
        else
            echo -ne "#"
        fi
    done
    
    for ((j=i; j<30; j++)); do echo -ne " "; done
    
    echo -ne "${C_TXT}] ${PCT}%${C_RESET}"
    
    if [ $((i % 3)) -eq 0 ]; then
        RAND_HEX=$(openssl rand -hex 2 2>/dev/null || echo "FA0${i}")
        tput cup $((CENTER_ROW + 2)) $((CENTER_COL + 5))
        echo -e "${C_TXT}>> HEX_ADDR: 0x${RAND_HEX^^} <<${C_RESET}"
    fi

    sleep 0.015
done

# 3. 完整性檢查
if [ "$NEXT_STATE" == "factory" ] && [ ! -f "$MUX_ROOT/factory.sh" ]; then
    tput cup $((CENTER_ROW + 4)) $CENTER_COL
    echo -e "${C_TXT}:: CRITICAL ERROR :: MODULE MISSING${C_RESET}"
    sleep 1
    echo "core" > "$STATE_FILE"
    exec "$MUX_ROOT/gate.sh" "core"
fi

# 4. 啟動目標系統
tput cnorm
stty sane 
clear
exec bash