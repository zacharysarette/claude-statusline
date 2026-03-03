# Claude Code Status Line

A three-line adaptive status line for [Claude Code](https://claude.com/claude-code) with ANSI colors, emoji, git integration, and progress bars.

## What It Looks Like

```
🕐 Time: Mon Mar 3 14:22 │ 💎 Plan: Team │ ⏳ Reset: █████░░░░░░░ 10h49m │ 🤖 Model: Opus 4.6 │ v1.0.26 │ NORMAL
📂 Dir: ~/dev/my-project │ 🌿 Branch: feature/login ✔ │ 💬 Session: "my session"
📊 Context: ██░░░░░░░░ 23% │ Tokens in: 120k out: 25k │ 💰 Cost: $0.42 │ ⏱ Elapsed: 12m34s │ Lines: +85/-12
```

### Line 1 — Identity & Time
| Field | Emoji | Description |
|---|---|---|
| Date + Time | 🕐 | Combined local date and time |
| Plan Tier | 💎 | Your Claude plan (from API, `$CLAUDE_PLAN` fallback, defaults to "Team") |
| Reset Countdown | ⏳ | Hours until UTC midnight (plan reset). Green/yellow/red bar |
| Model | 🤖 | Current model name (shortens "Claude " prefix) |
| Version | — | Claude Code version (e.g. v1.0.26), shown when available |
| Vim Mode | — | NORMAL (cyan) or INSERT (green). Always shown |
| Agent | 🔧 | Only shown when using `--agent` flag |
| Output Style | ✨ | Only shown when non-default style is active |

### Line 2 — Workspace
| Field | Emoji | Description |
|---|---|---|
| Working Dir | 📂 | Current directory (shortened with `~`, truncated if >50 chars) |
| Git Branch | 🌿 | Branch name + dirty status (M/D/?) or ✔ for clean |
| Session Name | 💬 | Only shown if session is named |

### Line 3 — Metrics
| Field | Emoji | Description |
|---|---|---|
| Context Window | 📊 | Usage bar. Green ≤50%, yellow ≤80%, red >80% |
| Tokens | — | Split input/output counts (1k, 250k, 1.5M) |
| Cost | 💰 | Session cost in USD (from API) |
| Elapsed | ⏱ | Session duration (from API) |
| Lines Changed | — | Lines added/removed this session (green +N / red -N) |

## Quick Setup

```bash
# 1. Copy the script
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh

# 2. Add to Claude Code settings (~/.claude/settings.json)
# Add this to the top-level object:
#   "statusLine": {
#     "type": "command",
#     "command": "bash ~/.claude/statusline-command.sh"
#   }
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
The script reads the plan tier from the API data first, falling back to `$CLAUDE_PLAN`, and defaulting to "Team" if neither is set.

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
