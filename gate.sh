#!/bin/bash
# gate.sh - Mux-OS 星門啟動器

TARGET_SYSTEM="$1"
MUX_ROOT="$HOME/mux-os"
STATE_FILE="$MUX_ROOT/.mux_state"

if [ -z "$TARGET_SYSTEM" ]; then TARGET_SYSTEM="core"; fi

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

echo "$NEXT_STATE" > "$STATE_FILE"

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
    
    if [ $((i % 2)) -eq 0 ]; then
        HEX_ADDR=$(printf "0x%04X" $((RANDOM%65535)))
    fi
    
    echo -ne "${C_TXT}:: ${THEME_COLOR}"
    printf "%3d%%" "$PCT"
    echo -ne "${C_TXT} :: MEM: ${HEX_ADDR}${C_RESET}\033[K"

    sleep 0.015
done

stty sane
tput cnorm
clear

if [ "$TARGET_SYSTEM" == "core" ]; then
    unset __MUX_MODE 2>/dev/null
    unset -f $(compgen -A function | grep "^_fac") 2>/dev/null
    unset -f $(compgen -A function | grep "^_factory") 2>/dev/null
    
    if [ -f "$MUX_ROOT/core.sh" ]; then
        source "$MUX_ROOT/core.sh"

        if command -v _mux_init &> /dev/null; then
            _mux_init
        fi
    fi

elif [ "$TARGET_SYSTEM" == "factory" ]; then
    if [ -z "$__MUX_CORE_ACTIVE" ]; then
        if [ -f "$MUX_ROOT/core.sh" ]; then
            source "$MUX_ROOT/core.sh"
            _mux_init
        fi
    fi
    
    if [ -f "$MUX_ROOT/factory.sh" ]; then
        source "$MUX_ROOT/factory.sh"
        
        if command -v _factory_system_boot &> /dev/null; then
            _factory_system_boot
        fi
    else
        echo "Error: Factory module not found at $MUX_ROOT/factory.sh"
        sleep 2
    fi
fi

