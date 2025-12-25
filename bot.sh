# bot.sh - Mux-OS 語義回饋模組

# 全局顏色變數 (供 ui.sh 共用)
export C_RESET="\033[0m"
export C_CYAN="\033[1;36m"
export C_GREEN="\033[1;32m"
export C_RED="\033[1;31m"
export C_YELLOW="\033[1;33m"
export C_GRAY="\033[1;30m"

# 機器人語義回饋函式 - Bot Semantic Feedback Function
function _bot_say() {
    local mood="$1"
    local detail="$2"

    local icon=""
    local color=""
    local phrases=()

    case "$mood" in
        "hello")
            icon=" ::";
            color=$C_CYAN;
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
                " I was sleeping... but okay, I'm up. 🥱"
                " I am ready to serve. 🫡"
                )
                ;;
        "success")
            icon=" ::";
            color=$C_GREEN;
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
            icon=" ::";
            color=$C_CYAN;
            phrases=(
                " Establishing Neural Link... 🧐"
                " Injecting query into Datasphere... 🤔"
                " Handshaking with the Grid... ☺️"
                " Accessing Global Network... 🙂‍↕️"
                " Broadcasting intent... 🤓"
                " Opening digital gateway... 😉"
                " Uplink established. 🤗"
                )
                ;;
        "error")
            icon=" ::";
            color=$C_RED;
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
            icon=" ::";
            color=$C_YELLOW;
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
            icon=" ::";
            color=$C_GRAY;
            phrases=(
                " Processing... 😑"
                " Entropy increasing... 🌀"
                " Calculating probabilities... 🧐"
                " Hold your horses... 🫥"
                " Compiling reality... 🫩"
                " Hold up... 🫨"
                " Gimme a sec... 🫠"
                " Doing the magic... 😶"
                " One moment... 🥱"
                )
                ;;
        "launch")
            icon=" ::";
            color=$C_CYAN;
            phrases=(
                " Spinning up module... ⚙️"
                " Injecting payload... 💉"
                " Materializing interface... 🖥️"
                " Accessing neural partition... 🧠"
                " Construct loading... 📦"
                " Summoning application... 🤖"
                " Executing launch sequence... 🚀"
                )
                ;;
        "system")
            icon=" ::";
            color=$C_YELLOW;
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
        *)
            icon=" ::";
            color=$C_CYAN;
            phrases=(
                " Processing: $detail 😌"
                " I hear you. 😙"
                )
                ;;
    esac

    local rand_index=$(( RANDOM % ${#phrases[@]} ))
    local selected_phrase="${phrases[$rand_index]}"

    echo -e "${color}${icon}${selected_phrase}${C_RESET}"
    [ -n "$detail" ] && echo -e "   ${C_GRAY}> ${detail}${C_RESET}"
}