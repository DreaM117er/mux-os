|![](pic/logo.png)|![](pic/startup.png)|
|---|---|
|![](pic/reset.png)||

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Termux-black?style=flat-square)
![Root](https://img.shields.io/badge/Root-Not%20Required-success?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

> *The Android Neural Link / A Personal Cyberdeck Environment*

```bash

  __  __                  ___  ____  
 |  \/  |_   ___  __     / _ \/ ___| 
 | |\/| | | | \ \/ /____| | | \___ \ 
 | |  | | |_| |>  <_____| |_| |___) |
 |_|  |_|\__,_/_/\_\     \___/|____/ 

 :: Target: Android/Termux :: Multiverse Edition ::
 :: Architect: @DreaM117er :: 


 :: 01. Mission Briefing ::
    ›› 這不是一個普通的 "Shell" 腳本，這是一場關於 AI 與人類共存的實驗...
    ›› Commander (指揮官)：你負責操作屬於自己的 "Mobile Suit"。
    ›› System AI：系統會跟你對話、輔助操作、導向目的地。
    # 前提是你必須建造屬於自己的 神經連結系統 (Neural Link)，才能發揮機體的完整功能。
    ›› Multiverse (多重宇宙)：在你的宇宙裡，你扮演你自己。
    # 可透過 "跳躍 (Warp)" 來到別人的宇宙，體驗其他指揮官的配置，獲取靈感後再回歸你的時間線。


 :: 02. Loading Sequence ::
    ›› 確認機體核心 Mux-OS Core v4.0.0 ... [ONLINE]
    ›› 辨識機體代號... [TARGET_LOCKED]

    # WARNING: 機體不需超頻 (ROOT)，功能可正常使用。

  - ›› 確認神經連結系統 Default... [OFFLINE]
  + ›› 確認多重宇宙跳躍系統... [WARNING]

    # WARNING: 多重宇宙跳躍系統受限，神經連結系統需啓動...
    # (提示: 請執行 mux link 安裝連結系統)

    ›› 啓動機體 AI 系統... [ONL..E]

    # WARNING: 本系統內建 AI 可能會產生隨機的嘲諷與幽默感。這是 Feature，不是 Bug。
    # (本系統 BOT 分別由 Gemini 及 Grok 來產生隨機語句) 


 :: 03. Deployment ::
    ›› 將 Mux-OS 核心注入你的終端機。複製以下指令序列並執行：

# ----------------------------------------
# 準備基礎環境 (Set Environment)
pkg install git ; pkg upgrade
cd ~

# 下載機體藍圖 (Clone Repository)
git clone https://github.com/DreaM117er/mux-os.git

# 進入格納庫
cd mux-os

# 執行初始化協議 (Inject Core Code)
bash setup.sh
# ----------------------------------------

    ›› 最後請按照 setup.sh 裡的指示做安裝。


 :: 04. Basic Command ::
# 基礎操作指令爲 mux 。
    ›› mux help:    動態列出所有的 mux 指令。
    ›› mux menu:    列出連結表單。
                    # 或是神經連結表單 (fzf)。
    ›› mux link:    安裝神經連結系統。
                    # 執行 fzf 選單安裝。
    ›› mux status:  顯示當前機體狀態。
    ›› mux info:    顯示系統版本號及詳細資訊。
    ›› mux update:  針對 app.sh 的版本更新。
    ›› mux reload:  重啓系統界面。
    ›› mux reset:   重置系統。
                    # 自動執行 git reset、git pull 指令來回朔系統。
    ›› mux setup: 安裝、修復、卸載系統。


 :: 05-1. Customization (fork & branch) ::
     ›› 請進入 "Repository" 主頁： "https://github.com/DreaM117er/mux-os" 。
     ›› 點擊 "fork" ，然後輸入你的 "Caommander ID"。
     ›› 再使用 "git clone" 把你 "fork" 出去的 Mux-OS 資料導入到你的本地資料夾進行修改。
     ›› Mux-OS 內執行 "mux warpto" 就可以看到你跟其他人的多重宇宙了。


 :: 05-2. Customization (Basic Command) ::
    ›› 首先執行 "apklist" 查找你要呼叫的應用程式 ("app")，然後查看 "APK_name" 及 "AM" 資訊。
    ›› 針對 "app.sh"，請複製下方的模板：

# ----------------------------------------
# === Menu 綠色功能大標題 ===

# : Menu 功能註解
function command_name() {
    _require_no_args "$@" || return 1
    _launch_android_app "app_name" "填入APK_name資訊" "填入AM資訊"
}
# ----------------------------------------

    ›› 將模板複製到 "app.sh" 裡面進行分類，儲存後使用：

# ----------------------------------------
# 加入已修改資訊及註解：
git add .
git commit -m "修改的內容細節"

# 執行上傳
git push
# ----------------------------------------

    ›› 最後在 Mux-OS 內進行 "mux reset" 即可將指令導出直接啓用。


 :: 05-3. Customization (Plugins Order) ::
# Mux-OS 需要大家的協助幫助，導入各家不同廠牌的原生應用程式，例如： sony.sh、htc.sh 等等。
# 貢獻方式基本跟 05-2 點（Customization Basic Command）一樣，只不過是導入到 plugins 資料夾內。
    ›› 首先執行 "apklist" 查找你要呼叫的應用程式 ("app")，然後查看 "APK_name" 及 "AM" 資訊。
    ›› 在 "plugins" 資料夾內新增一個 "target_device.sh"，請複製下方的模板：

# ----------------------------------------
# target_device.sh 品牌手機全家桶

# === Menu 綠色功能大標題 ===

# : Menu 功能註解
function command_name() {
    _require_no_args "$@" || return 1
    _launch_android_app "app_name" "填入APK_name資訊" "填入AM資訊"
}
# ----------------------------------------

    ›› 完工以後，請將檔案 "push" 上來並發送 "Pull Request"。
    # 一旦確認檔案沒問題，該手機原生應用程式 ("app") 將成爲為 Mux-OS 生態系的一部分。


 :: 06. Multiverse Warp Drive ::
    # 多重宇宙移轉系統: 需要先安裝神經連結系統才能執行。
    ›› 在另一個宇宙端的 Commander，將 "fork" 到本地的資料上傳之後，執行 "mux warpto"。
    ›› 表單會列出可以跳轉的 "Commander ID"，選擇其中一位，然後 "Enter" 確認。
    ›› 系統會自動執行跳轉，跳轉完畢之後操作 "mux reset" 重置系統。
    ›› 重置完畢執行 "mux status" 查看是否跳轉成功。


 :: 07. Message form Architect ::
    ›› "Logic in mind, Hardware in hand. I can't change the world, so I make my own world."
    # 別人是被環境所操控，我反而覺得我要控制環境，因此我打造了一個屬於自己的環境 (Mux-OS)。
    ›› "我發現 Termux 是一個被 Android 限制住的沙盒 (Sandbox)。"
    ›› "我發現了指令 (command) 可以代替函數 (function)。"
    # 因此我使用了最簡潔、直覺的指令，來呼叫APP及特定功能。
    ›› "我發現了 Android 核心底層的意圖 (Intert)。"
    # 然後我架構了它、開發屬於我的機體，然後我想讓這套機體能無限拓展。
    ›› "有生有死、一來一往、非黑即白、陰陽輪轉。"
    # 然後我架構了一個能殺死自己的腳本，怎麼來就怎麼走。
    ›› "你說是不是，Commander？"


 :: 08. Message the END ::
    ›› 邏輯架構： @DreaM117er。
    ›› 執行者： Gemini Pro (核心架構)、Grok (調皮鬼)。
    ›› 未來可能會加入的理工男： Claude AI。

```