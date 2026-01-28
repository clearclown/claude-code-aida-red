# AIDA-RED: 防御性安全测试框架

**AIDA-RED** (Automated Intrusion & Destruction Architecture) - AIDA的红队版本

<p align="center">
  <img src="../pics/aida-red-logo.svg" alt="AIDA-RED Logo" width="600">
</p>

[English](../../README.md) | [日本語](README_ja.md) | 简体中文 | [繁體中文](README_zh-TW.md) | [Русский](README_ru.md) | [فارسی](README_fa.md) | [العربية](README_ar.md)

> **"如果它坏了，说明它还没准备好。"**

---

## 概述

AIDA-RED是一个与[claude-code-aida](https://github.com/clearclown/claude-code-aida)集成的**防御性安全测试框架**。当AIDA专注于**构建**应用程序时，AIDA-RED专注于**破坏**它们，以便在攻击者之前发现漏洞。

**核心创新**: AIDA-RED使用运行**Kali Linux**安全工具的**Podman/Docker容器**，由Claude Code进行编排。Claude不编写攻击代码——它调用经过验证的开源安全工具并分析其输出。

### 设计理念

1. **零信任**: 假设每个输入都是攻击向量
2. **零模拟**: 攻击运行中的容器，而非隔离的函数
3. **真实工具**: 使用经过验证的安全扫描器（nuclei、nikto、nmap），而非自定义漏洞利用
4. **可操作报告**: 每个发现都包含复现步骤和修复建议

---

## 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        Claude Code                               │
│                    (编排器 & 分析器)                             │
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
│                    aida-red-net (Podman网络)                     │
│                             │                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                 目标应用程序                                │ │
│  │            (您的AIDA生成项目)                               │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 安全工具

AIDA-RED预装了行业标准安全工具：

| 工具 | 用途 | 使用场景 |
|------|------|----------|
| **[nuclei](https://github.com/projectdiscovery/nuclei)** | 基于模板的漏洞扫描器 | CVE检测、配置错误 |
| **[nikto](https://github.com/sullo/nikto)** | Web服务器扫描器 | 服务器配置错误、过时软件 |
| **[nmap](https://nmap.org/)** | 网络扫描器 | 端口发现、服务检测 |
| **[ffuf](https://github.com/ffuf/ffuf)** | Web模糊测试器 | 目录爆破、参数模糊测试 |
| **[sslscan](https://github.com/rbsec/sslscan)** | SSL/TLS分析器 | 证书问题、弱密码 |
| **[sqlmap](https://sqlmap.org/)** | SQL注入检测器 | 数据库漏洞（完整版） |
| **[stress-ng](https://github.com/ColinIanKing/stress-ng)** | 压力测试器 | 资源耗尽测试 |

---

## 安装

### 前提条件

- **Podman**（推荐）或 **Docker**
- 已安装AIDA插件的**Claude Code**

```bash
# 安装Podman（Ubuntu/Debian）
sudo apt install podman

# 或Docker
sudo apt install docker.io
```

### 安装AIDA-RED

AIDA-RED包含在AIDA插件中，无需单独安装。

```bash
# 验证安装
/aida:red-status
```

### 构建扫描器镜像

```bash
# 初始化并构建Kali扫描器容器
/aida:red-init

# 或使用轻量版（构建更快，工具更少）
/aida:red-init --lite
```

**镜像大小:**
- 完整版: ~2GB（包含sqlmap、ZAP CLI）
- 轻量版: ~624MB（nuclei、nikto、nmap、ffuf、sslscan）

---

## 使用方法

### 快速开始

```bash
# 1. 使用AIDA构建您的应用程序
/aida "创建一个带用户认证的REST API"

# 2. 初始化AIDA-RED扫描器
/aida:red-init --lite

# 3. 对运行中的应用执行安全扫描
/aida:red-assault --target http://localhost:8080

# 4. 查看报告
/aida:red-report
```

### 命令

| 命令 | 描述 |
|------|------|
| `/aida:red-init` | 构建Kali扫描器容器，创建网络 |
| `/aida:red-assault` | 对目标执行安全扫描 |
| `/aida:red-status` | 显示扫描器状态和最近发现 |
| `/aida:red-report` | 生成详细漏洞报告 |
| `/aida:red-cleanup` | 移除容器和网络 |

### 攻击选项

```bash
# 基本扫描（标准强度）
/aida:red-assault --target http://localhost:8080

# 最大强度（所有工具）
/aida:red-assault --target http://localhost:8080 --intensity maximum

# 仅使用特定工具
/aida:red-assault --target http://localhost:8080 --tools nuclei,nikto

# 扫描AIDA项目（自动检测运行服务）
/aida:red-assault --target ../my-aida-project
```

### 强度级别

| 级别 | 工具 | 时长 |
|------|------|------|
| `minimum` | nuclei、health-check | ~1分钟 |
| `standard` | nuclei、nikto、nmap、sslscan | ~5分钟 |
| `maximum` | 所有工具，包括ffuf、sqlmap | ~15分钟 |

---

## 输出示例

```
AIDA-RED 攻击完成

目标: http://localhost:8080
耗时: 2分34秒
工具: nuclei, nikto, nmap, sslscan

发现:
  严重:  0
  高危:  2
  中危:  5
  低危:  3
  信息:  10

主要问题:
  [高危] 过时的TLS配置 - TLS 1.0已启用
  [高危] 缺少安全头 - 未设置X-Frame-Options
  [中危] 信息泄露 - 响应头中包含服务器版本
  [中危] 开放端口 - 5432端口（PostgreSQL）已暴露
  [中危] 目录列表 - /assets/目录列表已启用

完整报告: .aida-red/reports/assault-20260128.json
```

---

## 三个反派（代理人格）

AIDA-RED使用三个专门的"反派"代理来处理不同的攻击向量：

### The Joker（逻辑模糊器）
生成"技术上有效但逻辑上具有破坏性"的输入。
- 边界值、大型负载、Unicode注入
- 竞态条件、整数溢出
- 工具: `ffuf`、`nuclei`（模糊测试模板）

### The Shadow（安全破坏者）
发现授权绕过和数据泄露。
- IDOR、权限提升、JWT操纵
- SQL注入、认证绕过
- 工具: `nuclei`、`nikto`、`sqlmap`

### The Chaos（基础设施破坏者）
破坏环境，而不仅仅是代码。
- 容器崩溃、网络分区
- 资源耗尽、混沌测试
- 工具: `stress-ng`、`nmap`

---

## 与AIDA集成

AIDA-RED自动与AIDA的工作流集成：

1. **自动触发**: 当AIDA完成（质量门通过）时，AIDA-RED建议执行安全扫描

2. **证据注入**: 发现会写入`.aida/tdd-evidence/external-bugs/`，导致AIDA的质量门**失败**，直到问题被修复

3. **持续循环**: 修复漏洞 → AIDA重建 → AIDA-RED再次扫描 → 重复直到清洁

```
AIDA构建完成
        ↓
AIDA-RED扫描
        ↓
发现漏洞? ─── 否 ───→ 完成！
        │
       是
        ↓
注入AIDA证据
        ↓
AIDA质量门失败
        ↓
开发者修复问题
        ↓
AIDA重建 → 循环
```

---

## 安全考虑

AIDA-RED设计用于您自己应用程序的**防御性安全测试**：

- 仅扫描您拥有或有权限测试的应用程序
- 未经授权请勿用于生产系统
- 结果可能包含误报 - 手动验证发现
- 某些工具（sqlmap）可能修改数据 - 谨慎使用

---

## 许可证

MIT许可证 - 请负责任地使用。您对这些工具的使用方式负责。
