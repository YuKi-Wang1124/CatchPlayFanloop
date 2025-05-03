## 🧱 專案架構 & 技術細節

- 架構模式：MVVM
- 播放引擎：AVQueuePlayer + AVPlayerLooper
- 播放邏輯：結合 scrollView 偵測與 Cell 可視區判斷
- 資料綁定：Combine (`@Published` + `.sink`)
- 使用自定義的 UserDefaults extension 管理靜音狀態
- 使用泛型 dequeue 擴充簡化 Cell 建構

---

## 🧪 測試設計

- 驗證當多個影片 Cell 同時可見時，能正確找出「畫面佔比最大」的那個 Cell 作為播放目標。

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

