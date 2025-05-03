# 📱 CatchPlayFanloop – CATCHPLAY+ iOS 面試作業

本專案為 CATCHPLAY+ 面試作業，模仿 [Fanloop](https://www.fanloop.com/zh-TW) 首頁的短影音播放體驗，包含影片自動播放、靜音控制、循環播放等功能。

---

## 功能需求

1. **影片播放控制**  
   當第 n+1 支影片在螢幕上出現超過 50% 時，需自動暫停第 n 支影片的播放，並開始播放第 n+1 支影片。

2. **音效控制**  
   點擊 Mute/Unmute 按鈕後，靜音設定需持續生效，直到使用者再次切換。

3. **影片循環播放**  
   每支影片播放完畢後，應自動重複播放（Loop）。

---

## 加分項目

- Commit 歷史清晰、符合良好 git commit 習慣
- 有撰寫 Unit Test

---

# 範例說明

以此影片為例：[A vertical video of a mature couple sharing a lovely moment at the park bench on a sunny day](https://mixkit.co/free-stock-video/a-vertical-video-of-a-mature-couple-sharing-a-lovely-100801/)

- **Title（粗體字）**：  
  `A vertical video of a mature couple sharing a lovely moment at the park bench on a sunny day`

- **Subtitle（正常字體）**：  
  `A vertical video captures a mature couple sitting on a sunlit park bench, sharing a warm, affectionate moment. Surrounded by lush greenery, they smile and chat, radiating joy and connection on a bright, sunny day.`

> **注意：**
> - Title 與 Subtitle 都限制只顯示一行
> - 超過一行時，點擊 Title 或 Subtitle 可展開顯示完整內容

---

## 範例畫面定義

參考圖片：[HackMD 連結](https://hackmd.io/_uploads/BkU1OAu1lx.png)

- 藍教主傳授高成功率... → Title
- 女人我最大... → Subtitle

---

## 🧪 測試設計

- 驗證當多個影片 Cell 同時可見時，能正確找出「畫面佔比最大」的那個 Cell 作為播放目標。

---

## 🧱 專案架構 & 技術細節

- 架構模式：MVVM
- 播放引擎：AVQueuePlayer + AVPlayerLooper
- 播放邏輯：結合 scrollView 偵測與 Cell 可視區判斷
- 資料綁定：Combine (`@Published` + `.sink`)
- 使用自定義的 UserDefaults extension 管理靜音狀態
- 使用泛型 dequeue 擴充簡化 Cell 建構

---

## 🚀 執行方式

1. 使用 Xcode 開啟 `CatchPlayFanloop.xcodeproj`
2. 確保影片資料位於 App Bundle 或下載路徑
3. 點擊 Run，選擇模擬器執行即可瀏覽短影片播放體驗

---

## 📮 聯絡資訊

面試者：王昱淇  
Email: wkiki1124@gmail.com  
GitHub: https://github.com/YuKi-Wang1124

