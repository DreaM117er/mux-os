# app.sh - 個人應用生態系

# === Network & Cloud ===

# : Edge & Bing search
function edge() {
    if [ -z "$1" ]; then
        _launch_android_app "Edge" "com.microsoft.emmx" "com.microsoft.ruby.Main"
    else
        local query="$*"
        query="${query// /+}"
        echo " > Edge Bing Search: $*"
        am start -a android.intent.action.VIEW \
            -d "https://www.bing.com/search?q=$query" \
            -p com.microsoft.emmx >/dev/null 2>&1
    fi
}

# : Mega Sync
function mega() {
    _require_no_args "$@" || return 1
    _launch_android_app "Mega" "mega.privacy.android.app" "mega.privacy.android.app.main.ManagerActivity"
}

# === Google Suite ===

# : Google Play Store & Search
function play() {
    if [ -z "$1" ]; then
        _launch_android_app "Play Store" "com.android.vending" "com.android.vending.AssetBrowserActivity"
    else
        local query="$*"
        query="${query// /+}"
        
        echo " > Searching Play Store for: $*"
        am start -a android.intent.action.VIEW \
            -d "market://search?q=$query" \
            -p com.android.vending >/dev/null 2>&1
    fi
}

# : Google app Search
function google() {
    if [ -z "$1" ]; then
        echo " > Please input search keywords. (e.g., google Termux)"
        return 1
    fi
    
    local query="$*"
    echo " > Google App Search: $*"
    am start -a android.intent.action.WEB_SEARCH \
        -p com.google.android.googlequicksearchbox \
        -e query "$query" >/dev/null 2>&1
}

# : Gmail
function gmail() {
    _require_no_args "$@" || return 1
    _launch_android_app "Gmail" "com.google.android.gm" "com.google.android.gm.ConversationListActivityGmail"
}

# : Google Drive
function gdrive() {
    _require_no_args "$@" || return 1
    _launch_android_app "Google Drive" "com.google.android.apps.docs" "com.google.android.apps.docs.app.NewMainProxyActivity"
}

# : Google Meet
function meet() {
    _require_no_args "$@" || return 1
    _launch_android_app "Meet" "com.google.android.apps.tachyon" "com.google.android.apps.tachyon.MainActivity"
}

# : Google Gemini AI
function gemini() {
    _require_no_args "$@" || return 1
    _launch_android_app "Gemini" "com.google.android.apps.bard" "com.google.android.apps.bard.shellapp.BardEntryPointActivity"
}


# === Maps & Nav ===

# : Google Map
function map() {
    _require_no_args "$@" || return 1
    _launch_android_app "Google Maps" "com.google.android.apps.maps" "com.google.android.maps.MapsActivity"
}

# : Map to location or keywords
function mapto() {
    if [ -z "$1" ]; then
        echo " > Please input location or keywords to search on map. (e.g., mapto Taipei 101)"
        return 1
    fi
    
    local query="$*"
    query="${query// /+}"
    echo " > Map search keywords: $*"
    am start -a android.intent.action.VIEW -d "geo:0,0?q=$query" >/dev/null 2>&1
}

# : Plan route to location or keywords
function mapway() {
    if [ -z "$1" ]; then
        echo " > Please input destination. (e.g., mapway Taipei Main Station)"
        return 1
    fi
    local query="$*"
    query="${query// /+}"
    echo " > Planning route to: $*"
    am start -a android.intent.action.VIEW -d "https://maps.google.com/maps?daddr=$query" >/dev/null 2>&1
}

# : Navigate to location or keywords
function mapgo() {
    if [ -z "$1" ]; then
        echo " > Please input destination or keywords (e.g., togo company, togo \"nearest MRT station\")"
        return 1
    fi
    
    local query="$*"
    query="${query// /+}"
    echo " > Start to go to: $*"
    am start -a android.intent.action.VIEW -d "google.navigation:q=$query" >/dev/null 2>&1
}


# === Office ===

# : Microsoft 365 Copilot
function ms365() {
    _require_no_args "$@" || return 1
    _launch_android_app "M365 Copilot" "com.microsoft.office.officehubrow" "com.microsoft.office.officesuite.OfficeSuiteActivity"
}

# === Engineering ===

