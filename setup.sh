#!/bin/bash
# setup.sh - Mux-OS 生命週期管理器 (Lifecycle Manager)

export __MUX_SETUP_ACTIVE=true

# 定義身份
SYSTEM_STATUS="OFFLINE"
COMMANDER_ID=""

# 定義路徑
MUX_ROOT="$HOME/mux-os"
RC_FILE="$HOME/.bashrc"
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
    echo -e " ${C_GRAY}:: Lifecycle Manager :: v3.6.0 ::${C_RESET}"
    echo ""
}

# 退出協議
function _exit_protocol() {
    echo ""
    echo -e "${C_GRAY}    ›› Operations complete. Returning to Core...${C_RESET}"
    sleep 0.5
    exec bash
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
    __MUX_CORE_ACTIVE=true bash "$MUX_ROOT/identity.sh"
    
    echo ""
    echo -e "${C_GREEN} :: Identity Matrix Updated.${C_RESET}"
    sleep 1
    
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
    echo -e "  ${C_GREEN}[+]${C_RESET} Dependencies    : git, ncurses-utils, termux-api"
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

    PACKAGES=(ncurses-utils git termux-api)
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
    BRAND=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]' | xargs)
    PLUGIN_DIR="$MUX_ROOT/plugins"
    VENDOR_TARGET="$MUX_ROOT/vendor.csv"
    
    if [ ! -d "$PLUGIN_DIR" ]; then mkdir -p "$PLUGIN_DIR"; fi

    case "$BRAND" in
        "redmi"|"poco") BRAND="xiaomi" ;;
        "rog"|"asus")   BRAND="asus" ;;
        "samsung")      BRAND="samsung" ;;
        *)              BRAND="${BRAND:-unknown}" ;;
    esac

    TARGET_PLUGIN="$PLUGIN_DIR/$BRAND.csv"
    if [ -f "$TARGET_PLUGIN" ]; then
        cp "$TARGET_PLUGIN" "$VENDOR_TARGET"
        echo "    ›› Vendor Identity: $BRAND (Module Loaded)"
    else
        echo '"CATNO","COMNO","CATNAME","TYPE","COM","COM2","COM3","HUDNAME","UINAME","PKG","TARGET","IHEAD","IBODY","URI","MIME","CATE","FLAG","EX","EXTRA","ENGINE"' > "$VENDOR_TARGET"
        echo "    ›› Vendor Identity: Generic (Standard Protocol)"
    fi
    chmod 644 "$VENDOR_TARGET"

    echo "    ›› Installing Bootloader..."

    sed -i '/# === Mux-OS Auto-Loader ===/d' "$RC_FILE"
    sed -i "\#source $MUX_ROOT/core.sh#d" "$RC_FILE"
    sed -i '/_mux_boot_sequence/d' "$RC_FILE"
    
    if ! grep -q "source $MUX_ROOT/core.sh" "$RC_FILE"; then
        echo "" >> "$RC_FILE"
        echo "# Mux-OS Core Uplink" >> "$RC_FILE"
        echo "if [ -f \"$MUX_ROOT/core.sh\" ]; then source \"$MUX_ROOT/core.sh\"; fi" >> "$RC_FILE"
        echo "    ›› Neural uplink established in .bashrc"
    else
        echo "    ›› Neural uplink already active."
    fi
    
    echo "    ›› Bootloader injected into $RC_FILE (v7.1.0 structure)"

    if [ ! -f "$MUX_ROOT/.mux_identity" ]; then
        echo ""
        echo -e "${C_YELLOW} :: Initializing Identity Protocol...${C_RESET}"
        sleep 1
        __MUX_CORE_ACTIVE=true bash "$MUX_ROOT/identity.sh"
    fi

    echo ""
    echo -e "${C_GREEN} :: System Ready. Returning to Core...${C_RESET}"
    sleep 1
    
    cat > "$MUX_ROOT/.mux_state" <<EOF
MUX_MODE="MUX"
MUX_STATUS="LOCKED"
EOF

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
    echo -e "  ${C_YELLOW}[!]${C_RESET} Note            : Dependencies (git, fzf) will be KEPT."
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
        sed -i '/# === Mux-OS Auto-Loader ===/d' "$RC_FILE"
        sed -i "\#source $MUX_ROOT/core.sh#d" "$RC_FILE"
        echo "    ›› Bootloader removed."
    fi

    if [ -d "$MUX_ROOT" ]; then
        unset -f mux _bot_say _mux_init 2>/dev/null
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
    echo ""
    echo " [1] Repair / Reinstall (Update)"
    echo " [2] Reset Identity (Re-auth)"
    echo " [3] Uninstall (Self-Destruct)"
    echo " [4] Cancel (Reload Core)"
    echo ""
    echo -ne "${C_CYAN} :: Select Protocol [1-4]: ${C_RESET}"
    read choice

    case "$choice" in
        1) _install_protocol ;;
        2) _reauth_protocol ;;
        3) _uninstall_protocol ;;
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