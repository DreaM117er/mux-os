# system.sh - 系統基礎建設

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

# : Console test (Debug)
function console() {
    _require_no_args "$@" || return 1
    _launch_android_app "Ghost App" "com.ghost.not.exist" ""
}

# === System Settings ===

# : Wi-Fi Settings
function wifi() {
    _require_no_args "$@" || return 1
    am start -a android.settings.WIFI_SETTINGS >/dev/null 2>&1
}

# : Bluetooth Settings
function ble() {
    _require_no_args "$@" || return 1
    am start -a android.settings.BLUETOOTH_SETTINGS >/dev/null 2>&1
}

# : GPS
function gps() {
    _require_no_args "$@" || return 1
    am start -a android.settings.LOCATION_SOURCE_SETTINGS >/dev/null 2>&1
}

# : Sound & Vibration
function sound() {
    _require_no_args "$@" || return 1
    am start -a android.settings.SOUND_SETTINGS >/dev/null 2>&1
}

# : Display Settings
function display() {
    _require_no_args "$@" || return 1
    am start -a android.settings.DISPLAY_SETTINGS >/dev/null 2>&1
}

# : Battery Info
function battery() {
    _require_no_args "$@" || return 1
    am start -a android.settings.BATTERY_SAVER_SETTINGS >/dev/null 2>&1
}

# : App Management
function apkinfo() {
    _require_no_args "$@" || return 1
    am start -a android.settings.MANAGE_APPLICATIONS_SETTINGS >/dev/null 2>&1
}

# : Hotspot & Tethering
function hspot() {
    _require_no_args "$@" || return 1
    am start -a android.settings.TETHER_SETTINGS >/dev/null 2>&1
}

# : NFC
function nfc() {
    _require_no_args "$@" || return 1
    am start -a android.settings.NFC_SETTINGS >/dev/null 2>&1
}

# : VPN 
function vpn() {
    _require_no_args "$@" || return 1
    am start -a android.settings.VPN_SETTINGS >/dev/null 2>&1
}

# : Airplane Mode
function apmode() {
    _require_no_args "$@" || return 1
    am start -a android.settings.AIRPLANE_MODE_SETTINGS >/dev/null 2>&1
}

# : Mobile Data / Roaming
function mdata() {
    _require_no_args "$@" || return 1
    am start -a android.settings.DATA_ROAMING_SETTINGS >/dev/null 2>&1
}

function roam() {
    _require_no_args "$@" || return 1
    am start -a android.settings.DATA_ROAMING_SETTINGS >/dev/null 2>&1
}

# : Storage
function storage() {
    _require_no_args "$@" || return 1
    am start -a android.settings.INTERNAL_STORAGE_SETTINGS >/dev/null 2>&1
}

# : Date & Time
function settime() {
    _require_no_args "$@" || return 1
    am start -a android.settings.DATE_SETTINGS >/dev/null 2>&1
}

# : Input Method Editor
function ime() {
    _require_no_args "$@" || return 1
    am start -a android.settings.INPUT_METHOD_SETTINGS >/dev/null 2>&1
}

function keyboard() {
    _require_no_args "$@" || return 1
    am start -a android.settings.INPUT_METHOD_SETTINGS >/dev/null 2>&1
}

# : Accessibility
function access() {
    _require_no_args "$@" || return 1
    am start -a android.settings.ACCESSIBILITY_SETTINGS >/dev/null 2>&1
}

# : Sync Settings
function account() {
    _require_no_args "$@" || return 1
    am start -a android.settings.SYNC_SETTINGS >/dev/null 2>&1
}

# : Developer Options
function dev() {
    _require_no_args "$@" || return 1
    am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS >/dev/null 2>&1
}