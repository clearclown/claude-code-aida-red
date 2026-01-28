# AIDA-RED: 防禦性安全測試框架

**AIDA-RED** (Automated Intrusion & Destruction Architecture) - AIDA的紅隊版本

<p align="center">
  <img src="../pics/aida-red-logo.svg" alt="AIDA-RED Logo" width="600">
</p>

[English](../../README.md) | [日本語](README_ja.md) | [简体中文](README_zh-CN.md) | 繁體中文 | [Русский](README_ru.md) | [فارسی](README_fa.md) | [العربية](README_ar.md)

> **「如果它壞了，說明它還沒準備好。」**

---

## 概述

AIDA-RED是一個與[claude-code-aida](https://github.com/clearclown/claude-code-aida)整合的**防禦性安全測試框架**。當AIDA專注於**建構**應用程式時，AIDA-RED專注於**破壞**它們，以便在攻擊者之前發現漏洞。

**核心創新**: AIDA-RED使用運行**Kali Linux**安全工具的**Podman/Docker容器**，由Claude Code進行編排。Claude不編寫攻擊程式碼——它調用經過驗證的開源安全工具並分析其輸出。

### 設計理念

1. **零信任**: 假設每個輸入都是攻擊向量
2. **零模擬**: 攻擊運行中的容器，而非隔離的函數
3. **真實工具**: 使用經過驗證的安全掃描器（nuclei、nikto、nmap），而非自訂漏洞利用
4. **可操作報告**: 每個發現都包含複現步驟和修復建議

---

## 架構

```
┌─────────────────────────────────────────────────────────────────┐
│                        Claude Code                               │
│                    (編排器 & 分析器)                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ /aida:red-  │  │ /aida:red-  │  │ /aida:red-  │              │
│  │    init     │  │   assault   │  │   report    │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
└─────────┼────────────────┼────────────────┼─────────────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Podman / Docker                               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              aida-red-scanner (Kali Linux)                 │ │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │ │
│  │  │ nuclei  │ │  nikto  │ │  nmap   │ │  ffuf   │  ...     │ │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                             │                                    │
│                    aida-red-net (Podman網路)                     │
│                             │                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                 目標應用程式                                │ │
│  │            (您的AIDA生成專案)                               │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 安全工具

AIDA-RED預裝了業界標準安全工具：

| 工具 | 用途 | 使用場景 |
|------|------|----------|
| **[nuclei](https://github.com/projectdiscovery/nuclei)** | 基於範本的漏洞掃描器 | CVE檢測、配置錯誤 |
| **[nikto](https://github.com/sullo/nikto)** | Web伺服器掃描器 | 伺服器配置錯誤、過時軟體 |
| **[nmap](https://nmap.org/)** | 網路掃描器 | 連接埠發現、服務檢測 |
| **[ffuf](https://github.com/ffuf/ffuf)** | Web模糊測試器 | 目錄爆破、參數模糊測試 |
| **[sslscan](https://github.com/rbsec/sslscan)** | SSL/TLS分析器 | 憑證問題、弱密碼 |
| **[sqlmap](https://sqlmap.org/)** | SQL注入檢測器 | 資料庫漏洞（完整版） |
| **[stress-ng](https://github.com/ColinIanKing/stress-ng)** | 壓力測試器 | 資源耗盡測試 |

---

## 安裝

### 前提條件

- **Podman**（推薦）或 **Docker**
- 已安裝AIDA外掛的**Claude Code**

```bash
# 安裝Podman（Ubuntu/Debian）
sudo apt install podman

# 或Docker
sudo apt install docker.io
```

### 安裝AIDA-RED

AIDA-RED包含在AIDA外掛中，無需單獨安裝。

```bash
# 驗證安裝
/aida:red-status
```

### 建構掃描器映像

```bash
# 初始化並建構Kali掃描器容器
/aida:red-init

# 或使用輕量版（建構更快，工具更少）
/aida:red-init --lite
```

**映像大小:**
- 完整版: ~2GB（包含sqlmap、ZAP CLI）
- 輕量版: ~624MB（nuclei、nikto、nmap、ffuf、sslscan）

---

## 使用方法

### 快速開始

```bash
# 1. 使用AIDA建構您的應用程式
/aida "建立一個帶使用者認證的REST API"

# 2. 初始化AIDA-RED掃描器
/aida:red-init --lite

# 3. 對運行中的應用執行安全掃描
/aida:red-assault --target http://localhost:8080

# 4. 查看報告
/aida:red-report
```

### 命令

| 命令 | 描述 |
|------|------|
| `/aida:red-init` | 建構Kali掃描器容器，建立網路 |
| `/aida:red-assault` | 對目標執行安全掃描 |
| `/aida:red-status` | 顯示掃描器狀態和最近發現 |
| `/aida:red-report` | 生成詳細漏洞報告 |
| `/aida:red-cleanup` | 移除容器和網路 |

### 攻擊選項

```bash
# 基本掃描（標準強度）
/aida:red-assault --target http://localhost:8080

# 最大強度（所有工具）
/aida:red-assault --target http://localhost:8080 --intensity maximum

# 僅使用特定工具
/aida:red-assault --target http://localhost:8080 --tools nuclei,nikto

# 掃描AIDA專案（自動檢測運行服務）
/aida:red-assault --target ../my-aida-project
```

### 強度級別

| 級別 | 工具 | 時長 |
|------|------|------|
| `minimum` | nuclei、health-check | ~1分鐘 |
| `standard` | nuclei、nikto、nmap、sslscan | ~5分鐘 |
| `maximum` | 所有工具，包括ffuf、sqlmap | ~15分鐘 |

---

## 輸出範例

```
AIDA-RED 攻擊完成

目標: http://localhost:8080
耗時: 2分34秒
工具: nuclei, nikto, nmap, sslscan

發現:
  嚴重:  0
  高危:  2
  中危:  5
  低危:  3
  資訊:  10

主要問題:
  [高危] 過時的TLS配置 - TLS 1.0已啟用
  [高危] 缺少安全標頭 - 未設定X-Frame-Options
  [中危] 資訊洩露 - 回應標頭中包含伺服器版本
  [中危] 開放連接埠 - 5432連接埠（PostgreSQL）已暴露
  [中危] 目錄列表 - /assets/目錄列表已啟用

完整報告: .aida-red/reports/assault-20260128.json
```

---

## 三個反派（代理人格）

AIDA-RED使用三個專門的「反派」代理來處理不同的攻擊向量：

### The Joker（邏輯模糊器）
生成「技術上有效但邏輯上具有破壞性」的輸入。
- 邊界值、大型負載、Unicode注入
- 競態條件、整數溢位
- 工具: `ffuf`、`nuclei`（模糊測試範本）

### The Shadow（安全破壞者）
發現授權繞過和資料洩露。
- IDOR、權限提升、JWT操縱
- SQL注入、認證繞過
- 工具: `nuclei`、`nikto`、`sqlmap`

### The Chaos（基礎設施破壞者）
破壞環境，而不僅僅是程式碼。
- 容器當機、網路分區
- 資源耗盡、混沌測試
- 工具: `stress-ng`、`nmap`

---

## 與AIDA整合

AIDA-RED自動與AIDA的工作流程整合：

1. **自動觸發**: 當AIDA完成（品質閘門通過）時，AIDA-RED建議執行安全掃描

2. **證據注入**: 發現會寫入`.aida/tdd-evidence/external-bugs/`，導致AIDA的品質閘門**失敗**，直到問題被修復

3. **持續迴圈**: 修復漏洞 → AIDA重建 → AIDA-RED再次掃描 → 重複直到清潔

```
AIDA建構完成
        ↓
AIDA-RED掃描
        ↓
發現漏洞? ─── 否 ───→ 完成！
        │
       是
        ↓
注入AIDA證據
        ↓
AIDA品質閘門失敗
        ↓
開發者修復問題
        ↓
AIDA重建 → 迴圈
```

---

## 安全考量

AIDA-RED設計用於您自己應用程式的**防禦性安全測試**：

- 僅掃描您擁有或有權限測試的應用程式
- 未經授權請勿用於生產系統
- 結果可能包含誤報 - 手動驗證發現
- 某些工具（sqlmap）可能修改資料 - 謹慎使用

---

## 授權條款

MIT授權條款 - 請負責任地使用。您對這些工具的使用方式負責。
