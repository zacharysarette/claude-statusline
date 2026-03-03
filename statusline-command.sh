#!/usr/bin/env bash
# Claude Code status line — three-line adaptive layout with colors + emoji
# Line 1: Identity & Time | Line 2: Workspace | Line 3: Metrics
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
    console.log('cc_version=\"' + esc(d.version || '') + '\"');
    console.log('cost_usd=\"' + (d.cost?.total_cost_usd || 0) + '\"');
    console.log('duration_ms=\"' + (d.cost?.total_duration_ms || 0) + '\"');
    console.log('lines_added=\"' + (d.cost?.total_lines_added || 0) + '\"');
    console.log('lines_removed=\"' + (d.cost?.total_lines_removed || 0) + '\"');
    console.log('ctx_size=\"' + (d.context_window?.context_window_size || 0) + '\"');
    console.log('plan_tier=\"' + esc(d.plan?.tier || d.plan?.name || d.account?.plan || '') + '\"');
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
    console.log('cc_version=\"\"');
    console.log('cost_usd=\"0\"');
    console.log('duration_ms=\"0\"');
    console.log('lines_added=\"0\"');
    console.log('lines_removed=\"0\"');
    console.log('ctx_size=\"0\"');
    console.log('plan_tier=\"\"');
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

datetime_str="🕐 ${DIM}Time:${R} ${CYAN}$(date '+%a %b %-d %H:%M')${R}"

plan_display="${plan_tier:-${CLAUDE_PLAN:-Team}}"
plan_str="💎 ${DIM}Plan:${R} ${MAGENTA}${plan_display}${R}"

version_str=""
if [ -n "$cc_version" ]; then
  version_str=" ${SEP} ${DIM}v${cc_version}${R}"
fi

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
reset_str="⏳ ${DIM}Reset:${R} ${bar_result} ${rc}${hrs}h${mins_pad}m${R}"

model_str="🤖 ${DIM}Model:${R} ${BLUE}${model/Claude /}${R}"

# Vim mode — default to NORMAL when not set
vim_mode="${vim_mode:-NORMAL}"
if [ "$vim_mode" = "INSERT" ]; then
  vim_str=" ${SEP} ${BGREEN}${vim_mode}${R}"
else
  vim_str=" ${SEP} ${BCYAN}${vim_mode}${R}"
fi

agent_str=""
if [ -n "$agent_name" ]; then
  agent_str=" ${SEP} 🔧 ${DIM}Agent:${R} ${YELLOW}${agent_name}${R}"
fi

style_str=""
style_lower=$(echo "$output_style" | tr '[:upper:]' '[:lower:]')
if [ -n "$output_style" ] && [ "$style_lower" != "normal" ] && [ "$style_lower" != "default" ]; then
  style_str=" ${SEP} ✨ ${DIM}Style:${R} ${MAGENTA}${output_style}${R}"
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
cwd_str="📂 ${DIM}Dir:${R} ${CYAN}${short_cwd}${R}"

git_str=""
if [ -n "$cwd" ]; then
  git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -n "$git_branch" ]; then
    git_str=" ${SEP} 🌿 ${DIM}Branch:${R} ${GREEN}${git_branch}${R}"
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
  ctx_str="📊 ${DIM}Context:${R} ${bar_result} ${cc}${used_pct}%${R}"
else
  ctx_str="📊 ${DIM}Context: ---------- --${R}"
fi

tokens_str=""
if [ "$total_input" -gt 0 ] 2>/dev/null || [ "$total_output" -gt 0 ] 2>/dev/null; then
  in_fmt=$(format_tokens "$total_input")
  out_fmt=$(format_tokens "$total_output")
  tokens_str=" ${SEP} ${DIM}Tokens in:${R} ${WHITE}${in_fmt}${R} ${DIM}out:${R} ${WHITE}${out_fmt}${R}"
fi

session_str=""
if [ -n "$session_name" ]; then
  session_str=" ${SEP} 💬 ${DIM}Session:${R} ${MAGENTA}\"${session_name}\"${R}"
fi

cost_str=""
if [ "$cost_usd" != "0" ] && [ -n "$cost_usd" ]; then
  cost_rounded=$(printf '%.2f' "$cost_usd" 2>/dev/null || echo "$cost_usd")
  cost_str=" ${SEP} 💰 ${DIM}Cost:${R} ${YELLOW}\$${cost_rounded}${R}"
fi

duration_str=""
if [ "$duration_ms" -gt 0 ] 2>/dev/null; then
  total_secs=$(( duration_ms / 1000 ))
  d_hrs=$(( total_secs / 3600 ))
  d_mins=$(( (total_secs % 3600) / 60 ))
  d_secs=$(( total_secs % 60 ))
  if [ "$d_hrs" -gt 0 ]; then
    duration_str=" ${SEP} ⏱ ${DIM}Elapsed:${R} ${DIM}${d_hrs}h${d_mins}m${d_secs}s${R}"
  elif [ "$d_mins" -gt 0 ]; then
    duration_str=" ${SEP} ⏱ ${DIM}Elapsed:${R} ${DIM}${d_mins}m${d_secs}s${R}"
  else
    duration_str=" ${SEP} ⏱ ${DIM}Elapsed:${R} ${DIM}${d_secs}s${R}"
  fi
fi

lines_str=""
if [ "$lines_added" -gt 0 ] 2>/dev/null || [ "$lines_removed" -gt 0 ] 2>/dev/null; then
  lines_str=" ${SEP} ${DIM}Lines:${R} ${GREEN}+${lines_added}${R}/${RED}-${lines_removed}${R}"
fi

# ─── OUTPUT ───
echo -e "${R}${datetime_str} ${SEP} ${plan_str} ${SEP} ${reset_str} ${SEP} ${model_str}${version_str}${END}"
echo -e "${R}${cwd_str}${git_str}${vim_str}${agent_str}${style_str}${session_str}${END}"
echo -e "${R}${ctx_str}${tokens_str}${cost_str}${duration_str}${lines_str}${END}"
