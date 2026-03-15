#!/bin/bash
# setup.sh - Mux-OS 生命週期管理器 (Lifecycle Manager)

if [ -f "$HOME/.mux_panic" ]; then
    echo "Panic mode active. Mux-OS bypassed."
    return 0
fi

export __MUX_SETUP_ACTIVE=true

# 定義身份
SYSTEM_STATUS="OFFLINE"
COMMANDER_ID=""

# 定義路徑
MUX_ROOT="$HOME/mux-os"
RC_FILE="$HOME/.bashrc"
SOUL_VAULT="$HOME/.bakmuxid"
BACKUP_DIR="$HOME/mux-os_backup_$(date +%Y%m%d_%H%M%S)"

# 定義顏色
C_RESET="\033[0m"
C_CYAN="\033[1;36m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_GRAY="\033[1;30m"

# 讀取身份檔案
if [ -f "$MUX_ROOT/.mux_identity" ]; then
    SYSTEM_STATUS="ONLINE"
    source "$MUX_ROOT/.mux_identity" 2>/dev/null
    COMMANDER_ID="$MUX_ID"
else
    SYSTEM_STATUS="OFFLINE"
    COMMANDER_ID="Unknown"
fi

# 狀態機探測與繼承
CURRENT_MODE="MUX"
CURRENT_STATUS="DEFAULT"
if [ -f "$MUX_ROOT/.mux_state" ]; then
    source "$MUX_ROOT/.mux_state" 2>/dev/null
    [ -n "$MUX_MODE" ] && CURRENT_MODE="$MUX_MODE"
    [ -n "$MUX_STATUS" ] && CURRENT_STATUS="$MUX_STATUS"
fi


# 輔助函式：Banner
function _banner() {
    clear
    echo -e "${C_GRAY}"
    cat << "EOF"
  __  __                  ___  ____  
 |  \/  |_   ___  __     / _ \/ ___| 
 | |\/| | | | \ \/ /____| | | \___ \ 
 | |  | | |_| |>  <_____| |_| |___) |
 |_|  |_|\__,_/_/\_\     \___/|____/ 
EOF
    echo -e "${C_RESET}"
    echo -e " ${C_GRAY}:: Lifecycle Manager :: vL.2.D ::${C_RESET}"
    echo ""
}

# 退出協議
function _exit_protocol() {
    echo ""
    echo -e "${C_GRAY}    ›› Operations complete. Returning to Core...${C_RESET}"
    sleep 0.5
    exec bash
}

# 靈魂傳輸協議
function _restore_identity_protocol() {
    if [ ! -d "$SOUL_VAULT" ] || [ -z "$(ls -A "$SOUL_VAULT"/.muxid_* 2>/dev/null)" ]; then
        return 1 # 找不到前世記憶
    fi

    echo ""
    echo -e "${C_CYAN} :: Archived Identity Matrices detected in Soul Vault.${C_RESET}"
    echo -ne "${C_YELLOW} :: Initiate Soul Transfer (Restore)? [Y/n]: ${C_RESET}"
    read r_choice
    if [[ "$r_choice" == "y" || "$r_choice" == "Y" || "$r_choice" == "" ]]; then
        echo -e "${C_GRAY}    ›› Select Identity to restore:${C_RESET}"
        local i=1
        local files=()
        # 依照時間排序，最新的在最上面
        for f in $(ls -1t "$SOUL_VAULT"/.muxid_*); do
            files[$i]="$f"
            echo -e "    [$i] $(basename "$f")"
            ((i++))
        done
        echo -ne "${C_CYAN}    ›› Choice: ${C_RESET}"
        read id_choice
        if [[ "$id_choice" =~ ^[1-3]$ ]] && [ -n "${files[$id_choice]}" ]; then
            cp "${files[$id_choice]}" "$MUX_ROOT/.mux_identity"
            echo -e "${C_GREEN}    ›› Soul Transfer Complete. Welcome back.${C_RESET}"
            sleep 1
            return 0 # 成功轉生
        else
            echo -e "${C_RED}    ›› Invalid selection. Transfer aborted.${C_RESET}"
            return 1
        fi
    fi
    return 1 # 創造新生命
}

