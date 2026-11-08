# TAMAGUMI 雲端／本機開發交接清單

更新日期：2026-11-08（台北時間）。本文件供使用者、本機 Codex、雲端 Codex 及協作代理接續工作。

## 1. 接手時先讀

- GitHub： https://github.com/mayuzumitsugumi/TAMAGUMI_GAME
- 目前開發分支：`codex/web-foundation`；不要假設 `main` 已包含原型。
- 原型起始提交：`0ab844c`。後續以 `git log`、`git status` 和遠端分支為準。
- 雲端工作區：`/workspace/TAMAGUMI_GAME`；本機路徑由使用者自行選定。
- 本交接文件的決策優先於舊 `DEVELOPMENT_PLAN.md` 中「Android 優先」等過時敘述。
- 使用者為決策者；執行總監 GPT-6.1 Sol 輕度、工程師 GPT-6.1 Sol 輕度、檢查員 GPT-6 Luna。代理是否存在須於新工作階段重新確認。

## 2. 最新方向

- 網頁優先：先驗證 Godot Web，候選公開方式為公開 Repo＋GitHub Pages；之後製作 Android APK。
- Godot Standard／GDScript，Compatibility renderer、Web 單執行緒。
- 遊戲離線運作，進度保存在玩家裝置；不託管玩家養成資料、不使用廣告。
- 共用版本化 JSON 備份：瀏覽器、未來 APK 可互相還原。
- 玩家需要下載／匯入備份，以及日後直接備份到自己的 GitHub Repo 兩種方式。
- GitHub 帳號授權與 Repo 寫入尚未實作；Pages 本身不能替玩家完成此事。不得把 Token 或 OAuth secret 放入公開前端。
- ESP32-S3 四按鍵小智 AI 成品板已到貨，先作獨立離線寵物研究；是否可共用核心／資料格式，待硬體辨識後決定。不能假設可直接執行 Godot。
- 兌換碼／NFC／QR 解鎖角色造型與場景屬後期範圍。

## 3. 現有程式與驗證狀態

| 資源 | 目前內容／狀態 |
|---|---|
| `project.godot`、`scenes/main.tscn` | Godot 4.6.x 基礎專案、直式佔位介面 |
| `scripts/pet_state.gd` | 原型資料與玩耍／休息操作，數值是測試資料，並非完整養成實作 |
| `scripts/save_store.gd` | JSON 本機保存、上一份備份、匯入驗證基礎 |
| `scripts/main.gd` | 操作、顯示、Web 備份匯出與檔案回呼 |
| `web/index.html` | Godot 自訂 HTML shell，包含瀏覽器檔案選取入口 |
| `export_presets.cfg` | Web／PWA 匯出候選設定，manifest／service worker 由 Godot 產生 |
| `.github/workflows/web-build.yml` | Push／PR 建置 Web artifact；未配置公開 Pages 部署 |

已執行：Godot 4.6.3 headless 編輯器載入及原型啟動、文件差異空白檢查。
未確認：GitHub Actions 實際成功結果、完整 Web 匯出、瀏覽器操作、IndexedDB 落盤、PWA 離線／更新、Safari／Android 真機、APK、OAuth 備份、ESP32。

不得將「headless 能啟動」當成「手機網頁版驗收通過」。程式內暫用的離線衰退及初始數值也不能視為正式規則。

## 4. 已討論的角色與養成規格

- 同一角色：蛋→小鳥→長大後解鎖人型；解鎖後可在人與鳥之間切換。
- 形象為台灣紫嘯鶇與使用者的人型角色。角色單格暫定128×128；鳥形與人型各有動畫模板。
- 穿搭至少基底、髮型、服裝三層；前後配件與遮擋需要額外層位設計。
- 互動：餵食、餵水、摸頭、睡眠、運動、遊戲、學習。食物以果實造型軟糖為主題。
- 可設定生活提醒、活動排程與專注計時；睡眠可配合起床時間，定時醒來及提醒。
- 體力上限100；每睡1分鐘恢復 `25/60` 點，睡眠可分段累計，保留小數精度。吃飯和喝水亦能補體力，份量未定。
- 最近24小時吃飯至少2次、喝水至少2次、累計睡眠至少240分鐘。任一不足引發該項暴躁。
- 最近48小時未吃飯、未喝水，或睡眠累計未達240分鐘，引發該項萎靡；吃飯／喝水的48小時計次精確邊界仍需確認。
- 進入暴躁情緒下降10%，進入萎靡下降20%；吃飯、喝水、睡眠三項可以累加。
- 超過一週未登入回到蛋，重新培養。

尚未經使用者明確定案：情緒百分比基準、同項暴躁升萎靡的追加扣法、是否只在狀態轉換扣一次、需求補足後是否返還情緒；先前助理提出的計算方式不視為已批准。

