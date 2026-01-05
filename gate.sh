#!/bin/bash
# gate.sh - Mux-OS Stargate Protocol

# 接收目標參數: "factory" 或 "core"
TARGET_SYSTEM="$1"
MUX_ROOT="$HOME/mux-os"
STATE_FILE="$MUX_ROOT/.mux_state"

# 1. 目標判定與視覺設定
if [ "$TARGET_SYSTEM" == "factory" ]; then
    THEME_COLOR="\033[1;31m"   # Factory 紅
    THEME_TEXT="NEURAL FORGE"
    NEXT_STATE="factory"
else
    THEME_COLOR="\033[1;36m"   # Core 青
    THEME_TEXT="SYSTEM CORE"
    NEXT_STATE="core"
    TARGET_SYSTEM="core"       # 預設防呆
fi

C_TXT="\033[1;30m"   # 灰色
C_RESET="\033[0m"

# 隱藏游標
tput civis
clear

# 2. 狀態寫入 (交接信物)
# 這是最重要的步驟，exec bash 後新系統會讀取這個檔案來決定載入誰
echo "$NEXT_STATE" > "$STATE_FILE"

# 3. 視覺轉場動畫
ROWS=$(tput lines)
COLS=$(tput cols)
CENTER_ROW=$(( ROWS / 2 ))
# 標題置中
TITLE_COL=$(( (COLS - 24) / 2 )) 

tput cup $((CENTER_ROW - 2)) $TITLE_COL
echo -e "${C_TXT}:: ACCESSING ${THEME_COLOR}${THEME_TEXT}${C_TXT} ::${C_RESET}"

# 進度條動畫 (約 0.6 秒)
BAR_LEN=24
BAR_COL=$(( (COLS - BAR_LEN - 9) / 2 ))

for i in {1..24}; do
    PCT=$(( i * 4 )) 
    tput cup $CENTER_ROW $BAR_COL
    echo -ne "${C_TXT}[${C_RESET}"
    for ((j=0; j<i; j++)); do echo -ne "${THEME_COLOR}#${C_RESET}"; done
    for ((j=i; j<24; j++)); do echo -ne " "; done
    echo -ne "${C_TXT}] ${PCT}%${C_RESET}"
    sleep 0.02
done

# 4. 完整性檢查 (Gatekeeper)
# 如果要去 Factory 但檔案不存在，攔截並導向 Setup
if [ "$NEXT_STATE" == "factory" ] && [ ! -f "$MUX_ROOT/factory.sh" ]; then
    tput cnorm
    echo -e "\n\n${C_TXT} :: ERROR: Factory Module Missing.${C_RESET}"
    sleep 1
    # 這裡可以選擇報錯或導向修復，這裡選擇直接報錯回 Core
    echo "core" > "$STATE_FILE"
    exec "$MUX_ROOT/gate.sh" "core"
fi

# 5. 跳躍 (The Jump)
tput cnorm
clear
exec bash