# 身份重置協議
function _reauth_protocol() {
    echo ""
    echo -e "${C_YELLOW} :: Identity Reset Sequence Initiated...${C_RESET}"
    echo -e "${C_GRAY}    Current Signature: $COMMANDER_ID${C_RESET}"
    echo ""
    
    if [ -f "$MUX_ROOT/.mux_identity" ]; then
        rm "$MUX_ROOT/.mux_identity"
        echo -e "${C_RED}    ›› Old identity purged.${C_RESET}"
    fi
    
    sleep 1
    if ! _restore_identity_protocol; then
        __MUX_CORE_ACTIVE=true bash "$MUX_ROOT/identity.sh"
    fi
    
    echo ""
    echo -e "${C_GREEN} :: Identity Matrix Updated.${C_RESET}"
    sleep 1
    
    _exit_protocol
}

# 身份備份協議
function _backup_identity_protocol() {
    echo ""
    echo -e "${C_YELLOW} :: Identity Backup Sequence Initiated...${C_RESET}"
    
    if [ ! -d "$SOUL_VAULT" ]; then mkdir -p "$SOUL_VAULT"; fi
    
    if [ ! -f "$MUX_ROOT/.mux_identity" ]; then
        echo -e "${C_RED}    ›› Error: No Identity Matrix found to backup.${C_RESET}"
        sleep 2
        _exit_protocol
    fi

    # 檢查記憶插槽數量
    local count=$(ls -1 "$SOUL_VAULT"/.muxid_* 2>/dev/null | wc -l)
    local target_file="$SOUL_VAULT/.muxid_$(date +%Y%m%d%H%M%S)"

    if [ "$count" -ge 3 ]; then
        echo -e "${C_RED}    ›› Memory slots full (Max 3). Select a matrix to overwrite:${C_RESET}"
        local i=1
        local files=()
        for f in $(ls -1t "$SOUL_VAULT"/.muxid_*); do
            files[$i]="$f"
            echo -e "    [$i] $(basename "$f")"
            ((i++))
        done
        echo -e "    [c] Cancel"
        echo -ne "${C_CYAN}    ›› Choice: ${C_RESET}"
        read b_choice
        if [[ "$b_choice" =~ ^[1-3]$ ]] && [ -n "${files[$b_choice]}" ]; then
            rm "${files[$b_choice]}"
            echo -e "${C_GRAY}    ›› Old matrix purged.${C_RESET}"
        else
            echo -e "${C_GRAY}    ›› Backup aborted.${C_RESET}"
            sleep 1
            _exit_protocol
        fi
    fi

    cp "$MUX_ROOT/.mux_identity" "$target_file"
    echo -e "${C_GREEN}    ›› Identity Matrix safely cloned to Soul Vault:${C_RESET}"
    echo -e "${C_GRAY}       $(basename "$target_file")${C_RESET}"
    
    sleep 2
    _exit_protocol
}

