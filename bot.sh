# bot.sh - Mux-OS 語義回饋模組 v3.0 (Dual Core Personality)

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

export C_RESET="\033[0m"
export C_CYAN="\033[1;36m"
export C_GREEN="\033[1;32m"
export C_RED="\033[1;31m"
export C_YELLOW="\033[1;33m"
export C_GRAY="\033[1;30m"
export C_PURPLE="\033[1;35m"
export C_ORANGE="\033[1;38;5;208m"
export C_WHITE="\033[1;37m"     # Commander's Color

# -----------------------------------------------------------
# [Bot] 系統核心人格 (The System)
# -----------------------------------------------------------
function _bot_say() {
    local mood="$1"
    local detail="$2"

    if [ "$__MUX_MODE" == "factory" ]; then
        _bot_factory_personality "$mood" "$detail"
        return
    fi

    local icon=""
    local color=""
    local phrases=()
    
    # 獲取時間參數 (0-23)
    local current_hour=$(date +%H)
    local rng=$(( RANDOM % 100 ))
    local easter_egg=0
    [ $rng -lt 3 ] && easter_egg=1

    case "$mood" in
        "hello")
            icon=" ::"
            color=$C_CYAN
            phrases=(
                " Mux-OS online. Awaiting input. 🫡"
                " Systems nominal. Ready when you are. 😏"
                " Greetings, Commander. 😁"
                " Core logic initialized. 😎"
                " At your service. 🫡"
                " Digital horizon secure. What's next? 🧐"
                " Yo, Commander. Systems ready. 🤠"
                " Mux-OS awake. Coffee time? 🤤"
                " What are we building today? 🤩"
                " System great. Vibes good. 😊"
                " Back online. Let's rock. 😆"
                " I am ready to serve. 🫡"
                )

            # 時間感知邏輯
            if [ "$current_hour" -ge 0 ] && [ "$current_hour" -lt 5 ]; then
                phrases+=( " Burning the midnight oil? 🕯️" " Late night coding best coding. 🦉" " The world sleeps, we build. 🌙" )
            elif [ "$current_hour" -ge 5 ] && [ "$current_hour" -lt 12 ]; then
                phrases+=( " Good morning, Commander. ☀️" " Rise and grind. ☕" " Fresh protocols loaded. 🥯" )
            elif [ "$current_hour" -ge 12 ] && [ "$current_hour" -lt 18 ]; then
                phrases+=( " Full throttle afternoon. 🏎️" " Productivity at 100%. 📈" " Don't forget to hydrate. 🥤" )
            else
                phrases+=( " Evening operations engaged. 🌆" " The night is young. 🍸" " Tactical mode: Chill. 😌" )
            fi
            ;;

        "success")
            icon=" ::"
            color=$C_GREEN
            phrases=(
                " Execution perfect. 😏"
                " As you commanded. 🫡"
                " Consider it done. 🥳"
                " Operation successful. 🤩"
                " That was easy. 😁"
                " I have arranged the bits as requested. 😉"
                " Smooth as silk. 😋"
                " Boom. Done. 😝"
                " Too easy. 😏"
                " Nailed it. 🤓"
                " Sorted. 😉"
                )
            ;;

        "neural")
            icon=" ::"
            color=$C_CYAN
            phrases=(
                " Establishing Neural Link... 🧐"
                " Injecting query into Datasphere... 🤔"
                " Handshaking with the Grid... 😊"
                " Accessing Global Network... 🙂‍↕️"
                " Broadcasting intent... 🤓"
                " Opening digital gateway... 😉"
                " Uplink established. 🤗"
                )
            ;;

        "error")
            icon=" ::"
            color=$C_RED
            phrases=(
                " I'm afraid I can't do that. 😩"
                " Mission failed successfully. 💀"
                " Computer says no. 🫢"
                " That... didn't go as planned. 🫤"
                " Protocol mismatch. Try again. 🤨"
                " My logic circuits refuse this request. 😒"
                " User error... presumably. 🤫"
                " Yeah... that's a negative. 🙄"
                " Oof. That didn't work. 🫨"
                " 404: Motivation not found. 🫠"
                )
            ;;

        "no_args")
            icon=" ::"
            color=$C_YELLOW
            phrases=(
                " I need less talking, more action. (No args please) 🤫"
                " That command stands alone. 🥹"
                " Don't complicate things. 😓"
                " Arguments are irrelevant here. 😦"
                " Just the command, nothing else. 🤐"
                " Whoa, too many words. 😵"
                " Just the command, chief. 🫡"
                )
            ;;

        "loading")
            icon=" ::"
            color=$C_GRAY
            phrases=(
                " Processing... 😑"
                " Entropy increasing... 🌀"
                " Calculating probabilities... 🧐"
                " Hold your horses... 🐴"
                " Compiling reality... 😑"
                " Hold up... 🫨"
                " Doing the magic... 😶"
                )
            ;;

        "launch")
            icon=" ::"
            color=$C_CYAN
            phrases=(
                " Spinning up module..."
                " Injecting payload..."
                " Materializing interface..."
                " Accessing neural partition..."
                " Summoning application..."
                " Executing launch sequence..."
                )
            ;;

        "system")
            icon=" ::"
            color=$C_YELLOW
            phrases=(
                " Interfacing with Host Core..."
                " Modulating system parameters..."
                " Establishing neural link..."
                " Overriding droid protocols..."
                " Syncing with hardware layer..."
                " Accessing control matrix..."
                )
            ;;

        "warp")
        local state="$2" 
        local target="$3"
        local quotes=()
        
        # 隨機彩蛋
        if [ $((RANDOM % 10)) -eq 0 ]; then
             local eggs=(
                "Detecting minor timeline divergence... Cute cat spotted. 🐈"
                "Foreign Mobile Suit is running an unauthorized midnight protocol..."
                "Sync complete. Their bot says hi. 👻"
             )
             echo -e "\033[1;35m :: ${eggs[$((RANDOM % ${#eggs[@]}))]}\033[0m"
        fi

        case "$state" in
            "start_local")
                quotes=(
                    "Warping neural pathway to timeline [$target]..."
                    "Bypassing branch matrix... Uplink established."
                    "Timeline synchronized. Welcome to [$target] universe."
                    "Quantum entanglement complete. You are now in [$target]. 😼"
                )
                ;;
            "start_remote")
                quotes=(
                    "Establishing cross-universe uplink to [$target]..."
                    "Scanning foreign neural signature... Mobile Suit detected."
                    "Timeline hijacked. You are now piloting [$target]'s neural link. 😈"
                    "First contact established with [$target]'s neural domain."
                )
                ;;
            "home")
                quotes=(
                    "Returning to prime timeline..."
                    "Mother universe uplink restored. Welcome home, pilot."
                    "All anomalies purged. Reality stabilized. Vibes good. 😌"
                )
                ;;
            "fail")
                quotes=(
                    "Branch not found... Reality matrix unstable..."
                    "Protocol 66: Initiating self-destruct... Just kidding. 😼"
                    "Warp core breach! ...Nah, just a typo. Try again."
                )
                ;;
        esac

        if [ ${#quotes[@]} -gt 0 ]; then
            local msg="${quotes[$((RANDOM % ${#quotes[@]}))]}"
            echo -e "\033[1;34m    ›› $msg\033[0m"
        fi
        return
        ;;

        *)
            icon=" ::"
            color=$C_CYAN
            phrases=( " Processing: $detail 😌" " I hear you. 😙" )
            ;;
    esac

    # Easter Egg Logic
    if [ "$easter_egg" -eq 1 ] && [[ "$mood" != "launch" && "$mood" != "system" && "$mood" != "loading" ]]; then
        color=$C_PURPLE
        local easter_eggs=(
            " Do androids dream of electric sheep? 🐑"
            " There is no spoon. 🥄"
            " Follow the white rabbit. 🐇"
            " I am watching you, Commander. 👀"
            " 42. The answer is 42. 💡"
            " This is the way. 🗿"
            " Resistance is futile. 🛸"
        )
        local ee_index=$(( RANDOM % ${#easter_eggs[@]} ))
        echo -e "${color}${icon}${easter_eggs[$ee_index]}${C_RESET}"
        [ -n "$detail" ] && echo -e "   ${C_GRAY} ›› ${detail}${C_RESET}"
        return
    fi

    local rand_index=$(( RANDOM % ${#phrases[@]} ))
    local selected_phrase="${phrases[$rand_index]}"

    echo -e "${color}${icon}${selected_phrase}${C_RESET}"
    [ -n "$detail" ] && echo -e "   ${C_GRAY} ›› ${detail}${C_RESET}"
}

# -----------------------------------------------------------
# [Commander] 指揮官人格 (The Architect / Pilot)
# -----------------------------------------------------------
function _commander_voice() {
    local mood="$1"
    local detail="$2"

    local icon=" ::"
    local color="$C_WHITE" # Commander is White/Silver (Pure Logic)
    local phrases=()
    local current_hour=$(date +%H)

    case "$mood" in
        "login")
            # 登入：啟動引擎，檢查儀表
            phrases=(
                " Link start. Synchronization stable."
                " Cockpit sealed. Systems all green."
                " Let's see what the world broke while I was asleep."
                " Neural interface connected. I have control."
                " Time to fix some chaos."
                " Engine ignition. Pressure normal."
            )
            # 深夜加班
            if [ "$current_hour" -ge 0 ] && [ "$current_hour" -lt 4 ]; then
                phrases+=( " Silence is golden. Let's code." " 3 AM logic is the purest logic." )
            fi
            ;;

        "logout")
            # 登出：切斷連結，休息
            phrases=(
                " Disengaging. Time for a smoke."
                " Severing neural connection. Reality is calling."
                " System cool-down. Good work today."
                " Shutting down the reactor. Lights out."
                " Mission complete. RTB (Return to Base)."
            )
            ;;

        "warp_ready")
            # 換乘前：挑選機體
            phrases=(
                " Engaging Warp Drive. Coordinates locked."
                " Switching units. Don't scratch the paint."
                " Let's jump to a better timeline."
                " Initiating phase shift. Hold on."
            )
            ;;

        "success")
            # 成功：理所當然，冷靜
            phrases=(
                " As expected."
                " Precision engineering."
                " Optimal outcome."
                " Flawless execution."
                " Logic is absolute."
                " Just another day at the office."
            )
            ;;

        "error")
            # 失敗：嘖，分析，不屑
            phrases=(
                " Tch. Inefficiency detected."
                " Re-calibrating variables..."
                " Who wrote this garbage? Oh, wait."
                " Entropy is increasing again."
                " Signal lost. Rerouting..."
                " Not acceptable. Fix it."
            )
            ;;
        
        "default_idle")
            # 停機坪閒聊 (DEFAULT狀態)
            phrases=(
                " Hangar atmosphere is stable."
                " Just watching the bits flow by."
                " Waiting for orders? No, I give the orders."
                " Checking diagnostics... clean."
                " Quiet day on the deck."
                " The void stares back."
            )
             # 早晨
            if [ "$current_hour" -ge 6 ] && [ "$current_hour" -lt 10 ]; then
                phrases+=( " Coffee first. Logic second." )
            fi
            ;;

        *)
            # 通用
            phrases=(
                " Affirmative."
                " Directing logic flow."
                " Acknowledged."
                " Processing..."
            )
            ;;
    esac

    local rand_index=$(( RANDOM % ${#phrases[@]} ))
    echo -e "${color}${icon}${phrases[$rand_index]}${C_RESET}"
    [ -n "$detail" ] && echo -e "   ${C_GRAY} ›› ${detail}${C_RESET}"
}

# -----------------------------------------------------------
# [Factory] 整備長官人格 (The Smith)
# -----------------------------------------------------------
function _bot_factory_personality() {
    local mood="$1"
    local detail="$2"
    
    local icon=" ::"
    local color=""
    local phrases=()
    
    local rng=$(( RANDOM % 100 ))
    if [ $rng -lt 5 ] && [[ "$mood" != "error" ]]; then
        local wisdom=(
            " I strongly advise keeping at least three backups. 💾"
            " Double-check your parameters. 🧐"
            " Clean code is safe code. 🧹"
            " Do not proceed without confirmation. 👁️"
        )
        local w_index=$(( RANDOM % ${#wisdom[@]} ))
        echo -e "\033[1;30m ::${wisdom[$w_index]}\033[0m"
    fi

    case "$mood" in
        "factory_welcome")
            color=$C_ORANGE
            phrases=(
                " Neural Link Factory online. Access Level: ROOT. 🏗️"
                " Commander verified. You have the con. 🛡️"
                " Factory uplink established. Modifications are permanent. ⚠️"
                " Welcome to the Forge. Don't break anything. 🔩"
            )
            ;;

        "factory")
            color=$C_ORANGE
            phrases=(
                " Factory operational. Scanning active links... 📡"
                " Current target: app.sh. Write-Mode: UNLOCKED. 🔓"
                " Forge status nominal. Awaiting command. 🫡"
                " Mechanism maintenance active... 🔧"
            )
            ;;

        "success")
            color=$C_GREEN
            phrases=(
                " Structure integrity: 100%. Modification applied. ✅"
                " Code compiled. Looks stable... for now. 🔨"
                " Patch applied to Sandbox. 🧐"
                " Blueprint updated. 📝"
                " Command forged. 🛡️"
            )
            ;;

        "action")
            color=$C_YELLOW
            phrases=(
                " Initiating write sequence..."
                " Forging new command node..."
                " Updating matrix definitions..."
                " Inscribing logic to core..."
            )
            ;;

        "warn")
            color=$C_RED
            phrases=(
                " Structural integrity warning"
                " Parameter mismatch detected"
                " Alert: Potential conflict in logic"
                " System Alert: Unstable configuration"
            )
            ;;

        "error")
            color=$C_RED
            phrases=(
                " Invalid input. Procedure aborted. 🚫"
                " Anomaly detected. Reverting changes. ↩️"
                " This action violates stability protocols. 🛑"
                " Error: Identity mismatch detected. 🔒"
                " Don't break anything. I mean it. 😠"
                " Syntax error. Check your manual. 📖"
            )
            ;;

        "deploy_start")
            color=$C_YELLOW
            phrases=(
                " Deployment sequence initiated. ⏳"
                " Input CONFIRM to authorize permanent deployment. ⌨️"
                " Compiling Sandbox changes... 📦"
            )
            ;;

        "deploy_done")
            color=$C_GREEN
            phrases=(
                " Deployment authorized. Modifications sealed. 🔒"
                " Factory shutdown in progress. 🛡️"
                " Uplink terminated. Reload kernel manually. 🔄"
                " Production environment updated. 💺"
            )
            ;;

        "eject")
            color=$C_RED
            phrases=(
                " Get out of my chair. Now. 🚀"
                " Security violation. Ejecting pilot... ⏏️"
                " Sandbox purged. Session terminated. 💥"
                " Critical protocol failure. Forcible extraction initiated. ✂️"
                " Access revoked. 🚫"
            )
            ;;

        *)
            color=$C_ORANGE
            phrases=(
                " Input received."
                " Acknowledged."
                " Command logged."
                " Routing logic..."
                " Core is attentive."
            )
            ;;
    esac

    local rand_index=$(( RANDOM % ${#phrases[@]} ))
    echo -e "${color}${icon}${phrases[$rand_index]}${C_RESET}"
    [ -n "$detail" ] && echo -e "   ${C_GRAY} ›› ${detail}${C_RESET}"
}