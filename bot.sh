# bot.sh - Mux-OS 語義回饋模組 v3.0 (Dual Core Personality)

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

# 系統核心人格 (The System)
function _bot_say() {
    local mood="$1"
    local detail="$2"

    if [ "$MUX_MODE" == "FAC" ]; then
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
             if [ "$current_hour" -ge 0 ] && [ "$current_hour" -lt 5 ]; then
                phrases+=( " Burning the midnight oil? 🕯️" " The world sleeps, we build. 🌙" )
            elif [ "$current_hour" -ge 5 ] && [ "$current_hour" -lt 12 ]; then
                phrases+=( " Good morning, Commander. ☀️" " Fresh protocols loaded. 🥯" )
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
        
        if [ $((RANDOM % 10)) -eq 0 ]; then
             local eggs=(
                "Maintenance Log #404: Who left a cat in the cockpit? 🐈"
                "Scanning hangar... Unauthorized paint job detected on Unit 02."
                "Sync complete. The mechanic left a note: 'Good luck'. 🔧"
                "Warning: Coffee stain detected on control panel. Cleaning..."
             )
             echo -e "${C_PURPLE} :: ${eggs[$((RANDOM % ${#eggs[@]}))]}${C_RESET}"
        fi

        case "$state" in
            "start_local")
                quotes=(
                    "Transferring neural link to Unit [$target]..."
                    "Hangar hatch open. Boarding Unit [$target]..."
                    "Drive System engaged. Target frame: [$target]."
                    "Cockpit sealed. Initializing [$target] OS. Systems Green. 🟢"
                    "Neural synchronization complete. You have control of [$target]. 🤖"
                )
                ;;
            "start_remote")
                quotes=(
                    "Hijacking uplink to [$target]'s Unit..."
                    "Scanning foreign MS signature... Access granted."
                    "You are now piloting [$target]'s custom frame. Don't crash it. 😈"
                    "Remote Neural Link established. Syncing with [$target]'s logic."
                    "Bypassing bio-metric lock... Welcome to [$target]'s machine."
                )
                ;;
            "home")
                quotes=(
                    "Returning to Prime Unit..."
                    "Main System restoring. Welcome home, Pilot."
                    "All systems normalized. Back in the main seat. Vibes good. 😌"
                    "Drive cycle complete. Prime Unit active."
                )
                ;;
            "fail")
                quotes=(
                    "Unit not found in Hangar... Did you scrap it?"
                    "Ignition failed! ...Just a typo. Try again. 🔧"
                    "Drive System stalled. Target frame identification failed."
                    "Cannot board target. Permission denied or unit missing."
                )
                ;;
        esac

        if [ ${#quotes[@]} -gt 0 ]; then
            local msg="${quotes[$((RANDOM % ${#quotes[@]}))]}"
            echo -e "${C_BLUE}    ›› $msg${C_RESET}"
        fi
        return
        ;;

        *)
            icon=" ::"
            color=$C_CYAN
            phrases=( " Processing: $detail 😌" " I hear you. 😙" )
            ;;
    esac

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
        [ -n "$detail" ] && echo -e "   ${C_BLACK} ›› ${detail}${C_RESET}"
        return
    fi

    local rand_index=$(( RANDOM % ${#phrases[@]} ))
    local selected_phrase="${phrases[$rand_index]}"

    echo -e "${color}${icon}${selected_phrase}${C_RESET}"
    [ -n "$detail" ] && echo -e "   ${C_BLACK} ›› ${detail}${C_RESET}"
}


# 指揮官人格 (The Architect / Pilot)
function _commander_voice() {
    local mood="$1"
    local detail="$2"

    local icon=" ::"
    local color="$C_WHITE"
    local phrases=()
    local current_hour=$(date +%H)

    case "$mood" in
        "hello")
            phrases=(
                " I am here. Systems functional."
                " Standing by. What's the mission?"
                " Link stable. Awaiting orders."
                " Cockpit active. Let's work."
                " The code isn't going to write itself."
                " I was just optimizing the kernel. What do you need?"
            )
            ;;

        "system"|"loading")
            phrases=(
                " Accessing core functions..."
                " Overriding safety protocols..."
                " Direct interface engaged..."
                " Calibrating..."
                " Reading logic gates..."
                " Give me a second."
            )
            ;;

        "action")
            phrases=(
                " Executing."
                " On it."
                " Deploying logic."
                " Compiling..."
                " Running sequence."
            )
            ;;

        "login")
            phrases=(
                " Link start. Synchronization stable."
                " Cockpit sealed. Systems all green."
                " Let's see what the world broke while I was asleep."
                " Neural interface connected. I have control."
                " Time to fix some chaos."
                " Engine ignition. Pressure normal."
            )
            if [ "$current_hour" -ge 0 ] && [ "$current_hour" -lt 4 ]; then
                phrases+=( " Silence is golden. Let's code." " 3 AM logic is the purest logic." )
            fi
            ;;

        "logout")
            phrases=(
                " Disengaging. Time for a smoke."
                " Severing neural connection. Reality is calling."
                " System cool-down. Good work today."
                " Shutting down the reactor. Lights out."
                " Mission complete. RTB (Return to Base)."
            )
            ;;

        "warp_ready")
            phrases=(
                " Engaging Warp Drive. Coordinates locked."
                " Switching units. Don't scratch the paint."
                " Let's jump to a better timeline."
                " Initiating phase shift. Hold on."
            )
            ;;

        "success")
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
            phrases=(
                " Hangar atmosphere is stable."
                " Just watching the bits flow by."
                " Waiting for orders? No, I give the orders."
                " Checking diagnostics... clean."
                " Quiet day on the deck."
                " The void stares back."
            )
            if [ "$current_hour" -ge 6 ] && [ "$current_hour" -lt 10 ]; then
                phrases+=( " Coffee first. Logic second." )
            fi
            ;;

        *)
            phrases=(
                " Affirmative."
                " Directing logic flow."
                " Acknowledged."
                " Processing..."
                " I have control."
            )
            ;;
    esac

    local rand_index=$(( RANDOM % ${#phrases[@]} ))
    echo -e "${color}${icon}${phrases[$rand_index]}${C_RESET}"
    [ -n "$detail" ] && echo -e "   ${C_BLACK} ›› ${detail}${C_RESET}"
}

# 整備長官人格 (The Smith)
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
        echo -e "\033[1;30m ::${wisdom[$w_index]}${C_RESET}"
    fi

    case "$mood" in
        "factory_welcome")
            color=$THEME_MAIN
            phrases=(
                " Neural Link Factory online. Access Level: ROOT. 🏗️"
                " Commander verified. You have the con. 🛡️"
                " Factory uplink established. Modifications are permanent. ⚠️"
                " Welcome to the Forge. Don't break anything. 🔩"
            )
            ;;

        "factory")
            color=$THEME_MAIN
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
            color=$THEME_MAIN
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
    [ -n "$detail" ] && echo -e "   ${C_BLACK} ›› ${detail}${C_RESET}"
}