# 安裝協議
function _install_protocol() {
    local cols=$(tput cols)
    if [ "$cols" -lt 50 ]; then
        clear
        echo -e "${C_CYAN} :: Mux-OS Lifecycle Manager ::${C_RESET}\n"
    else
        _banner
    fi
    echo -e "${C_YELLOW} :: Initialize System Construction?${C_RESET}"
    echo ""

    echo -e "${C_CYAN} [Manifest Preview]${C_RESET}"
    echo -e "  ${C_GREEN}[+]${C_RESET} Core Logic      : $MUX_ROOT/core.sh"
    echo -e "  ${C_GREEN}[+]${C_RESET} Visual Module   : $MUX_ROOT/ui.sh"
    echo -e "  ${C_GREEN}[+]${C_RESET} Neural Link     : $MUX_ROOT/bot.sh"
    echo -e "  ${C_GREEN}[+]${C_RESET} System Apps     : $MUX_ROOT/app.sh"
    echo -e "  ${C_GREEN}[+]${C_RESET} Bootloader      : $RC_FILE (Append)"
    echo -e "  ${C_GREEN}[+]${C_RESET} Dependencies    : git, ncurses-utils, termux-api, gh"
    echo ""

    echo -ne "${C_GREEN} :: Proceed with installation? [Y/n]: ${C_RESET}"
    read choice
    if [[ "$choice" != "y" && "$choice" != "Y" && "$choice" != "" ]]; then
        echo -e "${C_GRAY}    ›› Construction canceled.${C_RESET}"
        if [ "$SYSTEM_STATUS" == "ONLINE" ]; then
            _exit_protocol
        else
            exit 0
        fi
    fi

    echo ""
    echo -e "${C_YELLOW} :: Executing Protocol...${C_RESET}"

    PACKAGES=(ncurses-utils git termux-api gh)
    for pkg in "${PACKAGES[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            echo "    ›› Installing missing gear: $pkg"
            pkg install "$pkg" -y
        fi
    done

    echo -e "${C_YELLOW} :: Synchronizing Neural Core...${C_RESET}"
    
    REPO_URL="https://github.com/DreaM117er/mux-os"
    
    if [ ! -d "$MUX_ROOT/.git" ]; then
        echo "    ›› Cloning from Origin..."
        if [ -d "$MUX_ROOT" ]; then
            mv "$MUX_ROOT" "${MUX_ROOT}_bak_$(date +%s)"
        fi
        git clone "$REPO_URL" "$MUX_ROOT"
    else
        echo "    ›› Forcing Timeline Sync (Repair)..."
        cd "$MUX_ROOT"
        git fetch --all
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
        git reset --hard "origin/$branch"
    fi

    chmod +x "$MUX_ROOT/"*.sh

    echo "    ›› Calibrating Vendor Ecosystem..."
    # 定義絕對的 vendor.csv 及 plugins
    RAW_BRAND=$(getprop ro.product.brand 2>/dev/null | tr '[:upper:]' '[:lower:]' | xargs)
    
    case "$RAW_BRAND" in
        "redmi"|"poco"|"blackshark") BRAND="xiaomi" ;;
        "rog")                       BRAND="asus" ;;
        *)                           BRAND="${RAW_BRAND:-unknown}" ;;
    esac

    PLUGIN_DIR="$MUX_ROOT/plugins"
    VENDOR_TARGET="$MUX_ROOT/vendor.csv"
    
    [ ! -d "$PLUGIN_DIR" ] && mkdir -p "$PLUGIN_DIR"

    MATCHED_PLUGIN=""
    if [ -n "$(ls -A "$PLUGIN_DIR"/*.csv 2>/dev/null)" ]; then
        for plugin in "$PLUGIN_DIR"/*.csv; do
            plugin_name=$(basename "$plugin" .csv)
            if [ "$plugin_name" == "$BRAND" ] || [ "$plugin_name" == "$RAW_BRAND" ]; then
                MATCHED_PLUGIN="$plugin"
                break
            fi
        done
    fi

    if [ -n "$MATCHED_PLUGIN" ]; then
        cp "$MATCHED_PLUGIN" "$VENDOR_TARGET"
        echo "    ›› Vendor Identity: $BRAND (Dynamic Module Loaded)"
    else
        echo '"CATNO","COMNO","CATNAME","TYPE","COM","COM2","COM3","HUDNAME","UINAME","PKG","TARGET","IHEAD","IBODY","URI","MIME","CATE1","CATE2","CATE3","FLAG","EX1","EXTRA1","BOOLEN1","EX2","EXTRA2","BOOLEN2","EX3","EXTRA3","BOOLEN3","EX4","EXTRA4","BOOLEN4","EX5","EXTRA5","BOOLEN5","ENGINE"' > "$VENDOR_TARGET"
        if [ "$BRAND" != "unknown" ]; then
            echo "    ›› Vendor Identity: $BRAND (Generic Protocol Fallback)"
        else
            echo "    ›› Vendor Identity: Generic (Standard Protocol)"
        fi
    fi
    chmod 644 "$VENDOR_TARGET"

    echo "    ›› Installing Bootloader..."

    # 重要！定義注入區塊
    if [ -f "$RC_FILE" ]; then
        sed -i '/# Mux-OS Core Uplink/d' "$RC_FILE"
        sed -i '\#\[ -f "$HOME/mux-os/core.sh" \] && source "$HOME/mux-os/core.sh"#d' "$RC_FILE"
        sed -i '/# === Mux-OS Auto-Loader ===/d' "$RC_FILE"
    else
        touch "$RC_FILE"
    fi

    BLOCK_START="# >>> Mux-OS Init >>>"
    BLOCK_END="# <<< Mux-OS Init <<<"

    if grep -qF "$BLOCK_START" "$RC_FILE"; then
        sed -i "/$BLOCK_START/,/$BLOCK_END/d" "$RC_FILE"
    fi

    cat << EOF >> "$RC_FILE"
$BLOCK_START
# Mux-OS Core Uplink
[ -f "\$HOME/mux-os/core.sh" ] && source "\$HOME/mux-os/core.sh"
$BLOCK_END
EOF
    
    echo "    ›› Bootloader injected into $RC_FILE."

    local current_id=""
    if [ -f "$MUX_ROOT/.mux_identity" ]; then
        current_id=$(grep "MUX_ID=" "$MUX_ROOT/.mux_identity" | cut -d'=' -f2 | tr -d '"')
    fi

    if [ ! -f "$MUX_ROOT/.mux_identity" ] || [ "$current_id" == "Unknown" ]; then
        # 探測是否有前世記憶
        if ! _restore_identity_protocol; then
            echo ""
            echo -e "${C_YELLOW} :: Initializing Identity Protocol...${C_RESET}"
            sleep 1
            __MUX_CORE_ACTIVE=true bash "$MUX_ROOT/identity.sh"
        fi
    fi

    echo ""
    echo -e "${C_GREEN} :: System Ready. Returning to Core...${C_RESET}"
    sleep 1
    
    # 狀態機偵測及寫入
    if [ "$SYSTEM_STATUS" != "ONLINE" ] || [ ! -f "$MUX_ROOT/.mux_state" ]; then
        # 全新安裝
        cat > "$MUX_ROOT/.mux_state" <<EOF
MUX_MODE="MUX"
MUX_STATUS="DEFAULT"
EOF
    else
        # 修復更新
        if [[ "$CURRENT_MODE" == "XUM" || "$CURRENT_MODE" == "FAC"  || "$CURRENT_MODE" == "TCT" ]]; then
            CURRENT_STATUS="LOGIN"
        fi

        if ! grep -q "^MUX_MODE=" "$MUX_ROOT/.mux_state"; then echo "MUX_MODE=\"\"" >> "$MUX_ROOT/.mux_state"; fi
        if ! grep -q "^MUX_STATUS=" "$MUX_ROOT/.mux_state"; then echo "MUX_STATUS=\"\"" >> "$MUX_ROOT/.mux_state"; fi
        
        sed -i "s/^MUX_MODE=.*/MUX_MODE=\"$CURRENT_MODE\"/" "$MUX_ROOT/.mux_state"
        sed -i "s/^MUX_STATUS=.*/MUX_STATUS=\"$CURRENT_STATUS\"/" "$MUX_ROOT/.mux_state"
    fi

    unset MUX_INITIALIZED
    exec bash
}