# : GitHub
function github() {
    _require_no_args "$@" || return 1
    _launch_android_app "GitHub" "com.github.android" "com.github.android.main.MainActivity"
}

# : Autodesk Fusion
function fusion() {
    _require_no_args "$@" || return 1
    _launch_android_app "Fusion" "com.autodesk.fusion" "com.autodesk.a360.ui.activities.launcher.A360LauncherActivity"
}

# : Onshape CAD
function onshape() {
    _require_no_args "$@" || return 1
    _launch_android_app "Onshape" "com.onshape.app" "com.belmonttech.app.activities.BTSplashActivity"
}

# : JLCPCB
function jlc() {
    _require_no_args "$@" || return 1
    _launch_android_app "JLCPCB" "com.jlcpcb.m" "io.dcloud.PandoraEntry"
}


# === Communication ===

# : Google Phone
function phone() {
    _require_no_args "$@" || return 1
    _launch_android_app "Phone" "com.google.android.dialer" "com.google.android.dialer.extensions.GoogleDialtactsActivity"
}


# === Productivity ===

# : Line
function line() {
    _require_no_args "$@" || return 1
    _launch_android_app "Line" "jp.naver.line.android" "jp.naver.line.android.activity.SplashActivity"
}

# : X (Twitter)
function x() {
    _require_no_args "$@" || return 1
    _launch_android_app "X (Twitter)" "com.twitter.android" "com.twitter.android.StartActivity"
}

function twitter() {
    _require_no_args "$@" || return 1
    _launch_android_app "X (Twitter)" "com.twitter.android" "com.twitter.android.StartActivity"
}

# : Telegram
function tg() {
    _require_no_args "$@" || return 1
    _launch_android_app "Telegram" "org.telegram.messenger" "org.telegram.messenger.DefaultIcon"
}

# : Messenger
function msger() {
    _require_no_args "$@" || return 1
    _launch_android_app "Messenger" "com.facebook.orca" "com.facebook.orca.auth.StartScreenActivity"
}

# : Discord
function dc() {
    _require_no_args "$@" || return 1
    _launch_android_app "Discord" "com.discord" "com.discord.main.MainDefault"
}

# : Reddit
function reddit() {
    _require_no_args "$@" || return 1
    _launch_android_app "Reddit" "com.reddit.frontpage" "launcher.default"
}


# === Entertainment (Taiwan) ===

# : 動畫瘋 (Bahamut Anime)
function bhani() {
    _require_no_args "$@" || return 1
    _launch_android_app "Animation" "tw.com.gamer.android.animad" "tw.com.gamer.android.animad.AnimadActivity"
}

# : Mihon
function mihon() {
    _require_no_args "$@" || return 1
    _launch_android_app "Mihon" "app.mihon" "eu.kanade.tachiyomi.ui.main.MainActivity"
}


# === Local / Lifestyle (Taiwan) ===

# : Cashew (Budget Tracker)
function cashew() {
    _require_no_args "$@" || return 1
	_launch_android_app "Cashew" "com.budget.tracker_app" "com.budget.tracker_app.MainActivity"
}

# : OpenPoint (7-11)
function op() {
    _require_no_args "$@" || return 1
    _launch_android_app "OPENPOINT" "tw.net.pic.m.openpoint" "tw.net.pic.m.openpoint.activity.WelcomeActivity"
}

# : Shopee
function shopee() {
    _require_no_args "$@" || return 1
    _launch_android_app "Shopee" "com.shopee.tw" "com.shopee.app.ui.home.HomeActivity_"
}

# : Taobao
function taobao() {
    _require_no_args "$@" || return 1
    _launch_android_app "Taobao" "com.taobao.taobao" "com.taobao.tao.welcome.Welcome"
}

# : Invoice (Taiwan)
function invoice() {
    _require_no_args "$@" || return 1
    _launch_android_app "Invoice" "tw.com.quickscanner.invoice" "tw.com.quickscanner.invoice.ui.launchscreen.LaunchScreenActivity"
}

# : EZ Way
function ezway() {
    _require_no_args "$@" || return 1
    _launch_android_app "EZ Way" "com.tradevan.android.forms" "com.tradevan.android.forms.ui.activity.SplashActivity"
}