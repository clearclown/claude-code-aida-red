# /aida:queue - Enhancement Queue Management

Manage parallel enhancement tasks with isolated environments.

## Usage

```
/aida:queue add <project> <description>  # Add to queue
/aida:queue list                         # List all items
/aida:queue next                         # Get next item
/aida:queue start <id>                   # Start working
/aida:queue complete <id>                # Mark complete
/aida:queue status                       # Show status
```

## Workflow

### 1. Queue Multiple Enhancements

```bash
./scripts/enhancement-queue.sh add myapp "Add authentication"
./scripts/enhancement-queue.sh add myapp "Implement caching"
./scripts/enhancement-queue.sh add myapp "Add rate limiting"
```

### 2. Work Through Queue

```bash
# Get next item
./scripts/enhancement-queue.sh next

# Start working (creates isolated worktree)
./scripts/enhancement-queue.sh start 1

# Work in isolation
cd .aida/worktrees/enhance-1
# ... make changes ...

# Complete and cleanup
./scripts/enhancement-queue.sh complete 1
```

## Parallel Execution

With jj worktrees, multiple agents can work on different queue items simultaneously:

```
Agent 1                    Agent 2                    Agent 3
---------                  ---------                  ---------
start 1                    start 2                    start 3
cd enhance-1/              cd enhance-2/              cd enhance-3/
# work on auth             # work on cache            # work on rate-limit
complete 1                 complete 2                 complete 3
```

## Queue Status

```bash
./scripts/enhancement-queue.sh status
```

Output:
```
=== Queue Status ===

Total: 5
Pending: 2
In Progress: 1
Completed: 2
Cancelled: 0

Currently active:
  #3 - myapp: Add rate limiting
```

## Benefits

1. **Organization**: Track all enhancements in one place
2. **Isolation**: Each enhancement has its own worktree
3. **Parallel**: Multiple enhancements can run concurrently
4. **Cleanup**: Automatic worktree deletion on completion
5. **History**: Track what was completed and when
