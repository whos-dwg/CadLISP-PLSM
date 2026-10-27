# PLSM 批次聚合線簡化

![PLSM](assets/banner.svg)

[工具儲存庫](https://github.com/whos-dwg/CadLISP-PLSM) · [全部工具索引](https://github.com/whos-dwg/CadLISP-Index)

批次簡化開放且無弧段的 LWPOLYLINE，並回報處理與跳過數量。

| 項目 | 內容 |
| --- | --- |
| 指令 | `PLSM` |
| 檔案 | [PLSimplify_Multi_v1_7.lsp](lsp/PLSimplify_Multi_v1_7.lsp) |
| 分類 | 幾何處理 |
| 狀態 | 來源快照，實機回歸待完成 |
| 授權 | [MIT](LICENSE)，Copyright (c) 2026 whos-dwg |

[安裝](#安裝) · [操作](#操作) · [相依與設定](#相依與設定) · [已知問題](docs/KNOWN_ISSUES.md) · [驗證紀錄](docs/VALIDATION.md)

## 安裝

以 Windows 桌面版 AutoCAD 為目標。原碼使用的 Visual LISP／ActiveX、DCL 或原生命令，需在目標 AutoCAD 版本分別確認；尚未做整包年份、LT、Mac 或其他 CAD 的相容性認證。ActiveX 的平台限制見 [Autodesk](https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-AutoLISP/files/GUID-A0459510-CE7A-4206-9EAA-E25AAB569B20.htm)。

1. 下載並解壓縮本工具到固定位置，先開啟測試圖面。
2. 依公司環境把 `lsp` 資料夾加入需要的支援搜尋路徑與受信任位置。
3. 輸入 `APPLOAD`，載入 `PLSimplify_Multi_v1_7.lsp`；關閉視窗後輸入 `PLSM`。

也可使用完整路徑單獨載入；下列路徑需依實際位置修改：

```lisp
(load "C:/CAD/CadLISP-PLSM/lsp/PLSimplify_Multi_v1_7.lsp")
```

完成驗證後，可將這支 LISP 加入 APPLOAD 的 Startup Suite。請維持既定的 SECURELOAD 政策，使用受信任位置處理載入限制。[SECURELOAD 說明](https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-541566C6-2738-49DD-87C3-C1490E924A02.htm)。

## 操作

1. 輸入 `PLSM`，設定最小頂點距離；0 代表停用近點移除。
2. 輸入正值的最大線偏差，複選 LWPOLYLINE 並按 Enter。
3. 閱讀簡化、未減點、跳過封閉／弧段與錯誤統計，抽查結果。

## 相依與設定

實際指令 `PLSM`；預設近點距離 0、最大線偏差 2。

圖面影響：批次重建符合條件的聚合線。

## 行為與限制

封閉或含 bulge 的線跳過；簡化成功以新物件取代來源。需要保留關聯、擴充資料或原 Handle 時應先驗證重建影響。

## 來源與授權

本工具依維護者確認為自行從零撰寫，或以 AI 協作從零開發。程式與本次文件採 [MIT 授權](LICENSE)，允許使用、修改與再散布，須保留授權及著作權聲明。詳細來源紀錄見 [provenance.json](metadata/provenance.json)。

## 回報與維護

回報時附 AutoCAD 完整版本、命令列錯誤與去識別的重現範例。修改前請閱讀 [CONTRIBUTING](CONTRIBUTING.md)；發行步驟見 [PUBLISHING](docs/PUBLISHING.md)。本工具可獨立維護、下載及發布，不依賴其他 CadLISP 工具儲存庫。
