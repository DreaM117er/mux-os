#!/bin/bash
# gate.sh - Mux-OS 星門啟動器

MUX_ROOT="$HOME/mux-os"
STATE_FILE="$MUX_ROOT/.mux_state"
TARGET_ARG="$1"

if [ -n "$TARGET_ARG" ]; then
    TARGET_SYSTEM="$TARGET_ARG"
    echo "$TARGET_SYSTEM" > "$STATE_FILE"
else
    if [ -f "$STATE_FILE" ]; then
        LAST_STATE=$(cat "$STATE_FILE")
        TARGET_SYSTEM=$(echo "$LAST_STATE" | tr -d '[:space:]')
    fi

    if [ -z "$TARGET_SYSTEM" ]; then
        TARGET_SYSTEM="core"
    fi
fi

if [ "$TARGET_SYSTEM" == "factory" ]; then
    THEME_COLOR="\033[1;38;5;208m"
    THEME_TEXT="NEURAL FORGE"
    ICON=""
else
    THEME_COLOR="\033[1;36m"
    THEME_TEXT="SYSTEM CORE"
    TARGET_SYSTEM="core"
    ICON=""
fi

C_TXT="\033[1;30m"
C_RESET="\033[0m"

if [ "$TERM" != "dumb" ]; then
    tput civis
    clear

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
        sleep 0.015 
    done
    sleep 0.2
    tput cnorm
    clear
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exec bash --noprofile --rcfile <(echo "source $HOME/.bashrc")
fi

source "$MUX_ROOT/core.sh"

if [ "$TARGET_SYSTEM" == "factory" ]; then
    if [ -f "$MUX_ROOT/factory.sh" ]; then
        source "$MUX_ROOT/factory.sh"
        if command -v _factory_system_boot &> /dev/null; then
            _factory_system_boot
        fi
    fi
fi