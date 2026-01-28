# Claude Code Task Tool Limitations

> **Issue #31**: Claude Code Task ツールはカスタムサブエージェントをサポートしない

## 概要

Claude Code の `Task` ツールは、あらかじめ定義されたサブエージェントタイプのみをサポートしています。カスタムエージェント（例: `player-harness`, `player-impl` など）を直接起動することはできません。

## サポートされているサブエージェントタイプ

```
Task tool subagent_type パラメータで使用可能:

- general-purpose    : 汎用エージェント（マルチステップタスク）
- Explore           : コードベース探索エージェント
- Plan              : 実装計画エージェント
- Bash              : コマンド実行エージェント
```

## 影響

1. **カスタムエージェントは直接spawnできない**
   - AIDAの `player-*`, `leader-*` エージェントは Task ツールで起動不可
   - 全てのエージェント間通信はファイルベースで実装する必要がある

2. **ファイルベース通信の必要性**
   ```
   Agent A → ファイル書き込み → Agent B がファイル読み取り
   ```

## AIDA での回避策

### 1. タスクファイル方式

エージェント間でタスクを伝達するためにファイルを使用:

```bash
# タスク作成
cat > .aida/tasks/task-001.json << 'EOF'
{
  "id": "task-001",
  "type": "implement",
  "title": "Add user authentication",
  "assigned_to": "player-impl-1",
  "status": "pending"
}
EOF
```

### 2. キューシステム

`enhancement-queue.sh` でタスクキューを管理:

```bash
# キューにタスク追加
./scripts/enhancement-queue.sh add "Implement feature X"

# 次のタスクを取得
./scripts/enhancement-queue.sh next
```

### 3. task-seeker.sh によるアクティブなタスク取得

```bash
# エージェントが利用可能であることを通知
./scripts/task-seeker.sh available player-impl-1

# タスクを積極的に探す
./scripts/task-seeker.sh seek player-impl-1
```

### 4. セッション状態の共有

`.aida/state/session.json` でプロジェクト状態を共有:

```json
{
  "project_name": "my-project",
  "current_phase": "IMPL_PHASE",
  "active_tasks": [...],
  "completed_tasks": [...]
}
```

## 通信フロー例

```
┌────────────────┐      ┌──────────────────┐      ┌────────────────┐
│   Conductor    │      │   Task Files     │      │    Player      │
│                │      │                  │      │                │
│ 1. タスク作成   │──────▶│ .aida/tasks/     │──────▶│ 2. タスク読取   │
│                │      │   task-001.json  │      │                │
│                │◀──────│                  │◀──────│ 3. 結果書込み   │
│ 4. 結果確認    │      │ .aida/results/   │      │                │
└────────────────┘      └──────────────────┘      └────────────────┘
```

## ベストプラクティス

1. **標準化されたファイル形式を使用**
   - JSON形式でタスクと結果を記録
   - タイムスタンプを含める

2. **ポーリング間隔の最適化**
   - デフォルト: 3秒間隔
   - リソース状況に応じて調整

3. **エラーハンドリング**
   - タスクファイルのロック機構
   - タイムアウト処理

4. **状態の一貫性**
   - session.json で全体状態を管理
   - 各エージェントは自分の状態のみ更新

## 今後の展望

- Claude Code の将来バージョンでカスタムエージェントサポートを期待
- Plugin システムでのエージェント定義機能の追加を期待

## 関連ファイル

- `scripts/task-seeker.sh` - タスク探索
- `scripts/enhancement-queue.sh` - キュー管理
- `scripts/agent-coordinator.sh` - エージェント調整
- `hooks/stop/subagent-validator.sh` - サブエージェント検証

## 参考

- [Claude Code Plugin Documentation](https://docs.anthropic.com/en/docs/claude-code)
- Issue #31: Task Tool Limitations
