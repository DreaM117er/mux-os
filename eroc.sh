#!/bin/bash
# eroc.sh - Mux-OS 超頻模式 (Overclock Mode)

if [ -z "$MUX_ROOT" ]; then export MUX_ROOT="$HOME/mux-os"; fi
export XUM_DB="$MUX_ROOT/xum.csv"

# 超頻讀取器 (Chamber Reader)
function _xum_neural_read() {
    unset _XUM_SLOT _XUM_PKG _XUM_TARGET _XUM_IHEAD _XUM_IBODY \
          _XUM_URI _XUM_MIME _XUM_CATE1 _XUM_CATE2 _XUM_CATE3 \
          _XUM_EX1 _XUM_TRA1 _XUM_BOO1 _XUM_EX2 _XUM_TRA2 _XUM_BOO2 \
          _XUM_EX3 _XUM_TRA3 _XUM_BOO3 _XUM_EX4 _XUM_TRA4 _XUM_BOO4 \
          _XUM_EX5 _XUM_TRA5 _XUM_BOO5 _XUM_FLAG _XUM_USER _XUM_RDY

    local target_slot="$1"
    local target_file="${2:-$XUM_DB}"

    if [ ! -f "$target_file" ]; then 
        echo -e "\033[1;31m :: ERROR: Chamber database not found.\033[0m" >&2
        return 1
    fi

    local raw_data=$(awk -v FPAT='([^,]*)|("[^"]+")' -v slot="$target_slot" '
        NR > 1 { 
            row_slot = $1; gsub(/^"|"$/, "", row_slot); gsub(/^[ \t]+|[ \t]+$/, "", row_slot)
            if (row_slot == slot) {
                print $0
                exit
            }
        }
    ' "$target_file")

    if [ -z "$raw_data" ]; then return 1; fi

    eval $(echo "$raw_data" | awk -v FPAT='([^,]*)|("[^"]+")' '{
        fields[1]="_XUM_SLOT"; fields[2]="_XUM_PKG"; fields[3]="_XUM_TARGET"
        fields[4]="_XUM_IHEAD"; fields[5]="_XUM_IBODY"; fields[6]="_XUM_URI"
        fields[7]="_XUM_MIME"; fields[8]="_XUM_CATE1"; fields[9]="_XUM_CATE2"; fields[10]="_XUM_CATE3"
        fields[11]="_XUM_EX1"; fields[12]="_XUM_TRA1"; fields[13]="_XUM_BOO1"
        fields[14]="_XUM_EX2"; fields[15]="_XUM_TRA2"; fields[16]="_XUM_BOO2"
        fields[17]="_XUM_EX3"; fields[18]="_XUM_TRA3"; fields[19]="_XUM_BOO3"
        fields[20]="_XUM_EX4"; fields[21]="_XUM_TRA4"; fields[22]="_XUM_BOO4"
        fields[23]="_XUM_EX5"; fields[24]="_XUM_TRA5"; fields[25]="_XUM_BOO5"
        fields[26]="_XUM_FLAG"; fields[27]="_XUM_USER"; fields[28]="_XUM_RDY"

        for (i=1; i<=28; i++) {
            val = $i
            if (val ~ /^".*"$/) { val = substr(val, 2, length(val)-2) }
            gsub(/""/, "\"", val); gsub(/'\''/, "'\''\\'\'''\''", val)
            printf "%s='\''%s'\''; ", fields[i], val
        }
    }')
    
    return 0
}

# 火藥注入器 (Chamber Writer)
function _xum_neural_write() {
    local target_slot="$1"
    local col_idx="$2"
    local new_val="$3"
    local target_file="${4:-$XUM_DB}"

    if [ ! -f "$target_file" ]; then 
        echo -e "\033[1;31m :: ERROR: Chamber database not found.\033[0m" >&2
        return 1
    fi

    # 封裝引號與逃脫字元 (繼承兵工廠安全級別)
    local safe_val="${new_val//\\/\\\\}"
    safe_val="${safe_val//\"/\"\"}"

    # 第 1 欄 (SLOT) 保持純數字，其餘欄位包裹雙引號
    if [[ "$col_idx" == "1" ]]; then
        : 
    else
        if [ -n "$safe_val" ]; then
            safe_val="\"$safe_val\""
        fi
    fi

    # 原子寫入
    awk -v FPAT='([^,]*)|("[^"]+")' -v OFS="," \
        -v tslot="$target_slot" \
        -v col="$col_idx" \
        -v val="$safe_val" '
    {
        if (NR == 1) { print $0; next } # 標題行直接放行

        c = $1; gsub(/^"|"$/, "", c); gsub(/^[ \t]+|[ \t]+$/, "", c)

        if (c == tslot) {
            $col = val
        }
        print $0
    }' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
}

# 超頻系統啟動器 (Overclock System Bootloader)
function _xum_system_boot() {
    _system_lock
    _safe_ui_calc
    
    # 自動生成基礎
    if [ ! -f "$XUM_DB" ]; then
        echo '"SLOT","PKG","TARGET","IHEAD","IBODY","URI","MIME","CATE1","CATE2","CATE3","EX1","TRA1","BOO1","EX2","TRA2","BOO2","EX3","TRA3","BOO3","EX4","TRA4","BOO4","EX5","TRA5","BOO5","FLAG","USER","RDY"' > "$XUM_DB"
        for i in {1..8}; do
            echo "$i,,,,,,,,,,,,,,,,,,,,,,,,\"$USER\",\"N\"" >> "$XUM_DB"
        done
    fi

    clear
    _draw_logo "xum"
    _system_check "xum"
    _show_hud "xum"
    _system_unlock
    _bot_say "hello"
}

function xum() {
    local cmd="$1"
    local arg="$2"

    # 若無指令，預設的視覺回饋或亂碼擋板
    if [ -z "$cmd" ]; then
        return 0
    fi

    # XUM 指令分流閘 (Command Switch)
    case "$cmd" in
        "slot")
            # [切換彈巢]
            # 用法: xum slot <1-8>
            # 功能: 選擇並切換當前的子彈槽位
            ;;
            
        "set")
            # [火藥裝填]
            # 用法: xum set
            # 功能: 進入當前 Slot 的參數編輯模式 (支援 set done 退出)
            ;;
            
        "fire")
            # [發射]
            # 用法: xum fire
            # 功能: 拼裝當前 Slot 的參數並執行 am start，計算發射次數
            ;;
            
        "status")
            # [戰術面板]
            # 用法: xum status
            # 功能: 呼叫 fzf 面板，顯示 1-8 號子彈的 RDY 狀態與內容
            ;;
            
        "info")
            # [機密資訊]
            # 用法: xum info
            # 功能: 顯示 XUM 模組版本與解鎖狀態
            ;;
            
        "reload")
            # [系統重載]
            # 用法: xum reload
            # 功能: 重新讀取環境變數與 csv 狀態，刷新終端機
            ;;
            
        "reset")
            # [強制退膛與冷卻]
            # 用法: xum reset
            # 功能: 結束 XUM 模式，寫入實體雙重時間鎖 (2小時)，並清除快取
            ;;

        "mux")
            _bot_say "success" "TERMINATING OVERCLOCK PROTOCOL. REVERTING TO KERNEL STANDARDS."
            _update_mux_state "MUX" "LOGIN" "COCKPIT"
            _mux_reload_kernel
            ;;
            
        *)
            # [無效操作 / 亂碼屏障]
            # 功能: 所有非預期指令皆被攔截，並回傳亂碼語音
            return 1
            ;;
    esac
}

# 測試函式：驗證讀寫功能
# 僅在直接執行此腳本時運行，如果被 source 則忽略
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo ":: [PROJECT XUM] I/O Test Sequence Initiated ::"
    
    # 測試寫入：將 Slot 1 的 PKG (第 2 欄) 寫入 "com.test.xum"
    echo "› Writing to Slot 1 (Column 2)..."
    _xum_neural_write "1" 2 "com.test.xum"
    
    # 測試寫入：將 Slot 1 的 EX1 (第 11 欄) 寫入 "--es"
    echo "› Writing to Slot 1 (Column 11)..."
    _xum_neural_write "1" 11 "--es"
    
    # 測試讀取：讀出 Slot 1 驗證
    echo "› Reading from Slot 1..."
    _xum_neural_read "1"
    
    echo "---------------------------"
    echo "SLOT : $_XUM_SLOT"
    echo "PKG  : $_XUM_PKG"
    echo "EX1  : $_XUM_EX1"
    echo "RDY  : $_XUM_RDY"
    echo "---------------------------"
    echo ":: Test Complete ::"
fi

