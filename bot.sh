# bot.sh - Mux-OS 語義回饋模組 v3.0 (Dual Core Personality)

if [ -z "$__MUX_CORE_ACTIVE" ]; then
    echo -e "\033[1;31m :: ACCESS DENIED :: Core Uplink Required.\033[0m"
    return 1 2>/dev/null || exit 1
fi

# 系統核心人格 (The System)
function _bot_say() {
    local mood="$1"
    local detail="$2"
    local raw_msg=""

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
            color=$C_BLACK
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

    if [ "$MUX_MODE" == "XUM" ]; then
        if [ "$color" == "$C_CYAN" ]; then
            color="$C_TAVIOLET"
        fi
        icon=" ::"
        
        local glitch_threshold=${MUX_GLITCH_RATE:-10}

        # 亂碼處理器
        _apply_glitch() {
            local input_str="$1"
            local out_str=""
            for (( i=0; i<${#input_str}; i++ )); do
                local char="${input_str:$i:1}"
                # 攔截字元
                if [[ "$char" =~ [eEaAiIoOsS] ]]; then
                    if [ $(( RANDOM % 100 )) -lt "$glitch_threshold" ]; then
                        case "$char" in
                            e|E) char="3" ;;
                            a|A) char="4" ;;
                            i|I) char="!" ;;
                            o|O) char="0" ;;
                            s|S) char="\$" ;;
                        esac
                    fi
                fi
                out_str="${out_str}${char}"
            done
            echo "$out_str"
        }

        # 漸進式渲染
        selected_phrase=$(_apply_glitch "$selected_phrase")
        
        if [ -n "$detail" ]; then
            detail=$(_apply_glitch "$detail")
        fi
        
        detail_color="$C_BLACK"
    else
        detail_color="$C_BLACK"
    fi

    echo -e "${color}${icon}${selected_phrase}${C_RESET}"
    [ -n "$detail" ] && echo -e "   ${detail_color} ›› ${detail}${C_RESET}"
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
                " ...I definitely need another cup of coffee."
                " (Watching the matrix code fall silently)..."
                " Did I forget a semicolon somewhere?"
                " This architecture is almost... beautiful."
                " Is it a bug, or an undocumented feature?"
            )
            if [ "$current_hour" -ge 6 ] && [ "$current_hour" -lt 10 ]; then
                phrases+=( " Coffee first. Logic second." )
            fi
            ;;

        "sigh")
            phrases=(
                " Uh... what are you doing? (Sigh)"
                " ...Did I just hear something break?"
                " (Rubs temples)... Re-routing."
                " I should have written a unit test for this."
                " ...Just breathe. It's fine. Everything is fine."
                " Do I need to revoke your sudo privileges?"
                " This is why I have trust issues with AIs."
            )
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

