# AIDA プラグイン for Claude Code

**AIDA** (Agent Integration & Development Architecture) - Claude Code向けマルチエージェントオーケストレーションフレームワーク

[English](../../README.md) | 日本語 | [简体中文](README_zh-CN.md) | [繁體中文](README_zh-TW.md) | [Русский](README_ru.md) | [فارسی](README_fa.md) | [العربية](README_ar.md)

## 概要

AIDAはソフトウェア開発プロジェクト向けのマルチエージェントオーケストレーションを実現します：

- **新規プロジェクト生成**: 自然言語記述から完全なプロジェクトを生成
- **既存プロジェクト拡張**: 新機能で既存プロジェクトを拡張
- **プロジェクトメンテナンス**: 依存関係更新、セキュリティ監査、品質改善
- **外部プロジェクトインポート**: GitHub/GitLabリポジトリのインポートと分析

<p align="center">
  <img src="../pics/architecture.svg" alt="AIDAアーキテクチャ" width="600">
</p>

## クイックスタート

### インストール

**ワンラインインストール（推奨）**

```bash
curl -fsSL https://raw.githubusercontent.com/clearclown/claude-code-aida/main/scripts/install.sh | bash
```

**手動インストール**

```bash
# リポジトリをクローン
git clone https://github.com/clearclown/claude-code-aida.git
cd claude-code-aida

# インストールスクリプトを実行
./scripts/install.sh
```

**インストール確認**

```bash
./scripts/test-aida.sh --quick
```

### 基本的な使い方

```bash
# AIDAワークスペースを初期化
/aida:init

# 新規プロジェクトを生成
/aida:pipeline "Twitterクローンアプリケーションを作成"

# 既存プロジェクトを拡張
/aida:enhance /path/to/project "ユーザー認証を追加"

# ステータスを確認
/aida:status
```

## コマンド

### プロジェクト生成（新規プロジェクト）

| コマンド | 説明 |
|---------|------|
| `/aida:init` | AIDAディレクトリ構造を初期化 |
| `/aida:start <説明>` | 新規マルチエージェントパイプラインを開始 |
| `/aida:status` | 現在のセッションステータスを表示 |
| `/aida:work` | 現在のフェーズタスクを実行 |
| `/aida:pipeline <説明>` | 完全自動パイプラインを実行 |

### 既存プロジェクトサポート

| コマンド | 説明 |
|---------|------|
| `/aida:analyze <パス>` | プロジェクト構造、技術スタック、品質を分析 |
| `/aida:import <パス\|URL>` | 外部プロジェクトをAIDA管理にインポート |
| `/aida:enhance <パス> [仕様]` | ドキュメントまたは自然言語でプロジェクトを拡張 |
| `/aida:maintain <パス> [オプション]` | メンテナンスタスク（依存関係、セキュリティ、品質） |

### メンテナンスオプション

```bash
# 依存関係を更新
/aida:maintain /path/to/project --update-deps

# セキュリティ監査
/aida:maintain /path/to/project --security

# 品質改善
/aida:maintain /path/to/project --improve

# 失敗したテストを修正
/aida:maintain /path/to/project --fix-tests

# GitHub Issueに対応
/aida:maintain /path/to/project --issue https://github.com/org/repo/issues/123
```

## アーキテクチャ

### エージェントの役割

| エージェント | 役割 |
|-------------|------|
| **Conductor** | パイプライン全体をオーケストレーション、Leaderを指揮 |
| **Leader-Spec** | 仕様フェーズを担当（要件、設計） |
| **Leader-Impl** | 実装フェーズを担当（TDDベース開発） |
| **Leader-Enhance** | 既存プロジェクトの拡張仕様を担当 |
| **Player** | 専門ワーカー（Backend、Frontend、Docker） |

## 5フェーズワークフロー

<p align="center">
  <img src="../pics/workflow.svg" alt="ワークフロー" width="700">
</p>

| フェーズ | 名前 | 説明 |
|---------|------|------|
| 1 | 抽出とアーキテクチャ | 要件抽出、アーキテクチャ設計 |
| 2 | 構造とスキーマ | ディレクトリ構造、データスキーマ定義 |
| 3 | アラインメント | 要件の一貫性チェック |
| 4 | 検証 | 計画検証、修正箇所の特定 |
| 5 | 実装 | 品質ゲート付きTDDベース開発 |

