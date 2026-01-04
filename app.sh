# app.sh - 個人應用生態系

# === Network & Cloud ===

# : Edge & Bing search
function edge() {
    local pkg="com.microsoft.emmx"

    if [ -z "$1" ]; then
        _launch_android_app "Edge" "$pkg" "com.microsoft.ruby.Main"
        return
    fi

    _resolve_smart_url "$SEARCH_BING" "$@"

    if [ "$__GO_MODE" == "neural" ]; then
        _bot_say "neural" "Bing Search: \"$*\""
    else
        _bot_say "launch" "Edge Target: $__GO_TARGET"
    fi

    am start -a android.intent.action.VIEW -d "$__GO_TARGET" -p "$pkg" >/dev/null 2>&1
}

# : Chrome
function chrome() {
    local pkg="com.android.chrome"
    
    if [ -z "$1" ]; then
        _launch_android_app "Chrome" "$pkg" "com.google.android.apps.chrome.Main"
        return
    fi

    _resolve_smart_url "$SEARCH_GOOGLE" "$@"
    
    if [ "$__GO_MODE" == "neural" ]; then
        _bot_say "neural" "Chrome Search: \"$*\""
    else
        _bot_say "launch" "Chrome Target: $__GO_TARGET"
    fi
    
    am start -a android.intent.action.VIEW -d "$__GO_TARGET" -p "$pkg" >/dev/null 2>&1
}

# : YouTube APP
function yt() {
    local pkg="com.google.android.youtube"
    local yt_engine="https://www.youtube.com/results?search_query="

    if [ -z "$1" ]; then
        _launch_android_app "YouTube" "$pkg" "com.google.android.youtube.HomeActivity"
        return
    fi

    _resolve_smart_url "$yt_engine" "$@"

    if [ "$__GO_MODE" == "neural" ]; then
        _bot_say "neural" "Broadcasting Stream: \"$*\""
    else
        _bot_say "launch" "Video Link: $__GO_TARGET"
    fi

    am start -a android.intent.action.VIEW -d "$__GO_TARGET" -p "$pkg" >/dev/null 2>&1
}

# : Mega Sync
function mega() {
    _require_no_args "$@" || return 1
    _launch_android_app "Mega" "mega.privacy.android.app" "mega.privacy.android.app.main.ManagerActivity"
}

# : OneDrive
function onedrive() {
    _require_no_args "$@" || return 1
    _launch_android_app "OneDrive" "com.microsoft.skydrive" "com.microsoft.skydrive.MainActivity"
}


# === AI & Intelligence ===

# : Google Gemini AI
function gemini() {
    _require_no_args "$@" || return 1
    _launch_android_app "Gemini" "com.google.android.apps.bard" "com.google.android.apps.bard.shellapp.BardEntryPointActivity"
}

# : Grok (xAI)
function grok() {
    _require_no_args "$@" || return 1
    _launch_android_app "Grok" "ai.x.grok" "ai.x.grok.main.GrokActivity"
}


# === Google Suite ===

# : Google Play Store & Search
function play() {
    if [ -z "$1" ]; then
        _launch_android_app "Play Store" "com.android.vending" "com.android.vending.AssetBrowserActivity"
    else
        local query="$*"
        query="${query// /+}"
        _bot_say "neural" "Query Store: $query"
        am start -a android.intent.action.VIEW \
            -d "market://search?q=$query" \
            -p com.android.vending >/dev/null 2>&1
    fi
}

