# samsung.sh - 三星全家桶

# === Samsung Utilities ===

# : My Files
function files() {
    _require_no_args "$@" || return 1
    _launch_android_app "My Files" "com.sec.android.app.myfiles" "com.sec.android.app.myfiles.ui.MainActivity"
}

# : Samsung Clock
function clock() {
    _require_no_args "$@" || return 1
    _launch_android_app "Clock" "com.sec.android.app.clockpackage" "com.sec.android.app.clockpackage.ClockPackage"
}

# : Samsung Calendar
function calendar() {
    _require_no_args "$@" || return 1
    _launch_android_app "Calendar" "com.samsung.android.calendar" "com.samsung.android.app.calendar.activity.MainActivity"
}


# === Samsung Life ===

# : Samsung Health
function health() {
    _require_no_args "$@" || return 1
    _launch_android_app "Samsung Health" "com.sec.android.app.shealth" "com.samsung.android.app.shealth.home.HomeMainActivity"
}

# : Samsung Wallet (Pay)
function wallet() {
    _require_no_args "$@" || return 1
    _launch_android_app "Samsung Wallet" "com.samsung.android.spay" "com.samsung.android.spay.ui.SpayMainActivity"
}

# : Samsung Members
function members() {
    _require_no_args "$@" || return 1
    _launch_android_app "Members" "com.samsung.android.voc" "com.samsung.android.voc.LauncherActivity"
}


# === Samsung Media ===

# : Samsung Music
function music() {
    _require_no_args "$@" || return 1
    _launch_android_app "Samsung Music" "com.sec.android.app.music" "com.sec.android.app.music.common.activity.MusicMainActivity"
}

# : Samsung News
function news() {
    _require_no_args "$@" || return 1
    _launch_android_app "Samsung News" "com.samsung.android.app.spage" "com.samsung.android.app.spage.main.LauncherActivity"
}

# : Samsung Gaming Hub
function gamehub() {
    _require_no_args "$@" || return 1
    _launch_android_app "Gaming Hub" "com.samsung.android.game.gamehome" "com.samsung.android.game.gamehome.app.MainActivity"
}


# === Devices & IoT ===

# : SmartThings
function st() {
    _require_no_args "$@" || return 1
    _launch_android_app "SmartThings" "com.samsung.android.oneconnect" "com.samsung.android.oneconnect.ui.SCMainActivity"
}

# : Galaxy Wearable
function wear() {
    _require_no_args "$@" || return 1
    _launch_android_app "Galaxy Wearable" "com.samsung.android.app.watchmanager" "com.samsung.android.app.watchmanager.setupwizard.SetupWizardWelcomeActivity"
}

# : Smart Tutor (Remote Support)
function tutor() {
    _require_no_args "$@" || return 1
    _launch_android_app "Smart Tutor" "com.rsupport.rs.activity.rsupport.aas2" "com.rsupport.rs.activity.edit.IntroActivity"
}


# === Productivity ===

# : Samsung Notes
function notes() {
    _require_no_args "$@" || return 1
    _launch_android_app "Samsung Notes" "com.samsung.android.app.notes" "com.samsung.android.app.notes.memolist.MemoListActivity"
}


# === Samsung Tools ===

# : Screen Recorder
function rec() {
    _require_no_args "$@" || return 1
    _bot_say "system" "Initializing Screen Recorder..."

    am start -n com.samsung.android.app.screenrecorder/com.samsung.android.app.screenrecorder.ScreenRecorderActivity >/dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        _bot_say "warn" "Direct launch failed. Opening Quick Settings."
        cmd statusbar expand-settings
    fi
}