# AIDA 插件 for Claude Code

**AIDA** (Agent Integration & Development Architecture) - Claude Code 多代理编排框架

[English](../../README.md) | [日本語](README_ja.md) | 简体中文 | [繁體中文](README_zh-TW.md) | [Русский](README_ru.md) | [فارسی](README_fa.md) | [العربية](README_ar.md)

## 概述

AIDA 为软件开发项目提供多代理编排功能：

- **新项目生成**：从自然语言描述生成完整项目
- **现有项目增强**：为现有项目添加新功能
- **项目维护**：依赖更新、安全审计、质量改进
- **外部项目导入**：导入和分析 GitHub/GitLab 仓库

<p align="center">
  <img src="../pics/architecture.svg" alt="AIDA 架构" width="600">
</p>

## 快速开始

### 安装

**一键安装（推荐）**

```bash
curl -fsSL https://raw.githubusercontent.com/clearclown/claude-code-aida/main/scripts/install.sh | bash
```

**手动安装**

```bash
# 克隆仓库
git clone https://github.com/clearclown/claude-code-aida.git
cd claude-code-aida

# 运行安装脚本
./scripts/install.sh
```

**验证安装**

```bash
./scripts/test-aida.sh --quick
```

### 基本用法

```bash
# 初始化 AIDA 工作区
/aida:init

# 生成新项目
/aida:pipeline "创建一个 Twitter 克隆应用"

# 增强现有项目
/aida:enhance /path/to/project "添加用户认证"

# 查看状态
/aida:status
```

## 命令

### 项目生成（新项目）

| 命令 | 描述 |
|------|------|
| `/aida:init` | 初始化 AIDA 目录结构 |
| `/aida:start <描述>` | 启动新的多代理流水线 |
| `/aida:status` | 显示当前会话状态 |
| `/aida:work` | 执行当前阶段任务 |
| `/aida:pipeline <描述>` | 运行完全自动化流水线 |

### 现有项目支持

| 命令 | 描述 |
|------|------|
| `/aida:analyze <路径>` | 分析项目结构、技术栈、质量 |
| `/aida:import <路径\|URL>` | 导入外部项目到 AIDA 管理 |
| `/aida:enhance <路径> [规格]` | 使用文档或自然语言增强项目 |
| `/aida:maintain <路径> [选项]` | 维护任务（依赖、安全、质量） |

### 维护选项

```bash
# 更新依赖
/aida:maintain /path/to/project --update-deps

# 安全审计
/aida:maintain /path/to/project --security

# 质量改进
/aida:maintain /path/to/project --improve

# 修复失败的测试
/aida:maintain /path/to/project --fix-tests

# 处理 GitHub Issue
/aida:maintain /path/to/project --issue https://github.com/org/repo/issues/123
```

## 架构

### 代理角色

| 代理 | 角色 |
|------|------|
| **Conductor** | 编排整个流水线，指挥 Leaders |
| **Leader-Spec** | 处理规格阶段（需求、设计） |
| **Leader-Impl** | 处理实现阶段（基于 TDD 的开发） |
| **Leader-Enhance** | 处理现有项目的增强规格 |
| **Player** | 专业工作者（Backend、Frontend、Docker） |

## 5 阶段工作流

<p align="center">
  <img src="../pics/workflow.svg" alt="工作流" width="700">
</p>

| 阶段 | 名称 | 描述 |
|------|------|------|
| 1 | 提取与架构 | 需求提取、架构设计 |
| 2 | 结构与模式 | 目录结构、数据模式定义 |
| 3 | 对齐 | 需求一致性检查 |
| 4 | 验证 | 计划验证、识别修订 |
| 5 | 实现 | 带质量门的 TDD 开发 |

## 语言支持

AIDA 自动检测并支持多种语言：

| 语言 | 检测方式 | 测试框架 |
|------|----------|----------|
| Go | `go.mod` | `go test` |
| TypeScript/JavaScript | `package.json` | Jest, Vitest |
| Python | `pyproject.toml`, `requirements.txt` | pytest |
| Rust | `Cargo.toml` | `cargo test` |
| Java | `pom.xml`, `build.gradle` | JUnit, Maven/Gradle |
| Ruby | `Gemfile` | RSpec |
| C# | `*.csproj` | dotnet test |
| PHP | `composer.json` | PHPUnit |

## 质量门

### 新项目门（10 个门）

| 门 | 名称 | 验证 |
|----|------|------|
| 1 | 后端构建 | `go build ./...` |
| 2 | 后端测试 | `go test ./...` |
| 3 | 前端构建 | `npm run build` |
| 4 | 前端测试 | `npm test -- --run` |
| 5 | Docker 构建 | `docker compose build` |
| 6 | Docker 运行 | `docker compose up -d` |
| 7 | 健康检查 | `curl localhost:8080/health` |
| 8 | API 覆盖 | 3+ 处理器文件，10+ 函数 |
| 9 | 前端覆盖 | 3+ 页面，路由，API 客户端 |
| 10 | 集成 | API 客户端，CORS，Docker 链接 |

## TDD 协议

<p align="center">
  <img src="../pics/tdd-cycle.svg" alt="TDD 循环" width="300">
</p>

所有实现遵循严格的 TDD：

1. **RED**：首先编写失败的测试
2. **GREEN**：编写最少代码使测试通过
3. **REFACTOR**：在测试通过的情况下清理代码

没有测试就没有代码。不运行测试就没有测试。

## 脚本

| 脚本 | 描述 |
|------|------|
| `scripts/install.sh` | 一键安装 |
| `scripts/test-aida.sh` | AIDA 自测 |
| `scripts/quality-gates.sh` | 新项目质量门 |
| `scripts/enhance-quality-gates.sh` | 增强质量门 |
| `scripts/analyze-project.sh` | 项目分析 |
| `scripts/checkpoint.sh` | 保存/恢复会话状态 |

## 容器运行时

AIDA 同时支持 Docker 和 Podman：

```bash
# 自动检测 podman 或 docker

# 强制使用 Podman
export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
./scripts/quality-gates.sh myproject
```

## 许可证

MIT

## 致谢与鸣谢

### 核心技术

| 项目 | 作者 | 角色 |
|------|------|------|
| [zoltraak](https://github.com/dai-motoki/zoltraak) | [@dai-motoki](https://github.com/dai-motoki) | 需求生成 |
| [cc-sdd](https://github.com/gotalab/cc-sdd) | [@gotalab](https://github.com/gotalab) | 规格驱动开发 |
| [claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) | [@Chachamaru127](https://github.com/Chachamaru127) | TDD 框架 |
| orchestrobot (aida-cli) | [@kent8192](https://github.com/kent8192) | 多代理编排 |

### 基础设施

| 项目 | 许可证 |
|------|--------|
| [Claude Code](https://github.com/anthropics/claude-code) | Anthropic |
| [Redis](https://redis.io/) | BSD-3-Clause |
| [tmux](https://github.com/tmux/tmux) | ISC |
| [Podman](https://podman.io/) | Apache 2.0 |

### 特别感谢

- [Anthropic](https://www.anthropic.com/) - Claude 的创造者
- 所有帮助改进此项目的贡献者和测试者

## 链接

- [GitHub 仓库](https://github.com/clearclown/claude-code-aida)
- [Issues](https://github.com/clearclown/claude-code-aida/issues)