其他待定：孵化及人型解鎖條件、新生寬限期、餵食／喝水有效次數間隔、體力消耗、情緒恢復、活動獎勵、回蛋保留項目、睡眠自動起床與貪睡細節。

## 5. 本機接手 ESP32：先辨識，再修改

雲端環境沒有使用者電腦的 USB 轉接，本輪未偵測到 ttyUSB／ttyACM；使用者允許存取不會自動建立 USB 通道。

需要由本機環境讀取，初步只做不改寫操作：

- [ ] 確認 Windows／macOS／Linux、本機 Codex／終端可用性。
- [ ] 記錄商品連結、板型、PCB 字樣與原廠文件。
- [ ] 辨識 USB VID／PID 與序列埠名稱。
- [ ] 查晶片型號、Flash／PSRAM 容量、韌體版本及啟動紀錄。
- [ ] 查螢幕驅動、解析度、四鍵 GPIO、音訊、電池與 USB 接線。
- [ ] 核對小智韌體來源、設定方式、原廠恢復映像與刷寫流程。
- [ ] 若設備允許，讀取原始 Flash 備份並於本機安全保存；紀錄範圍、工具版本、檔案大小與雜湊。
- [ ] 核對是否啟用 Flash encryption／Secure Boot，不能假設備份一定能刷回。
- [ ] 資料充分後再提出可恢復的原型方案，刷寫前與使用者確認具體映像及恢復路徑。

即使只連序列埠，工具的 DTR／RTS 也可能重啟開發板，讀取前需說明。不要猜 GPIO、不要按模糊教學擦除整片 Flash。

原始 Flash、Wi-Fi 設定、裝置身分、Token、私人金鑰及使用者語音等資料不可提交至公開 GitHub。

## 6. 雲端與電腦雙邊備份／接續流程

程式與文件以 GitHub 為共同來源；Git 不是工作中自動同步，也不是所有硬體資料的備份。

### 第一次在本機取得專案

```sh
git clone https://github.com/mayuzumitsugumi/TAMAGUMI_GAME.git
cd TAMAGUMI_GAME
git switch codex/web-foundation
git status --short
```

### 每次開始工作

```sh
git status --short
git fetch origin
git pull --ff-only
```

有未提交改動時先確認來源，不直接 reset／覆蓋。遠端分歧時先查看 log，保留兩邊工作再處理。
切換電腦／雲端前先提交、推送並核對提交雜湊；另一端拉取後再開始。同時作業應各開分支，不用 force push 覆蓋對方。

### 每次交接紀錄

- 日期、操作端（雲端／本機）、分支、commit。
- 完成項目、未完成項目、修改檔案與必要決策。
- 實際執行命令、結果與未測平台。
- 本機專用資料所在位置的描述，不填憑證內容。
- 下個操作與可能造成資料變動的步驟。

### 備份位置分工

| 內容 | GitHub | 本機額外備份 |
|---|---|---|
| 程式、設定範例、規格、非敏感板型資料 | 是 | clone保留 |
| 正式美術原始檔 | 定案授權／容量後選擇，可另用私有空間 | 必須 |
| `.godot` 快取與 build 產物 | 不提交；測試包可用Actions artifact | 可重建 |
| ESP32原始Flash與裝置設定 | 不公開 | 至少本機＋使用者自有安全儲存 |
| API Token、OAuth secret、簽署金鑰 | 不提交 | 系統安全儲存／使用者私有備份 |
| 玩家養成備份 | 不提交到開發專案 | 玩家自行保管 |

目前`.gitignore`不是敏感資料偵測器，提交前仍需查看 staged diff 與檔案清單。

## 7. 接下來的工作順序

1. 確認GitHub Actions結果，完成Web export及瀏覽器最小驗證。
2. 修正本機保存可靠性、匯入前確認與錯誤恢復，再做PWA離線／更新驗證。
3. 將本文件列出的正式養成規則另寫成確認規格，測試數值保持明確標記。
4. 網頁流程穩定後加入Android原生檔案與提醒。iOS真機由使用者朋友協助。
5. GitHub玩家備份待授權方案確定後獨立整合；不以公開Repo保存玩家私密資料。
6. 本機辨識ESP32硬體及備份現有韌體，再評估與網頁／APK共用的範圍。

## 8. 參考來源

- Hanhaechi： https://github.com/hanhaechi/tamagotchi-project （架構參考）
- SleepTamagotchi： https://github.com/aaronzzheng/SleepTamagotchi （時間及保存設計參考）
- Luvvy Lambs： https://github.com/Saupernova13/luvvy-lambs-game （需求／動畫分工參考）
- Open-Meets： https://github.com/kanatallow/Open-Meets （APK使用流程與說明文件參考；未公開App源碼）
- Clock： https://github.com/yassineAbou/Clock （Android鬧鐘參考）

上述只作設計參考；未直接導入其程式與素材。引入第三方元件時另外核對授權。
