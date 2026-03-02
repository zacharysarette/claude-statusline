# Claude Code Status Line

A two-line adaptive status line for [Claude Code](https://claude.com/claude-code) with ANSI colors, emoji, git integration, and progress bars.

## What It Looks Like

```
🕐 Mon Mar 2 22:10 │ 💎 Max │ ⏳ █████░░░░░░░ 10h49m │ 🤖 Opus 4.6 │ NORMAL
📂 ~/dev/my-project │ 🌿 feature/login ✔ │ 📊 ██░░░░░░░░ 23% │ in: 120k out: 25k │ 💬 "my session"
```

### Line 1 — Identity & Time
| Field | Emoji | Description |
|---|---|---|
| Date + Time | 🕐 | Combined local date and time |
| Plan Tier | 💎 | Your Claude plan (reads `$CLAUDE_PLAN`, defaults to "Max") |
| Reset Countdown | ⏳ | Hours until UTC midnight (plan reset). Green/yellow/red bar |
| Model | 🤖 | Current model name (shortens "Claude " prefix) |
| Vim Mode | — | NORMAL (cyan) or INSERT (green). Always shown |
| Agent | 🔧 | Only shown when using `--agent` flag |
| Output Style | ✨ | Only shown when non-default style is active |

### Line 2 — Workspace & Context
| Field | Emoji | Description |
|---|---|---|
| Working Dir | 📂 | Current directory (shortened with `~`) |
| Git Branch | 🌿 | Branch name + dirty status or ✔ for clean |
| Context Window | 📊 | Usage bar. Green ≤50%, yellow ≤80%, red >80% |
| Tokens | — | Split input/output counts (1k, 250k, 1.5M) |
| Session Name | 💬 | Only shown if session is named |

## Quick Setup

```bash
# 1. Copy the script
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh

# 2. Add to Claude Code settings (~/.claude/settings.json)
# Add this to the top-level object:
#   "statusline_command": "bash ~/.claude/statusline-command.sh"
```

Or ask Claude Code to do it: *"Set up my status line using the script in this repo"* — see [SETUP.md](SETUP.md) for the full agent-friendly guide.

## Requirements

- **Node.js** — used for JSON parsing (no `jq` dependency)
- **Git** — for branch/dirty status (gracefully skipped if not in a git repo)
- **Bash** — Git Bash on Windows, or any standard bash on macOS/Linux

## Customization

### Change your plan tier
Set the `CLAUDE_PLAN` environment variable in your shell profile:
```bash
export CLAUDE_PLAN="Pro"  # or "Max", "Team", etc.
```

### Disable vim mode display
In `statusline-command.sh`, change:
```bash
vim_mode="${vim_mode:-NORMAL}"
```
to:
```bash
vim_mode=""
```

## License

MIT