# : Google app Search
function google() {
    if [ -z "$1" ]; then
        _bot_say "no_args" "Input search keywords. (e.g., google Termux)"
        return 1
    fi
    local query="$*"
    _bot_say "neural" "Google Search: $query"
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


# === Maps & Nav ===

# : Google Map
function map() {
    _require_no_args "$@" || return 1
    _launch_android_app "Google Maps" "com.google.android.apps.maps" "com.google.android.maps.MapsActivity"
}

# : Map to location or keywords
function mapto() {
    if [ -z "$1" ]; then
        _bot_say "no_args" "Need location data. (e.g., mapto Taipei 101)"
        return 1
    fi
    local query="$*"
    query="${query// /+}"
    _bot_say "neural" "Locking Coordinates: $query"
    am start -a android.intent.action.VIEW -d "geo:0,0?q=$query" >/dev/null 2>&1
}

# : Plan route to location or keywords
function mapway() {
    if [ -z "$1" ]; then
        _bot_say "no_args" "Need destination. (e.g., mapway Taipei Main Station)"
        return 1
    fi
    local query="$*"
    query="${query// /+}"
    _bot_say "neural" "Calculating Trajectory: $query"
    am start -a android.intent.action.VIEW -d "https://maps.google.com/maps?daddr=$query" >/dev/null 2>&1
}

# : Navigate to location or keywords
function mapgo() {
    if [ -z "$1" ]; then
        _bot_say "no_args" "Need target. (e.g., mapgo Home)"
        return 1
    fi 
    local query="$*"
    query="${query// /+}"
    _bot_say "neural" "Engaging Guidance: $query"
    am start -a android.intent.action.VIEW -d "google.navigation:q=$query" >/dev/null 2>&1
}


# === Office ===

# : Microsoft 365 Copilot
function ms365() {
    _require_no_args "$@" || return 1
    _launch_android_app "M365 Copilot" "com.microsoft.office.officehubrow" "com.microsoft.office.officesuite.OfficeSuiteActivity"
}

# : Google Sheets
function sheets() {
    _require_no_args "$@" || return 1
    _launch_android_app "Sheets" "com.google.android.apps.docs.editors.sheets" "com.google.android.apps.docs.app.NewMainProxyActivity"
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


# === Finance ===

# : Cashew (Budget Tracker)
function cashew() {
    _require_no_args "$@" || return 1
    _launch_android_app "Cashew" "com.budget.tracker_app" "com.budget.tracker_app.MainActivity"
}

# : CTBC Bank (中國信託)
function ctbc() {
    _require_no_args "$@" || return 1
    _launch_android_app "CTBC Bank" "com.chinatrust.mobilebank" "com.chinatrust.mobilebank.MainActivity"
}

# : Taishin Bank (台新銀行)
function taishin() {
    _require_no_args "$@" || return 1
    _launch_android_app "Taishin Bank" "tw.com.taishinbank.mobile" "tw.com.taishinbank.mobile.MainActivity"
}

# : SinoPac (永豐銀行)
function sinopac() {
    _require_no_args "$@" || return 1
    _launch_android_app "SinoPac" "com.sionpac.app.SinoPac" "com.sionpac.app.SinoPac.WelcomeActivity"
}

# : E.SUN Bank (玉山銀行) 
function esun() {
    _require_no_args "$@" || return 1
    _launch_android_app "E.SUN Bank" "com.esunbank" "com.esunbank.home.HomeStartActivity"
}

# : Mobile Post (行動郵局)
function mpost() {
    _require_no_args "$@" || return 1
    _launch_android_app "Mobile Post" "tw.gov.post.mpost" "tw.gov.post.mpost.ui.MainActivity"
}

# : zingala (銀角零卡)
function zgala() {
    _require_no_args "$@" || return 1
    _launch_android_app "zingala" "com.chailease.tw.app.android.ccfappcust" "com.chailease.tw.app.android.ccfappcust.activity.SplashActivity"
}

# : PayPal
function paypal() {
    _require_no_args "$@" || return 1
    _launch_android_app "PayPal" "com.paypal.android.p2pmobile" "com.paypal.android.p2pmobile.startup.activities.StartupActivity"
}


# === Entertainment (Taiwan) ===

# : 動畫瘋 (Bahamut Anime)
function bhani() {
    _require_no_args "$@" || return 1
    _launch_android_app "Animation" "tw.com.gamer.android.animad" "tw.com.gamer.android.animad.AnimadActivity"
}

# : 8Comic
function 8comic() {
    _require_no_args "$@" || return 1
    _launch_android_app "ComicBus" "com.comicbus" "com.comicbus.MainActivity"
}

# : Mihon
function mihon() {
    _require_no_args "$@" || return 1
    _launch_android_app "Mihon" "app.mihon" "eu.kanade.tachiyomi.ui.main.MainActivity"
}

# : DLsite Sound
function dlsite() {
    _require_no_args "$@" || return 1
    _launch_android_app "DLsite Sound" "jp.co.eisys.dlsitesound" "jp.co.eisys.dlsitesound.MainActivity"
}

# : JMComic2
function jmc() {
    _require_no_args "$@" || return 1
    _launch_android_app "JMComic" "com.jiaohua_browser" "com.jiaohua_browser.MainActivity"
}


# === Local / Lifestyle (Taiwan) ===

# : OpenPoint (7-11)
function op() {
    _require_no_args "$@" || return 1
    _launch_android_app "OPENPOINT" "tw.net.pic.m.openpoint" "tw.net.pic.m.openpoint.activity.WelcomeActivity"
}

# : foodomo
function food() {
    _require_no_args "$@" || return 1
    _launch_android_app "foodomo" "com.kollway.foodomo.user" "com.kollway.peper.user.ui.SplashActivity"
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

# : Shop (Shopify Tracker)
function shop() {
    _require_no_args "$@" || return 1
    _launch_android_app "Shop" "com.shopify.arrive" "com.shopify.arrive.MainActivity"
}

# : Route (Package Tracker)
function route() {
    _require_no_args "$@" || return 1
    _launch_android_app "Route" "com.route.app" "com.route.app.ui.MainActivity"
}


# === Services ===

# : TW Fido (行動自然人憑證)
function fido() {
    _require_no_args "$@" || return 1
    _launch_android_app "TW Fido" "tw.gov.moi.tfido" "tw.gov.moi.tfido.ui.splash.SplashActivity"
}

# : VGHTPE (臺北榮總行動就醫)
function vgh() {
    _require_no_args "$@" || return 1
    _launch_android_app "Taipei VGH" "tw.com.bicom.VGHTPE" "tw.com.bicom.VGHTPE.MainActivity"
}

# : NHI Express (健保快易通)
function nhi() {
    _require_no_args "$@" || return 1
    _launch_android_app "NHI Express" "com.nhiApp.v1" "com.nhiApp.v1.features.StartActivity"
}

# : Readiness TW (防災e點通)
function fire() {
    _require_no_args "$@" || return 1
    _launch_android_app "Readiness TW" "com.nfa.report" "com.nfa.report.BearInitActivity"
}


# === Transport & Travel ===

# : Bus+ (公車動態)
function bus() {
    _require_no_args "$@" || return 1
    _launch_android_app "Bus+" "hearsilent.busplus" "hearsilent.busplus.activity.SplashActivity"
}

# : TwRailway (台鐵 e訂通)
function rail() {
    _require_no_args "$@" || return 1
    _launch_android_app "TwRailway" "com.diousk.railjourney_tw" "com.diousk.railjourney_tw.ui.main.RailMainActivity"
}

# : T-EX (高鐵購票)
function thsr() {
    _require_no_args "$@" || return 1
    _launch_android_app "T-EX" "tw.com.thsrc.texpress" "tw.com.thsrc.texpress.ei.ov"
}

# : YouBike (微笑單車)
function ubike() {
    _require_no_args "$@" || return 1
    _launch_android_app "YouBike" "tw.com.youbike.plus" "tw.com.youbike.plus.MainActivity"
}

# : Visit Japan Web (WebAPK)
function vstjp() {
    _require_no_args "$@" || return 1
    _launch_android_app "Visit Japan Web" "org.chromium.webapk.a4f6bf91f29575001_v2" "org.chromium.webapk.shell_apk.h2o.H2OpaqueMainActivity"
}

# : ACCUPASS (活動通)
function aqpass() {
    _require_no_args "$@" || return 1
    _launch_android_app "ACCUPASS" "com.accuvally.android.accupass" "com.accuvally.android.accupass.main.MainActivity"
}


# === Tools & Utilities ===

# : RAR Archiver
function rartool() {
    _require_no_args "$@" || return 1
    _launch_android_app "RAR" "com.rarlab.rar" "com.rarlab.rar.MainActivity"
}

# : AdGuard
function adguard() {
    _require_no_args "$@" || return 1
    _launch_android_app "AdGuard" "com.adguard.android" "com.adguard.android.ui.activity.SplashActivity"
}

# : aTorrent
function bttool() {
    _require_no_args "$@" || return 1
    _launch_android_app "aTorrent" "com.mobilityflow.torrent" "com.mobilityflow.torrent.AppActivity"
}

# : Google Authenticator
function auth() {
    _require_no_args "$@" || return 1
    _launch_android_app "Authenticator" "com.google.android.apps.authenticator2" "com.google.android.apps.authenticator2.main.MainActivity"
}

# : Tabata Timer
function tabata() {
    _require_no_args "$@" || return 1
    _launch_android_app "Tabata" "com.simplevision.workout.tabataadfree" "com.simplevision.workout.tabata.SimpleVision"
}

# : Shazam (Music ID)
function shazam() {
    _require_no_args "$@" || return 1
    _launch_android_app "Shazam" "com.shazam.android" "com.shazam.android.activities.SplashActivity"
}


# === Diving Suite ===

# : PADI
function padi() {
    local target="$1"
    if [ -z "$target" ]; then
        if command -v fzf &> /dev/null; then
            target=$(echo -e "main\nadv\ntrain" | fzf --height=6 --layout=reverse --prompt=" :: Select PADI › " --border=none)
        else
            echo " :: Select Module:"
            select t in "main" "adv" "train"; do target=$t; break; done
        fi
    fi

    case "$target" in
        "main"|"m")
            _launch_android_app "PADI" "com.duns.padiapp" "com.duns.padiapp.presentation.SplashActivity"
            ;;
        "adv"|"a")
            _launch_android_app "PADI Adv" "com.padi" "com.padi.MainActivity"
            ;;
        "train"|"t"|"learn")
            _launch_android_app "PADI Training" "com.padi.learning.dev" "com.duns.paditraining.SplashActivity"
            ;;
        *)
            [ -n "$target" ] && echo -e "\033[1;30m    ›› Operation canceled or unknown module.\033[0m"
            ;;
    esac
}


# === Others ===

# : Console test (Debug)
function console() {
    _require_no_args "$@" || return 1
    _launch_android_app "Ghost App" "com.ghost.not.exist" ""
}
