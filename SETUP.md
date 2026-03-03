# Agent Setup Guide

This file is written for a Claude Code agent to follow when setting up the status line on a new machine. If you are a Claude agent helping a user set up their status line, follow these steps exactly.

## Prerequisites Check

Before starting, verify these are available:
```bash
node --version    # Need Node.js for JSON parsing
git --version     # Need git for branch/status info
bash --version    # Need bash to run the script
```

## Step 1: Copy the Script

Copy `statusline-command.sh` to the Claude config directory:

**macOS / Linux:**
```bash
mkdir -p ~/.claude
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

**Windows (Git Bash):**
```bash
mkdir -p ~/.claude
cp statusline-command.sh ~/.claude/statusline-command.sh
```

## Step 2: Configure Claude Code Settings

Edit `~/.claude/settings.json` to add the statusline command. If the file doesn't exist, create it.

**Add this key** to the top-level JSON object:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

If the file already exists with other settings, merge the key in — do NOT overwrite existing settings.

### Example: Merging with existing settings
If `settings.json` currently contains:
```json
{
  "theme": "dark",
  "permissions": {}
}
```

It should become:
```json
{
  "theme": "dark",
  "permissions": {},
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

## Step 3: Set Plan Tier (Optional)

The status line reads the plan tier from the API data first, falling back to the `CLAUDE_PLAN` environment variable, and defaulting to "Team" if neither is set. To override, add to the user's shell profile (`~/.bashrc`, `~/.zshrc`, or equivalent):

```bash
export CLAUDE_PLAN="Pro"
```

Valid values: `Max`, `Pro`, `Team`, or any custom string.

## Step 4: Verify

Tell the user to open a new Claude Code session. The three-line status bar should appear at the bottom of the terminal with:
- Line 1: clock, plan, reset countdown, model, version, vim mode
- Line 2: working directory, git branch, session name
- Line 3: context usage, tokens, cost, elapsed time, lines changed

## Troubleshooting

### Status line doesn't appear
- Check that `~/.claude/settings.json` has the `statusLine` key (nested object with `type` and `command`)
- Check that the script file exists at `~/.claude/statusline-command.sh`
- Try running manually: `echo '{}' | bash ~/.claude/statusline-command.sh`

### No git info showing
- Verify you're inside a git repository
- Check that `git` is on PATH

### Path shows as `...` instead of `~/...`
- This happens when the cwd path format doesn't match `$HOME`
- On Windows, Claude Code sends `C:/Users/...` but Git Bash `$HOME` is `/c/Users/...`
- The script handles this normalization, but if `$HOME` is set differently, the substitution may fail
- Fix: check `echo $HOME` and ensure the normalization in the script matches

### "command not found" errors
- Ensure Node.js is installed and on PATH
- The script uses `node` for JSON parsing since `jq` may not be available

## Platform Notes

### Windows (Git Bash)
- The script normalizes Windows paths (`C:/` → `/c/`) for `~` substitution
- The "Permission denied" error from bash profile (spaces in username path) is harmless — ignore it

### macOS
- Uses `date` command which may differ slightly from GNU date
- `date '+%a %b %-d %H:%M'` — the `%-d` (no-pad day) works on macOS

### Linux
- Should work out of the box with no modifications
