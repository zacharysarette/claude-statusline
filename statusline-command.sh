#!/usr/bin/env bash
# Claude Code status line — two-line adaptive layout with colors + emoji
# Line 1: Identity & Time | Line 2: Workspace & Context
#
# Every color code includes ;40 (black bg) so background is NEVER dropped.

input=$(cat)

# ─── ANSI Colors (all include ;40 black background) ───
R='\033[0;40m'          # reset + black bg (base state)
BOLD='\033[1;40m'
DIM='\033[2;40m'
CYAN='\033[0;36;40m'
GREEN='\033[0;32;40m'
YELLOW='\033[0;33;40m'
RED='\033[0;31;40m'
MAGENTA='\033[0;35;40m'
BLUE='\033[0;34;40m'
WHITE='\033[0;97;40m'
BCYAN='\033[1;36;40m'   # bold cyan
BGREEN='\033[1;32;40m'  # bold green
SEP='\033[2;40m│\033[0;40m'
END='\033[0m'           # true reset, only at line end

# Parse all values via a single node call
eval "$(echo "$input" | node -e "
const chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  try {
    const d = JSON.parse(chunks.join(''));
    const esc = s => (s || '').replace(/'/g, \"'\\\\\\\\''\");
    console.log('model=\"' + esc(d.model?.display_name || '') + '\"');
    console.log('cwd=\"' + esc(d.cwd || d.workspace?.current_dir || '') + '\"');
    console.log('used_pct=\"' + esc(String(d.context_window?.used_percentage || '')) + '\"');
    console.log('total_input=\"' + (d.context_window?.total_input_tokens || 0) + '\"');
    console.log('total_output=\"' + (d.context_window?.total_output_tokens || 0) + '\"');
    console.log('session_name=\"' + esc(d.session_name || '') + '\"');
    console.log('vim_mode=\"' + esc(d.vim?.mode || '') + '\"');
    console.log('agent_name=\"' + esc(d.agent?.name || '') + '\"');
    console.log('output_style=\"' + esc(d.output_style?.name || '') + '\"');
  } catch(e) {
    console.log('model=\"\"');
    console.log('cwd=\"\"');
    console.log('used_pct=\"\"');
    console.log('total_input=\"0\"');
    console.log('total_output=\"0\"');
    console.log('session_name=\"\"');
    console.log('vim_mode=\"\"');
    console.log('agent_name=\"\"');
    console.log('output_style=\"\"');
  }
});
" 2>/dev/null)"

# ─── Helpers ───

format_tokens() {
  local t=$1
  if [ "$t" -ge 1000000 ] 2>/dev/null; then
    printf "%s.%sM" "$(( t / 1000000 ))" "$(( (t % 1000000) / 100000 ))"
  elif [ "$t" -ge 1000 ] 2>/dev/null; then
    printf "%sk" "$(( t / 1000 ))"
  else
    printf "%s" "$t"
  fi
}

# Build progress bar INLINE (no subshell) — all chars stay on black bg
# Usage: sets $bar_result
build_bar_inline() {
  local filled=$1 total=$2 color=$3
  local empty=$(( total - filled ))
  bar_result=""
  local i
  for (( i=0; i<filled; i++ )); do bar_result="${bar_result}█"; done
  for (( i=0; i<empty; i++ ));  do bar_result="${bar_result}░"; done
  bar_result="${color}${bar_result}${R}"
}

# ─── LINE 1: Identity & Time ───

datetime_str="🕐 ${CYAN}$(date '+%a %b %-d %H:%M')${R}"

plan_str="💎 ${MAGENTA}${CLAUDE_PLAN:-Max}${R}"

# Reset countdown
utc_secs=$(( $(date -u +%s) % 86400 ))
secs_left=$(( 86400 - utc_secs ))
hrs=$(( secs_left / 3600 ))
mins=$(( (secs_left % 3600) / 60 ))
bar_w=12
filled_t=$(( (hrs * bar_w + 23) / 24 ))
[ "$filled_t" -gt "$bar_w" ] && filled_t=$bar_w
if [ "$hrs" -ge 8 ]; then rc="$GREEN"; elif [ "$hrs" -ge 3 ]; then rc="$YELLOW"; else rc="$RED"; fi
build_bar_inline "$filled_t" "$bar_w" "$rc"
printf -v mins_pad "%02d" "$mins"
reset_str="⏳ ${bar_result} ${rc}${hrs}h${mins_pad}m${R}"

