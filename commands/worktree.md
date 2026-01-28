# /aida:worktree - Environment Isolation

Manage isolated work environments using jj (Jujutsu).

## Usage

```
/aida:worktree create <name>   # Create new worktree
/aida:worktree list            # List all worktrees
/aida:worktree switch <name>   # Switch to worktree
/aida:worktree delete <name>   # Delete worktree
```

## Prerequisites

1. Install jj if not already installed:
   ```bash
   ./scripts/setup-jj.sh
   ```

2. Initialize jj in your repository:
   ```bash
   ./scripts/setup-jj.sh --init
   ```

## Workflow

### Creating an Isolated Environment

```bash
# Create worktree for a feature
./scripts/jj-worktree.sh create feature-auth

# Switch to it
cd .aida/worktrees/feature-auth

# Work in complete isolation
# All changes are tracked by jj automatically
```

### Completing Work

```bash
# When done, describe your changes
jj describe -m "Implemented auth feature"

# Squash into parent
jj squash

# Return to main workspace
cd /original/path

# Delete worktree
./scripts/jj-worktree.sh delete feature-auth
```

## Why jj?

| Feature | git worktree | jj worktree |
|---------|--------------|-------------|
| Auto-commit | No | Yes |
| Undo any operation | Limited | Full |
| Stash required | Yes | No |
| Conflict handling | Manual | Automatic |
| Operation log | No | Yes |

## Parallel Enhancement Pattern

When working on multiple enhancements simultaneously:

```bash
# Enhancement 1
./scripts/jj-worktree.sh create enhance-api
# Enhancement 2
./scripts/jj-worktree.sh create enhance-ui
# Enhancement 3
./scripts/jj-worktree.sh create enhance-tests

# Work on each independently
# No conflicts, no stashing
```

## Troubleshooting

### jj not installed
```bash
./scripts/setup-jj.sh
```

### Worktree conflicts
```bash
# List current state
jj log

# Resolve with squash or abandon
jj squash  # or jj abandon
```

### Reset to clean state
```bash
jj undo  # Undo last operation
```
