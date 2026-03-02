# Roadmap

Future improvements and expansion ideas for the Claude Code status line.

## Planned Improvements

### Background Color Fix
The black background (`\033[40m`) currently has visible gaps between colored segments in some terminals. Every color code already includes `;40`, but the renderer still shows through. Possible approaches:
- Test with `\033[48;5;0m` (256-color black) or `\033[48;2;0;0;0m` (truecolor black)
- Investigate if Claude Code's statusline renderer strips or resets background attributes
- Try padding each segment to fill the line width with background color
- Consider using a different "background" approach like full-width box-drawing characters

### Performance: Replace Node.js with Pure Bash
The current JSON parser uses Node.js, which adds ~50-100ms startup time per render. Alternatives:
- **jq** — fastest, but not installed by default on Windows
- **Python** — `python3 -c "import json,sys; ..."` — more available than jq on some systems
- **Pure bash** — crude but possible for the simple flat JSON structure: `grep -o '"key":"[^"]*"'` patterns
- **Compiled binary** — a tiny Rust/Go tool that reads stdin JSON and outputs bash vars

### Configurable Layout
Add a companion config file (`~/.claude/statusline.conf`) to toggle fields:
```bash
SHOW_VIM_MODE=true
SHOW_TOKENS=true
SHOW_GIT=true
SHOW_RESET_BAR=true
SHOW_SESSION=true
SHOW_AGENT=true
SHOW_STYLE=true
DEFAULT_VIM_MODE="NORMAL"  # or "" to hide when vim not active
```

### Cost Tracking
Show estimated session cost based on token counts and model pricing:
```
💰 $0.42
```
- Requires a pricing lookup (could be hardcoded or fetched)
- Model pricing: input vs output rates differ
- Would need to be updated when Anthropic changes pricing

### Stopwatch / Session Duration
Show how long the current session has been active:
```
⏱️ 1h23m
```
- Write session start time to a temp file on first run
- Calculate elapsed on each render
- Reset when session changes (detect via session_name or PID)

## Feature Ideas

### Clickable Links (OSC 8)
Claude Code's statusline supports OSC 8 hyperlinks in terminals that support them (iTerm2, Kitty, WezTerm). Ideas:
- Make the git branch name link to the GitHub branch page
- Make the working directory clickable to open in file manager
- Link the model name to Anthropic docs

### Theme System
Multiple color themes selectable via config:
- **Default** — current green/cyan/magenta/blue scheme
- **Monochrome** — white/gray only, for minimal terminals
- **Solarized** — match solarized terminal theme colors
- **Nord** — match nord color palette
- **Custom** — user defines colors in config file

### Multi-Session Awareness
When running multiple Claude Code sessions, show a session indicator:
```
[2/3] 🕐 Mon Mar 2 ...
```
- Detect via lock files or PID tracking in a shared temp directory

### Rate Limit Warning
Flash the reset bar or show a warning icon when approaching rate limits:
```
⏳ ██░░░░░░░░░░ 2h15m ⚠️
```

### PR Review Status
If on a branch with an open PR, show its review status:
```
🌿 feature/login 📋 2✔ 1💬
```
- Uses `gh pr view --json reviewDecision,reviews`
- Could be slow — cache for 60s

### System Resource Monitor
Add optional CPU/memory usage (useful for long builds):
```
💻 CPU: 45% MEM: 8.2G
```

### Weather (Just for Fun)
Tiny weather indicator fetched periodically:
```
🌤️ 72°F
```
- Fetch from wttr.in on first run, cache for 1 hour
- Totally optional / easter egg

## Architecture Notes for Contributors

### How the Script Works
1. Claude Code pipes JSON to stdin after each assistant message
2. The script reads all stdin via `input=$(cat)`
3. A single `node` call parses JSON and outputs `key="value"` pairs
4. `eval` brings those into bash variables
5. Each section builds a string with ANSI color codes
6. Two `echo -e` calls output line 1 and line 2
7. Claude Code renders each `echo` as a separate status row

### JSON Fields Available
```
d.model.display_name        "Claude Opus 4.6"
d.cwd                       "C:/Users/..." or "/home/..."
d.context_window.used_percentage   23
d.context_window.total_input_tokens    120000
d.context_window.total_output_tokens   25000
d.session_name              "my session" or ""
d.vim.mode                  "NORMAL", "INSERT", or ""
d.agent.name                "agent-name" or undefined
d.output_style.name         "default", "Concise", etc.
```

### Key Gotchas
- **Windows paths**: `C:/` must be normalized to `/c/` for `~` substitution
- **Output style**: comes through as lowercase `"default"`, needs case-insensitive comparison
- **Vim mode**: empty when not enabled — default to "NORMAL" if you want it always visible
- **Multi-line**: each `echo` = one row. `\n` inside a single printf does NOT work
- **Background colors**: ANSI `\033[40m` has rendering gaps in some terminals despite being in every escape code
