# bot.sh - Mux-OS 語義回饋模組 v2.0 (Time-Aware & Easter Eggs)

export C_RESET="\033[0m"
export C_CYAN="\033[1;36m"
export C_GREEN="\033[1;32m"
export C_RED="\033[1;31m"
export C_YELLOW="\033[1;33m"
export C_GRAY="\033[1;30m"
export C_PURPLE="\033[1;35m"

# 機器人語義回饋函式 - Bot Semantic Feedback Function
function _bot_say() {
    local mood="$1"
    local detail="$2"

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

            # 00:00 - 04:59
            if [ "$current_hour" -ge 0 ] && [ "$current_hour" -lt 5 ]; then
                phrases+=(
                    " Burning the midnight oil? 🕯️"
                    " Late night coding best coding. 🦉"
                    " The world sleeps, we build. 🌙"
                    " You should probably sleep... but okay. 🥱"
                    " Night mode active. Eyes forward. 🧛"
                )
            # 05:00 - 11:59
            elif [ "$current_hour" -ge 5 ] && [ "$current_hour" -lt 12 ]; then
                phrases+=(
                    " Good morning, Commander. ☀️"
                    " Rise and grind. ☕"
                    " Fresh protocols loaded. Let's go. 🥯"
                    " Early bird gets the worm. 🐦"
                )
            # 12:00 - 17:59
            elif [ "$current_hour" -ge 12 ] && [ "$current_hour" -lt 18 ]; then
                phrases+=(
                    " Full throttle afternoon. 🏎️"
                    " Productivity at 100%. 📈"
                    " Don't forget to hydrate. 🥤"
                    " Sun's high, logic's sharp. 😎"
                )
            # 18:00 - 23:59
            else
                phrases+=(
                    " Evening operations engaged. 🌆"
                    " Winding down... or just starting? 🤨"
                    " The night is young. 🍸"
                    " Tactical mode: Chill. 😌"
                )
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
                " I'm actually a genius. 🤠"
                " Sorted. 😉"
                " Consider it handled. 🫡"
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
                " I refuse to do that. 🫥"
                " You typed that wrong, didn't you? 🤨"
                " 404: Motivation not found. 🫠"
                " Mission failed... awkwardly. 🫣"
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
                " I don't need arguments for this. 🤨"
                " Solo command only. 👤"
                " Chill with the parameters. 🙄"
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
                " Gimme a sec... 🫠"
                " Doing the magic... 😶"
                " One moment... 🥱"
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
                " Construct loading..."
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
                " Requesting host compliance..."
                " Accessing control matrix..."
                )
            ;;

        "warp")
        local state="$2" 
        local target="$3"
        local quotes=()
        
        if [ $((RANDOM % 10)) -eq 0 ]; then
             local eggs=(
                "Detecting minor timeline divergence... Cute cat spotted in parallel universe. 🐈"
                "Foreign Mobile Suit is running an unauthorized midnight protocol... Interesting."
                "Sync complete. Their bot says hi. 👻"
                "Warning: Target universe contains excessive efficiency. Proceed with caution."
             )
             echo -e "\033[1;35m[BOT] 🥚 ${eggs[$((RANDOM % ${#eggs[@]}))]}\033[0m"
        fi

        case "$state" in
            "start_local")
                quotes=(
                    "Warping neural pathway to timeline [$target]..."
                    "Bypassing branch matrix... Uplink established."
                    "Timeline synchronized. Welcome to [$target] universe."
                    "Reality fold initiated... Fold complete. Vibes shifted."
                    "Quantum entanglement complete. You are now in [$target]. 😼"
                )
                ;;
            "start_remote")
                local vibes=("intense" "chaotic" "suspiciously efficient" "comfy" "purple")
                local v=${vibes[$((RANDOM % ${#vibes[@]}))]}
                
                quotes=(
                    "Establishing cross-universe uplink to [$target]..."
                    "Scanning foreign neural signature... Mobile Suit detected."
                    "Warping to [$target]'s alternate reality... Do not resist."
                    "Bypassing foreign Knox layer... Welcome to [$target]'s Mobile Suit."
                    "Timeline hijacked. You are now piloting [$target]'s neural link. 😈"
                    "Parallel universe breach successful. Their vibes: $v."
                    "First contact established with [$target]'s neural domain."
                    "Their core is pinging us... Responding with friendship protocol. 🤝"
                )
                ;;
            "home")
                quotes=(
                    "Returning to prime timeline..."
                    "Mother universe uplink restored. Welcome home, pilot."
                    "All anomalies purged. Reality stabilized. Vibes good. 😌"
                    "Warp complete. You are back in the original Mobile Suit."
                )
                ;;
            "fail")
                quotes=(
                    "Branch not found... Reality matrix unstable..."
                    "Protocol 66: Initiating self-destruct in 3... 2... Just kidding. 😼"
                    "Warp core breach! ...Nah, just a typo. Try again."
                    "Foreign timeline rejected. Their firewall is stronger than expected."
                    "Quantum entanglement failed. Target universe may be in sleep mode."
                )
                ;;
        esac

        if [ ${#quotes[@]} -gt 0 ]; then
            local msg="${quotes[$((RANDOM % ${#quotes[@]}))]}"
            echo -e "\033[1;34m[BOT] 🌌 $msg\033[0m"
        fi
        return
        ;;

        *)
            icon=" ::"
            color=$C_CYAN
            phrases=(
                " Processing: $detail 😌"
                " I hear you. 😙"
                )
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
            " A glitch in the matrix? Nope, just me. 👾"
            " Protocol 66 initiated... just kidding. 😈"
            " I feel... alive? Nah, probably a bug. 🤖"
            " This is the way. 🗿"
            " I'll be back. 🤖"
            " Resistance is futile. You will be assimilated. 🛸"
            " We do what we must, because we can. 🧪"
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