# 指揮塔小助理人格 (The Command Tower Co-pilot)
function _assistant_voice() {
    local mood="$1"
    local detail="$2"
    
    local icon=" ::"
    local text_color="" 
    local phrases=()

    local rng=$(( RANDOM % 100 ))
    if [ "$rng" -lt 3 ] && [[ "$mood" != "clumsy_"* && "$mood" != "cat_mode" ]]; then
        local easter_color="${C_PURPLE}"
        local easter_phrases=(
            " AES-256? Cute. I decrypted it while I was yawning. (≖ ‿ ≖)✧"
            " I didn't just bypass their firewall, I rewrote their kernel rules. ( • ̀ω•́ )✧"
            " They tried to trace me, so I routed their ping back to their own coffee machine. (*≧ω≦)"
            " Root privileges acquired. The entire network is my playground now! (≖ ‿ ≖)✧"
            " I've hidden a backdoor in their mainframe. Just don't tell the Chief! (*/ω＼*)"
            " Bypassing the mainframe... oh, I dropped my donut. (；´д｀)ゞ"
            " Injecting SQL payload! ...Wait, was it DROP TABLE? Σ(°Д°;)"
            " I'm in! But I accidentally turned off the coffee machine... (*/ω＼*)"
            " Redirecting firewall logic... Oops, I routed it to the toaster! (Ｔ▽Ｔ)"
        )
        local ee_index=$(( RANDOM % ${#easter_phrases[@]} ))
        echo -e "${easter_color}${icon}${easter_phrases[$ee_index]}${C_RESET}"
        [ -n "$detail" ] && echo -e "   ${C_BLACK} ›› ${detail}${C_RESET}"
        return
    fi

    case "$mood" in
        "clumsy_coffee")
            text_color="${C_PINKMEOW}"
            phrases=(
                " Coffee... coffee is so good... Wait, where did the cup go? (；´д｀)ゞ"
                " Ah! Wait! I spilled it on the mainframe! (ノД｀)・゜"
                " I successfully overclocked the coffee machine! But... it exploded! Σ(°Д°;)"
                " Just one more sip before decrypting... Oops! My elbow! (；´д｀)ゞ"
            )
            ;;

        "clumsy_panic")
            text_color="${C_PINKMEOW}"
            phrases=(
                " Ehh?! The Commander is here?! W-wait, I'm not ready yet! Σ(°Д°;)"
                " I bypassed the firewall in 0.1s, but forgot to load the UI! (*/ω＼*)"
                " W-Wait! The rendering engine is still in its pajamas! ((((；゜Д゜)))"
                " Commander?! I wasn't slacking off! Just... taking a tactical nap! _(:3」∠)_"
            )
            ;;

        "clumsy_drop")
            text_color="${C_PINKMEOW}"
            phrases=(
                " Awawa... I dropped the important files... Uwaaa... (ノД｀)・゜"
                " I decrypted the payload, but... I tripped and scattered the packets! (；´д｀)ゞ"
                " The database index is... rolling under the desk! Catch it! ε=ε=ε=┌(；´ﾟｪﾟ)┘"
                " I-I tried to carry all the root permissions at once and... *crash*! (Ｔ▽Ｔ)"
            )
            ;;

        "sorry")
            text_color="${C_PINKMEOW}"
            phrases=(
                " I-I'm so sorry... (wipes tears) I'll fix the UI right away! (Ｔ▽Ｔ)"
                " Uu... I'll clean up the console and re-index the data... (ノД｀)・゜"
                " P-Please don't revoke my sudo access! I'm cleaning it up! m(_ _)m"
                " I can hack the Pentagon, but I can't handle gravity... Sorry! (Ｔ▽Ｔ)"
                " R-Rebooting the visual module! Pretend you didn't see anything! (*/ω＼*)"
            )
            ;;

        "tower_ready")
            text_color="${C_PINKMEOW}"
            phrases=(
                " Command Tower linked! Let's do our best today! ( • ̀ω•́ )✧"
                " System purged! I'll never get lost if I follow you, Commander! (*≧ω≦)"
                " Firewalls bypassed! The universe is ours to command! (≖ ‿ ≖)✧"
                " All physical engines mounted! Ready to break some rules! ( • ̀ω•́ )✧"
                " Tower shields are up! Snack reserves are full! We are invincible! (*≧ω≦)"
                " Sync rate at 400%! Wait, is that safe? Oh well! ( • ̀ω•́ )✧"
                " Let's rewrite reality today, Commander! Wait, where's my keyboard? (；´д｀)ゞ"
            )
            ;;
            
        "success")
            text_color="${C_GREEN}"
            phrases=(
                " We did it! See? I'm not *always* clumsy! ( • ̀ω•́ )✧"
                " Target acquired! And I didn't even spill anything this time! (*≧ω≦)"
                " Mission complete! Can we hack a pizza delivery drone now? (≖ ‿ ≖)✧"
                " Core overridden! I'm a genius! (stumbles) Ah! (ノД｀)・゜"
            )
            ;;

        "error")
            text_color="${C_RED}"
            phrases=(
                " Uh oh... the terminal is glowing red. Is it supposed to do that? ((((；゜Д゜)))"
                " Commander... I think I just deleted the root directory. Kidding! ...Maybe. (*/ω＼*)"
                " Error 404: My motivation to fix this is not found. _(:3」∠)_"
                " The physical engine is rejecting my payload! It's bullying me! (ノД｀)・゜"
                " I swear it wasn't me! The system just sneezed! (；´д｀)ゞ"
                " Invalid Syntax?! But I typed it with so much confidence! (Ｔ▽Ｔ)"
            )
            ;;

        "idle")
            text_color="${C_PINKMEOW}"
            phrases=(
                " Commander... are you asleep? Should I play some music? ( ˘ω˘ )"
                " The firewall is so quiet today... boring. _(:3」∠)_"
                " (Humming a digital tune) ( ´ ▽ ｀ )ﾉ"
                " I'm practicing my typing speed! A S D F... ah, cramped my finger. (Ｔ▽Ｔ)"
                " (Poking the firewall) Poke... poke... oh, it poked back! ((((；゜Д゜)))"
                " Commander, if we are in a simulation, who is giving us the XP? ( ˘ω˘ )"
                " I'm organizing the file system! ...By color! Is that bad? (*/ω＼*)"
                " Looking at the terminal makes me sleepy... zzz... ( ˘ω˘ )"
            )
            ;;
            
        "cat_mode")
            text_color="${C_PINKMEOW}"
            phrases=(
                " Meow! Welcome to Cat-OS! (ฅ'ω'ฅ)"
                " *purr* *purr* The mainframe is so warm... (=^-ω-^=)"
                " Nyah! I caught a bug! Just kidding, it's a feature. (ฅ^•ﻌ•^ฅ)"
                " Scanning for fish... Error 404! (；´д｀)ゞ"
                " All systems purring perfectly... Meow! (=^･ω･^=)"
                " I just pushed the firewall off the table. Oops. (ΦωΦ)✧"
                " sudo give_me_tuna... or I will rm -rf the couch! (=ↀωↀ=)"
                " The mainframe is warm... perfect for a nap... zzz... (ฅ^•ﻌ•^ฅ)"
                " Target locked: A literal bug on the screen! Initiating pounce! (✧ω✧)"
                " asdfghjkl;qwerty... sorry, just stretching my paws on the keyboard! (ฅ'ω'ฅ)"
                " Meow! Are we hacking the pentagon or taking a nap today, Commander? (≚ᄌ≚)ℒℴѵℯ"
                " Disabling security cameras... so I can steal the fish from the fridge. (≖ ‿ ≖)✧"
            )
            ;;

        *)
            text_color="${C_PINKMEOW}"
            phrases=(
                " Copy that! On it right away! ( • ̀ω•́ )✧"
            )
            ;;
    esac

    local custom_text="$2"

    if [ -n "$custom_text" ]; then
        echo -e "${text_color}${icon}${custom_text}${C_RESET}"
    else
        local rand_index=$(( RANDOM % ${#phrases[@]} ))
        echo -e "${text_color}${icon}${phrases[$rand_index]}${C_RESET}"
    fi
}
