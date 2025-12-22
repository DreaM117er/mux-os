# samsung.sh - 三星全家桶

# === Samsung Life ===

# : Samsung Health
function health() {
    _launch_android_app "Samsung Health" "com.sec.android.app.shealth" "com.samsung.android.app.shealth.home.HomeMainActivity"
}

# : Samsung Wallet (Pay)
function wallet() {
    _launch_android_app "Samsung Wallet" "com.samsung.android.spay" "com.samsung.android.spay.ui.SpayMainActivity"
}

# : Samsung Members
function members() {
    _launch_android_app "Members" "com.samsung.android.voc" "com.samsung.android.voc.LauncherActivity"
}

# : Samsung Kids
function kids() {
    _launch_android_app "Samsung Kids" "com.sec.android.app.kidshome" ""
}

# === Samsung Media ===

# : Samsung Music
function music() {
    _launch_android_app "Samsung Music" "com.sec.android.app.music" "com.sec.android.app.music.common.activity.MusicMainActivity"
}

# : Samsung News
function news() {
    _launch_android_app "Samsung News" "com.samsung.android.app.spage" "com.samsung.android.app.spage.main.LauncherActivity"
}

# === Devices & IoT ===

# : SmartThings
function st() {
    _launch_android_app "SmartThings" "com.samsung.android.oneconnect" "com.samsung.android.oneconnect.ui.SCMainActivity"
}

# : Galaxy Wearable
function wear() {
    _launch_android_app "Galaxy Wearable" "com.samsung.android.app.watchmanager" "com.samsung.android.app.watchmanager.setupwizard.SetupWizardWelcomeActivity"
}

# : Smart Tutor (Remote Support)
function tutor() {
    _launch_android_app "Smart Tutor" "com.rsupport.rs.activity.rsupport.aas2" "com.rsupport.rs.activity.edit.IntroActivity"
}

# === Productivity ===

# : Samsung Notes
function notes() {
    _launch_android_app "Samsung Notes" "com.samsung.android.app.notes" "com.samsung.android.app.notes.memolist.MemoListActivity"
}