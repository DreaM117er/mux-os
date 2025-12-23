# Mux-OS
> *The Android Neural Link / A Personal Cyberdeck Environment*

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Termux-black?style=flat-square)
![Root](https://img.shields.io/badge/Root-Not%20Required-success?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

## 設計哲學 (Philosophy)

Termux 是一套類似 Linux 的終端機，但礙於 Android 核心限制，它只有「沙盒（Sandbox）」的功能。我們被強制鎖在這個小空間中，雖然安全，但總覺得少了點什麼。

**Mux-OS 是什麼？**

它是一套建立在 Android 核心周圍運轉的 **「指令模擬呼叫器 (Command Simulator)」**。
它以直覺、人性化、簡化的指令，達到「無縫接軌」的效率。它會讓你產生一種錯覺：「我彷彿真的在手機裡操作一套完整的 Linux OS」。

### 核心亮點
* **No Root Required**: 不需要刷機，只要有 Termux，就能像傻瓜一樣使用。
* **Intuitive**: 指令直覺化（例如 `wb` 上網, `music` 聽歌）。
* **Self-Healing**: 內建自我修復機制，系統衝突一鍵重置。

## 開發者筆記 (Developer's Note)

> "我的腦袋思維模式跟一般人不太一樣..."

Mux-OS 的誕生，源於我與 AI (Gemini) 的一場關於 Termux 的辯論。我從中提煉出了 5 個邏輯點，構成了這套系統的骨架：

1.  **Termux 是個沙盒** -> 但我們可以裝飾這個籠子。
2.  **函數可以代替指令** -> 因爲 Linux 就是這個原則。
3.  **指令要夠直覺** -> 能夠盲打的指令，才是好指令。
4.  **善用 Android 原生 APP** -> 既然手機裡都有裝，何不直接呼叫它們？
5.  **GitHub 是最佳的更新源** -> 讓腳本具備雲端同步能力。

這造就了 Mux-OS 的六大特性：
* **直覺化**：輸入 `google termux`，直接喚醒瀏覽器搜尋。
* **自動化**：不只是執行，還包含錯誤偵測。
* **傻瓜化**：只做「安裝」、「執行」、「使用」、「自定義」。
* **永續性**：不依賴特定手機型號，換手機也能用。
* **擴充性**：`plugins` (廠牌適配) + `app` (個人化) 分層架構。
* **自我修復**：Git 衝突？版本錯誤？一個 `mux reset` 指令全部搞定。

## 操作界面 (Interface)

**系統啟動與狀態檢查**
*(Mux-OS 啟動時的綠色檢查清單，與版本號顯示)*
<p align="left">
  <img src="pic/startup.png" alt="Mux-OS Startup" width="400" />
</p>

**自我修復機制 (Self-Healing in Action)**
*(展示 Update 衝突後，系統建議 Reset 並成功修復的過程)*
<p align="left">
  <img src="pic/reset.png" alt="Mux-OS Self-Healing" width="400" />
</p>

## 安裝教學 (Installation)

只需要一行指令，Mux-OS 就會自動偵測你的裝置品牌 (Samsung/Xiaomi/Asus...) 並完成配置。

### 1. 前置需求
請確保你使用的是 **GitHub 版本** 或  **F-Droid 版本** 的 Termux (Google Play 版本已停止維護)。

### 2. 下載與部署
在 Termux 中輸入以下指令：

```bash
pkg update && pkg install git -y
gh repo clone DreaM117er/mux-os
cd mux-os
```
*(安裝Git、把Mux-OS下載下來)*

### 3. 啓動系統

```bash
source ~/mux-os/core.sh
```
*(第一次執行core會將需要的功能做引導式的安裝，請照著指示操作即可。)*

## 使用指南 (Usage)

### Mux-OS 的核心指令是 mux。

- `mux menu`: 叫出圖形化指令儀表板 (Dashboard)。
- `mux update`: 檢查並更新系統。
- `mux reset`: [危險] 強制重置系統至原廠設定（修復所有錯誤）。

### 常用快捷鍵 (Examples)

- `wb` : 開啟瀏覽器 (Neural Link)。
- `wb <內容> `: 預設 瀏覽器啓動 + 搜尋。
- `wifi` : 開啟 Wi-Fi 設定。
- `apklist` : 列出手機內所有 App 的 Package Name。

### 自定義（Customization）

- `app.sh`: 在這裡新增你自己的 App 快捷鍵。
- `plugins/<手機廠牌>.sh`: 跟隨手機廠牌邏輯。
- `system.sh`: 系統底層邏輯（不建議隨意更動）。

*Mux-OS 的強大在於它的可塑性，可以按照下列的模板直接修改再貼入 app.sh 裡面。*

```bash
# === 綠色功能大標題 ===

# : APP功能註解
function custom_command() {
    _require_no_args "$@" || return 1
    _launch_android_app "custom_app_name" "可藉由apklist指令獲得（Name）" "可藉由apklist指令獲得（Activity）"
}
```

## 致謝 (Credits)
- Core Logic: DreamM117er。
- Co-Pilot / Architect: Google Gemini
- Platform: Termux Team