# 卸載協議
function _uninstall_protocol() {
    _banner
    echo -e "${C_RED} :: WARNING: Self-Destruct Sequence Requested.${C_RESET}"
    echo -e "${C_GRAY}    This action will permanently remove Mux-OS from this terminal.${C_RESET}"
    echo ""

    echo -e "${C_RED} [Destruction Manifest]${C_RESET}"
    echo -e "  ${C_RED}[-]${C_RESET} System Core     : $MUX_ROOT (All files)"
    echo -e "  ${C_RED}[-]${C_RESET} Bootloader      : Cleaning $RC_FILE"
    echo -e "  ${C_YELLOW}[!]${C_RESET} Note            : Dependencies (git, gh, fzf) will be KEPT."
    echo ""

    echo -ne "${C_RED} :: To confirm, type 'CONFIRM' (all caps): ${C_RESET}"
    read input
    
    if [ "$input" != "CONFIRM" ]; then
        echo -e "${C_GREEN} :: Safety lock engaged. Aborting destruction.${C_RESET}"
        _exit_protocol
    fi

    echo ""
    echo -e "${C_YELLOW} :: Initiating Purge...${C_RESET}"
    sleep 1

    if [ -f "$RC_FILE" ]; then
        BLOCK_START="# >>> Mux-OS Init >>>"
        BLOCK_END="# <<< Mux-OS Init <<<"
        if grep -qF "$BLOCK_START" "$RC_FILE"; then
            sed -i "/$BLOCK_START/,/$BLOCK_END/d" "$RC_FILE"
        fi

        sed -i '/# === Mux-OS Auto-Loader ===/d' "$RC_FILE"
        sed -i '/# Mux-OS Core Uplink/d' "$RC_FILE"
        sed -i '\#source '"$MUX_ROOT"'/core.sh#d' "$RC_FILE"
        sed -i '\#\[ -f "$HOME/mux-os/core.sh" \] && source "$HOME/mux-os/core.sh"#d' "$RC_FILE"

        echo "    ›› Bootloader removed."
    fi

    if [ -d "$MUX_ROOT" ]; then
        unset -f mux _bot_say _mux_init 2>/dev/null
        cd ~ 2>/dev/null || cd /
        rm -rf "$MUX_ROOT"
        echo "    ›› Core files vaporized."
    fi

    echo ""
    echo -e "${C_RED} :: System Purged. Connection Lost.${C_RESET}"
    echo -e "${C_GRAY}    (Restart Termux to clear residual memory states)${C_RESET}"
    exit 0
}

