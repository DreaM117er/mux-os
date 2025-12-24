# system.sh - 系統基礎建設

function _sys_cmd() {
    local name="$1"
    local intent="$2"
    _require_no_args "${@:3}" || return 1
    _bot_say "system" "Configuring: $name"
    am start -a "$intent" >/dev/null 2>&1
}

# 瀏覽器網址搜尋引擎 - https://engine.com/search?q=
export SEARCH_GOOGLE="https://www.google.com/search?q="
export SEARCH_BING="https://www.bing.com/search?q="

export __GO_TARGET=""
export __GO_MODE=""

function _resolve_smart_url() {
    local search_engine="$1"
    local input="${*:2}"

    __GO_TARGET=""
    __GO_MODE="launch"

    if [[ "$input" == http* ]]; then
        __GO_TARGET="$input"
    
    elif echo "$input" | grep -P -q '[^\x00-\x7F]'; then
        __GO_TARGET="${search_engine}${input}"
        __GO_MODE="neural"

    elif [[ "$input" == *.* ]] && [[ "$input" != *" "* ]]; then
        __GO_TARGET="https://$input"
    
    else
        __GO_TARGET="${search_engine}${input}"
        __GO_MODE="neural"
    fi
}

# === System Tools ===

# : Termux Terminal
function termux() {
    _launch_android_app "Termux" "com.termux" "com.termux.app.TermuxActivity"
}

# : Show installed APKs
function apklist() {
    _require_no_args "$@" || return 1
    _launch_android_app "Package Names" "com.csdroid.pkg" "com.csdroid.pkg.MainActivity"
}

# : Default Web Browser (Neural Link)
function wb() {
    if [ -z "$1" ]; then
        _bot_say "neural" "Protocol: [VISUAL_INTERFACE_INIT]"
        am start -a android.intent.action.VIEW -d "about:blank" >/dev/null 2>&1
        return
    fi

    _resolve_smart_url "" "$@"

    if [ "$__GO_MODE" == "neural" ]; then
        _bot_say "neural" "Search Query: \"$*\""
    else
        _bot_say "launch" "Target Lock: $__GO_TARGET"
    fi

    am start -a android.intent.action.VIEW -d "$__GO_TARGET" >/dev/null 2>&1
}

# : AI Assistant (Voice Interface)
function ai() {
    _require_no_args "$@" || return 1
    am start -a android.intent.action.VOICE_COMMAND >/dev/null 2>&1
}

# : Console test (Debug)
function console() {
    _require_no_args "$@" || return 1
    _launch_android_app "Ghost App" "com.ghost.not.exist" ""
}


# === System Settings ===

# : Wi-Fi Settings
function wifi() {
    _sys_cmd "Wireless Module" "android.settings.WIFI_SETTINGS" "$@"
}

# : Bluetooth Settings
function ble() {
    _sys_cmd "Bluetooth Radio" "android.settings.BLUETOOTH_SETTINGS" "$@"
}

# : GPS Location
function gps() {
    _sys_cmd "Geo-Positioning" "android.settings.LOCATION_SOURCE_SETTINGS" "$@"
}

# : Sound & Vibration
function sound() {
    _sys_cmd "Audio Output" "android.settings.SOUND_SETTINGS" "$@"
}

# : Display Settings
function display() {
    _sys_cmd "Visual Interface" "android.settings.DISPLAY_SETTINGS" "$@"
}

# : Battery Info
function battery() {
    _sys_cmd "Power Core" "android.settings.BATTERY_SAVER_SETTINGS" "$@"
}

# : App Management
function apkinfo() {
    _sys_cmd "Package Manager" "android.settings.MANAGE_APPLICATIONS_SETTINGS" "$@"
}

# : Hotspot & Tethering
function hspot() {
    _sys_cmd "Tethering Uplink" "android.settings.TETHER_SETTINGS" "$@"
}

# : NFC Settings
function nfc() {
    _sys_cmd "Near Field Protocol" "android.settings.NFC_SETTINGS" "$@"
}

# : VPN Settings
function vpn() {
    _sys_cmd "Secure Tunnel" "android.settings.VPN_SETTINGS" "$@"
}

# : Airplane Mode
function apmode() {
    _sys_cmd "Radio Silence" "android.settings.AIRPLANE_MODE_SETTINGS" "$@"
}

# : Mobile Data
function mdata() {
    _sys_cmd "Cellular Link" "android.settings.DATA_ROAMING_SETTINGS" "$@"
}

# : Roaming Settings
function roam() {
    _sys_cmd "Roaming Protocols" "android.settings.DATA_ROAMING_SETTINGS" "$@"
}

# : Internal Storage
function storage() {
    _sys_cmd "Memory Banks" "android.settings.INTERNAL_STORAGE_SETTINGS" "$@"
}

# : Date & Time
function settime() {
    _sys_cmd "Chronometer" "android.settings.DATE_SETTINGS" "$@"
}

# : Input Method Editor
function ime() {
    _sys_cmd "Input Matrix" "android.settings.INPUT_METHOD_SETTINGS" "$@"
}

# : Keyboard Settings
function keyboard() {
    _sys_cmd "Input Matrix" "android.settings.INPUT_METHOD_SETTINGS" "$@"
}

# : Accessibility
function access() {
    _sys_cmd "Accessibility Layer" "android.settings.ACCESSIBILITY_SETTINGS" "$@"
}

# : Sync Settings
function account() {
    _sys_cmd "Identity Sync" "android.settings.SYNC_SETTINGS" "$@"
}

# : Developer Options
function dev() {
    _sys_cmd "Developer Override" "android.settings.APPLICATION_DEVELOPMENT_SETTINGS" "$@"
}
