# TAMAGUMI_GAME

像素電子寵物遊戲，目前以 Godot Web 為優先技術原型，後續製作 Android APK。兩平台預留共用備份格式；ESP32-S3 到貨後另行評估。

目前有基礎 Godot 專案與佔位介面。測試數值並非正式養成規則，尚未完成手機瀏覽器驗證。

## 開發環境

使用 Godot **4.6.3 Standard**（GDScript，非 .NET），開啟 `project.godot` 後按 F6/F5 執行。所有正式美術與玩法都可稍後替換。

安裝同版本 export templates 後：

```sh
godot --headless --editor --path . --quit
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8080 --directory build/web
```

開啟 http://localhost:8080 。不可直接以 file:// 開啟匯出檔。PWA manifest 與 service worker 由 Godot 產生；離線可用性仍需瀏覽器驗證。

## GitHub 建置

Push／Pull Request 會觸發 Web 建置，Actions 產物為 `tamagumi-web-prototype`。此流程只產生測試包，不自動發布 Pages。GitHub OAuth 備份、Android 原生功能及 ESP32 均未完成。

Godot 快取、建置包、環境憑證與簽署金鑰不進版本庫。請勿把玩家備份或 Token 提交到公開專案。

- [最低成本開發架構、流程與進度核對](docs/DEVELOPMENT_PLAN.md)
- [雲端／本機交接清單與 ESP32 接手步驟（最新決策）](docs/HANDOFF.md)

養成規則與正式介面另行討論；兌換機制暫不納入第一階段。
