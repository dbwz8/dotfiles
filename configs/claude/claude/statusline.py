#!/usr/bin/env python3
"""Compact single-line Claude Code statusline.

Shows: model, repo, git branch (+ dirty marker), a 10-char context-usage
bar, session cost and elapsed session time. Uses muted 256-color ANSI
codes and Nerd Font glyphs with Powerline-style separators. Set the
environment variable CLAUDE_STATUSLINE_PLAIN=1 to fall back to a
plain-ASCII rendering on terminals without a Nerd Font / UTF-8 locale.
"""
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

raw = json.loads(sys.stdin.read())

R = "\033[0m"


def c(code):
    return f"\033[38;5;{code}m"


# Muted 256-color palette.
GREY = c(245)      # separators / secondary text
BLUE = c(67)       # model
PURPLE = c(103)    # repo
GREEN = c(108)     # branch / clean / low context usage
RED = c(167)       # dirty marker / high context usage
YELLOW = c(179)    # mid context usage
TEAL = c(109)      # elapsed time
TAN = c(180)       # cost

# Decide whether it is safe to use Nerd Font glyphs / powerline chars.
_lang = (os.environ.get("LANG", "") + os.environ.get("LC_ALL", "")).upper()
NF = os.environ.get("CLAUDE_STATUSLINE_PLAIN", "") != "1" and (
    "UTF-8" in _lang or "UTF8" in _lang
)

SEPX = f" {GREY}{R} " if NF else f" {GREY}|{R} "  # TAIL_OK

ICON_MODEL2 = " " if NF else ""     #  microchip
ICON_REPO = " " if NF else ""      #  github/repo
ICON_BRANCH = " " if NF else ""    #  code-fork / branch
ICON_CTX = " " if NF else ""       #  dashboard / gauge
ICON_COST = " " if NF else ""      #  usd
ICON_TIME = " " if NF else ""      #  clock
DOT = "" if NF else "*"            #  filled dot for dirty marker

# --- model -----------------------------------------------------------
model_id = raw.get("model", {}).get("id", "")
if "opus" in model_id:
    model = "opus"
elif "sonnet" in model_id:
    model = "sonnet"
elif "haiku" in model_id:
    model = "haiku"
else:
    tail = model_id.split("-")
    model = tail[-1] if tail and tail[-1] else raw.get("model", {}).get("display_name", "?")

model_seg = f"{BLUE}{ICON_MODEL}{model}{R}"

# --- repo (truncated) --------------------------------------------------
MAX_REPO_LEN = 20
workspace = raw.get("workspace", {}) or {}
repo_info = workspace.get("repo") or {}
project = workspace.get("project_dir", "")
repo_name = repo_info.get("name") or (os.path.basename(project.rstrip("/")) if project else "")
if repo_name and len(repo_name) > MAX_REPO_LEN:
    repo_name = repo_name[: MAX_REPO_LEN - 1] + "…"

repo_seg = f"{PURPLE}{ICON_REPO}{repo_name}{R}" if repo_name else ""

# --- git branch + dirty marker ----------------------------------------
branch = ""
dirty = False
if project:
    try:
        b = subprocess.run(
            ["git", "--no-optional-locks", "-C", project, "branch", "--show-current"],
            capture_output=True, text=True, timeout=1,
        )
        branch = b.stdout.strip() if b.returncode == 0 else ""
        if not branch:
            sha = subprocess.run(
                ["git", "--no-optional-locks", "-C", project, "rev-parse", "--short", "HEAD"],
                capture_output=True, text=True, timeout=1,
            )
            if sha.returncode == 0:
                branch = sha.stdout.strip()
        d = subprocess.run(
            ["git", "--no-optional-locks", "-C", project, "status", "--porcelain"],
            capture_output=True, text=True, timeout=1,
        )
        dirty = d.returncode == 0 and bool(d.stdout.strip())
    except Exception:
        pass

branch_seg = ""
if branch:
    marker = f" {RED}{DOT}{R}" if dirty else ""
    branch_seg = f"{GREEN}{ICON_BRANCH}{branch}{R}{marker}"

# --- context usage bar (10 chars) --------------------------------------
BAR_LEN = 10
ctx_seg = ""
ctx = raw.get("context_window", {}) or {}
pct = ctx.get("used_percentage")
if pct is None:
    win_size = ctx.get("context_window_size", 0) or 0
    if win_size > 0:
        usage = ctx.get("current_usage") or {}
        if usage:
            tokens = (
                usage.get("input_tokens", 0)
                + usage.get("cache_creation_input_tokens", 0)
                + usage.get("cache_read_input_tokens", 0)
            )
        else:
            tokens = ctx.get("total_input_tokens", 0) + ctx.get("total_output_tokens", 0)
        pct = (tokens * 100 / win_size) if tokens > 0 else 0

if pct is not None:
    pct = max(0, min(100, pct))
    filled = round(pct * BAR_LEN / 100)
    bar = "█" * filled + "░" * (BAR_LEN - filled)
    color = RED if pct >= 80 else YELLOW if pct >= 50 else GREEN
    ctx_seg = f"{color}{ICON_CTX}{bar} {pct:.0f}%{R}"

# --- session cost -------------------------------------------------------
cost_seg = ""
cost = (raw.get("cost", {}) or {}).get("total_cost_usd", 0) or 0
if cost > 0:
    cost_str = f"${cost:.2f}" if cost < 10 else f"${cost:.1f}"
    cost_seg = f"{TAN}{ICON_COST}{cost_str}{R}"

# --- elapsed session time -----------------------------------------------
time_seg = ""
transcript_path = raw.get("transcript_path", "")
start_dt = None
try:
    with open(transcript_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            entry = json.loads(line)
            ts = entry.get("timestamp")
            if ts:
                start_dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
            break
except Exception:
    pass
if start_dt is None and transcript_path:
    try:
        start_dt = datetime.fromtimestamp(os.path.getctime(transcript_path), tz=timezone.utc)
    except Exception:
        pass

if start_dt is not None:
    elapsed = datetime.now(timezone.utc) - start_dt
    total_seconds = max(0, int(elapsed.total_seconds()))
    h, rem = divmod(total_seconds, 3600)
    m, s = divmod(rem, 60)
    elapsed_str = f"{h}h{m:02d}m" if h else f"{m}m{s:02d}s"
    time_seg = f"{TEAL}{ICON_TIME}{elapsed_str}{R}"

segments = [s for s in (model_seg, repo_seg, branch_seg, ctx_seg, cost_seg, time_seg) if s]
sys.stdout.write(SEP.join(segments))