model_str="🤖 ${BLUE}${model/Claude /}${R}"

# Vim mode — default to NORMAL when not set
vim_mode="${vim_mode:-NORMAL}"
if [ "$vim_mode" = "INSERT" ]; then
  vim_str=" ${SEP} ${BGREEN}${vim_mode}${R}"
else
  vim_str=" ${SEP} ${BCYAN}${vim_mode}${R}"
fi

agent_str=""
if [ -n "$agent_name" ]; then
  agent_str=" ${SEP} 🔧 ${YELLOW}${agent_name}${R}"
fi

style_str=""
style_lower=$(echo "$output_style" | tr '[:upper:]' '[:lower:]')
if [ -n "$output_style" ] && [ "$style_lower" != "normal" ] && [ "$style_lower" != "default" ]; then
  style_str=" ${SEP} ✨ ${MAGENTA}${output_style}${R}"
fi

# ─── LINE 2: Workspace & Context ───

norm_cwd="${cwd//\\//}"
if [[ "$norm_cwd" =~ ^([A-Za-z]):/ ]]; then
  drive_lower=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')
  norm_cwd="/${drive_lower}${norm_cwd:2}"
fi
home_dir="$HOME"
short_cwd="${norm_cwd/#$home_dir/\~}"
if [ ${#short_cwd} -gt 50 ]; then
  short_cwd="~/...$(echo "$short_cwd" | rev | cut -d'/' -f1-2 | rev)"
fi
cwd_str="📂 ${CYAN}${short_cwd}${R}"

git_str=""
if [ -n "$cwd" ]; then
  git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -n "$git_branch" ]; then
    git_str=" ${SEP} 🌿 ${GREEN}${git_branch}${R}"
    porcelain=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
    if [ -n "$porcelain" ]; then
      mod_count=$(echo "$porcelain" | grep -c '^ \?M')
      untracked_count=$(echo "$porcelain" | grep -c '^??')
      deleted_count=$(echo "$porcelain" | grep -c '^ \?D')
      dirty_parts=()
      [ "$mod_count" -gt 0 ] 2>/dev/null && dirty_parts+=("${YELLOW}M:${mod_count}${R}")
      [ "$untracked_count" -gt 0 ] 2>/dev/null && dirty_parts+=("${CYAN}?:${untracked_count}${R}")
      [ "$deleted_count" -gt 0 ] 2>/dev/null && dirty_parts+=("${RED}D:${deleted_count}${R}")
      if [ ${#dirty_parts[@]} -gt 0 ]; then
        IFS=' ' dirty_joined="${dirty_parts[*]}"
        git_str="${git_str} [${dirty_joined}]"
      fi
    else
      git_str="${git_str} ${GREEN}✔${R}"
    fi
  fi
fi

if [ -n "$used_pct" ]; then
  filled=$(echo "$used_pct" | awk '{printf "%d", ($1 / 10) + 0.5}')
  empty=$((10 - filled))
  [ "$filled" -gt 10 ] && filled=10 && empty=0
  pct_int=${used_pct%.*}
  if [ "$pct_int" -le 50 ] 2>/dev/null; then cc="$GREEN"; elif [ "$pct_int" -le 80 ] 2>/dev/null; then cc="$YELLOW"; else cc="$RED"; fi
  build_bar_inline "$filled" 10 "$cc"
  ctx_str="📊 ${bar_result} ${cc}${used_pct}%${R}"
else
  ctx_str="📊 ${DIM}---------- --${R}"
fi

tokens_str=""
if [ "$total_input" -gt 0 ] 2>/dev/null || [ "$total_output" -gt 0 ] 2>/dev/null; then
  in_fmt=$(format_tokens "$total_input")
  out_fmt=$(format_tokens "$total_output")
  tokens_str=" ${SEP} ${DIM}in:${R} ${WHITE}${in_fmt}${R} ${DIM}out:${R} ${WHITE}${out_fmt}${R}"
fi

session_str=""
if [ -n "$session_name" ]; then
  session_str=" ${SEP} 💬 ${MAGENTA}\"${session_name}\"${R}"
fi

# ─── OUTPUT ───
echo -e "${R}${datetime_str} ${SEP} ${plan_str} ${SEP} ${reset_str} ${SEP} ${model_str}${vim_str}${agent_str}${style_str}${END}"
echo -e "${R}${cwd_str}${git_str} ${SEP} ${ctx_str}${tokens_str}${session_str}${END}"
