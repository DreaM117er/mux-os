# system.sh - 系統基礎建設

function _sys_cmd() {
    local name="$1"
    local intent="$2"
    _require_no_args "${@:3}" || return 1
    _bot_say "system" "Configuring: $name"
    am start -a "$intent" >/dev/null 2>&1
}

# 定義網址搜尋引擎首頁 - https://engine/search?q=
export SEARCH_GOOGLE="https://www.google.com/search?q="
export SEARCH_BING="https://www.bing.com/search?q="

function _smart_browse() {
    local pkg_target="$1"
    local search_engine="$2"
    local input="${*:3}"

    local pkg_flag=""
    if [ "$pkg_target" != "wb" ] && [ -n "$pkg_target" ]; then
        pkg_flag="-p $pkg_target"
    fi

    if [ -z "$input" ]; then
        if [ -n "$pkg_flag" ]; then
            am start --user 0 $pkg_flag >/dev/null 2>&1
        else
            am start -a android.intent.action.VIEW -d "" >/dev/null 2>&1
        fi
        return
    fi

    local target_url=""
    local mode="launch"

    if [[ "$input" == http* ]]; then
        target_url="$input"
    elif echo "$input" | grep -P -q '[^\x00-\x7F]'; then
        target_url="${search_engine}${input}"
        mode="neural"
    elif [[ "$input" == *.* ]] && [[ "$input" != *" "* ]]; then
        target_url="https://$input"
    else
        target_url="${search_engine}${input}"
        mode="neural"
    fi

    if [ "$mode" == "neural" ]; then
        _bot_say "neural" "Search Query: \"$input\""
    else
        _bot_say "launch" "Target Lock: $target_url"
    fi

    am start -a android.intent.action.VIEW -d "$target_url" $pkg_flag >/dev/null 2>&1
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
    _smart_browse "wb" "$SEARCH_GOOGLE" "$@"
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
