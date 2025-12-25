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

# : Samsung Reminder
function remind() {
    _require_no_args "$@" || return 1
    _launch_android_app "Reminder" "com.samsung.android.app.reminder" "com.samsung.android.app.reminder.ui.LaunchMainActivity"
}

# : Galaxy Store
function store() {
    _require_no_args "$@" || return 1
    _launch_android_app "Galaxy Store" "com.sec.android.app.samsungapps" "com.sec.android.app.samsungapps.SamsungAppsMainActivity"
}

# : Samsung Weather
function weather() {
    _require_no_args "$@" || return 1
    _launch_android_app "Weather" "com.sec.android.daemonapp" "com.sec.android.daemonapp.app.MainActivity"
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
function member() {
    _require_no_args "$@" || return 1
    _launch_android_app "Members" "com.samsung.android.voc" "com.samsung.android.voc.LauncherActivity"
}


# === Samsung Media ===

# : Samsung Video Player
function video() {
    _require_no_args "$@" || return 1
    _launch_android_app "Video Player" "com.samsung.android.video" "com.samsung.android.video.player.activity.MoviePlayer"
}

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
    if [ "$1" == "cli" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local filename="/sdcard/mux_rec_${timestamp}.mp4"
        
        _bot_say "system" "Initializing Native Capture Protocol..."
        echo -e "\033[1;31m🔴 Recording... Press Ctrl+C to stop.\033[0m"
        
        /system/bin/screenrecord --time-limit 180 --verbose "$filename"
        
        echo ""
        _bot_say "success" "Footage saved: $filename"
        
        am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://$filename" >/dev/null 2>&1
        return
    fi

    _bot_say "system" "Accessing Recorder Configuration..."
    
    am start -a android.intent.action.MAIN \
             -n com.samsung.android.app.smartcapture/com.samsung.android.app.smartcapture.setting.SmartCaptureSettingsActivity >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        _bot_say "neural" "Config uplink established. Manual trigger required."
    else
        _bot_say "error" "Uplink blocked. System UI restriction active."
        echo " > Tip: Use 'rec cli' for direct silent recording."
    fi
}