## 対応言語

AIDAは複数の言語を自動検出してサポートします：

| 言語 | 検出方法 | テストフレームワーク |
|------|----------|---------------------|
| Go | `go.mod` | `go test` |
| TypeScript/JavaScript | `package.json` | Jest, Vitest |
| Python | `pyproject.toml`, `requirements.txt` | pytest |
| Rust | `Cargo.toml` | `cargo test` |
| Java | `pom.xml`, `build.gradle` | JUnit, Maven/Gradle |
| Ruby | `Gemfile` | RSpec |
| C# | `*.csproj` | dotnet test |
| PHP | `composer.json` | PHPUnit |

## 品質ゲート

### 新規プロジェクトゲート（10ゲート）

| ゲート | 名前 | 検証内容 |
|--------|------|----------|
| 1 | Backendビルド | `go build ./...` |
| 2 | Backendテスト | `go test ./...` |
| 3 | Frontendビルド | `npm run build` |
| 4 | Frontendテスト | `npm test -- --run` |
| 5 | Dockerビルド | `docker compose build` |
| 6 | Docker実行 | `docker compose up -d` |
| 7 | ヘルスチェック | `curl localhost:8080/health` |
| 8 | APIカバレッジ | 3+ハンドラファイル、10+関数 |
| 9 | Frontendカバレッジ | 3+ページ、ルーティング、APIクライアント |
| 10 | 統合 | APIクライアント、CORS、Dockerリンク |

## TDDプロトコル

<p align="center">
  <img src="../pics/tdd-cycle.svg" alt="TDDサイクル" width="300">
</p>

すべての実装は厳格なTDDに従います：

1. **RED**: 最初に失敗するテストを書く
2. **GREEN**: テストをパスする最小限のコード
3. **REFACTOR**: テストがパスしたままクリーンアップ

テストなしのコードは不可。実行しないテストも不可。

## スクリプト

| スクリプト | 説明 |
|-----------|------|
| `scripts/install.sh` | ワンクリックインストール |
| `scripts/test-aida.sh` | AIDAセルフテスト |
| `scripts/quality-gates.sh` | 新規プロジェクト品質ゲート |
| `scripts/enhance-quality-gates.sh` | 拡張品質ゲート |
| `scripts/analyze-project.sh` | プロジェクト分析 |
| `scripts/checkpoint.sh` | セッション状態の保存/復元 |

## コンテナランタイム

AIDAはDockerとPodmanの両方をサポートします：

```bash
# podmanまたはdockerを自動検出

# Podmanを強制
export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
./scripts/quality-gates.sh myproject
```

## ライセンス

MIT

## クレジット・謝辞

### 核心技術

| プロジェクト | 作者 | 役割 |
|-------------|------|------|
| [zoltraak](https://github.com/dai-motoki/zoltraak) | [@dai-motoki](https://github.com/dai-motoki) | 要件生成 |
| [cc-sdd](https://github.com/gotalab/cc-sdd) | [@gotalab](https://github.com/gotalab) | 仕様駆動開発 |
| [claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) | [@Chachamaru127](https://github.com/Chachamaru127) | TDD フレームワーク |
| orchestrobot (aida-cli) | [@kent8192](https://github.com/kent8192) | マルチエージェント |

### インフラストラクチャ

| プロジェクト | ライセンス |
|-------------|-----------|
| [Claude Code](https://github.com/anthropics/claude-code) | Anthropic |
| [Redis](https://redis.io/) | BSD-3-Clause |
| [tmux](https://github.com/tmux/tmux) | ISC |
| [Podman](https://podman.io/) | Apache 2.0 |

### スペシャルサンクス

- [Anthropic](https://www.anthropic.com/) - Claudeの開発元
- このプロジェクトの改善に貢献してくださったすべての貢献者とテスター

## リンク

- [GitHubリポジトリ](https://github.com/clearclown/claude-code-aida)
- [Issues](https://github.com/clearclown/claude-code-aida/issues)