_banner

if [ "$SYSTEM_STATUS" == "ONLINE" ]; then
    echo -e "${C_CYAN} :: System Status: ${C_GREEN}ONLINE${C_RESET} ${C_GRAY}(Commander: $COMMANDER_ID)${C_RESET}"
    echo -e "${C_CYAN} :: Active Dimension: ${C_YELLOW}$CURRENT_MODE${C_RESET}"
    echo ""
    echo " [1] Repair / Reinstall (Update)"
    echo " [2] Reset Identity (Re-auth)"
    echo " [3] Backup Identity (Export)"
    echo " [4] Uninstall (Self-Destruct)"
    echo " [5] Cancel (Reload Core)"
    echo ""
    echo -ne "${C_CYAN} :: Select Protocol [1-5]: ${C_RESET}"
    read choice

    case "$choice" in
        1) _install_protocol ;;
        2) _reauth_protocol ;;
        3) _backup_identity_protocol ;;
        4) _uninstall_protocol ;;
        *) _exit_protocol ;;
    esac

else
    echo -e "${C_CYAN} :: System Status: ${C_RED}OFFLINE${C_RESET}"
    echo ""
    echo " [1] Install"
    echo " [2] Delete (All Mux-OS Data)"
    echo " [3] Cancel"
    echo ""
    echo -ne "${C_CYAN} :: Select Protocol [1-3]: ${C_RESET}"
    read choice

    case "$choice" in
        1) _install_protocol ;;
        2) _uninstall_protocol ;;
        *) 
           echo "    ›› Standing by."
           exit 0 
           ;;
    esac
fi