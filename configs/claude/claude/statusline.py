#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

raw = json.loads(sys.stdin.read())

R = "\033[0m"
c = "\033[38;5;{}m".format

GREY, BLUE, PURPLE, GREEN = c(245), c(67), c(103), c(108)
RED, YELLOW, TEAL, TAN = c(167), c(179), c(109), c(180)

_lang = (os.environ.get("LANG", "") + os.environ.get("LC_ALL", "")).upper()
NF = os.environ.get("CLAUDE_STATUSLINE_PLAIN", "") != "1" and ("UTF-8" in _lang or "UTF8" in _lang)

SEP = f" {GREY}{R} " if NF else f" {GREY}|{R} "

# Model
model_id = raw.get("model", {}).get("id", "")
for name in ("opus", "sonnet", "haiku", "fable"):
    if name in model_id:
        model = name
        break
else:
    tail = model_id.rsplit("-", 1)
    model = tail[-1] or "?"
model_seg = f"{BLUE} {model}{R}" if NF else f"{BLUE}{model}{R}"

# Repo (truncated to 20 chars)
workspace = raw.get("workspace") or {}
project = workspace.get("project_dir", "")
repo_name = (workspace.get("repo") or {}).get("name") or (os.path.basename(project.rstrip("/")) if project else "")
if len(repo_name) > 20:
    repo_name = repo_name[:19] + "…"
repo_seg = f"{PURPLE} {repo_name}{R}" if NF and repo_name else f"{PURPLE}{repo_name}{R}" if repo_name else ""

# Git branch + dirty marker
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
            b = subprocess.run(
                ["git", "--no-optional-locks", "-C", project, "rev-parse", "--short", "HEAD"],
                capture_output=True, text=True, timeout=1,
            )
            branch = b.stdout.strip() if b.returncode == 0 else ""
        d = subprocess.run(
            ["git", "--no-optional-locks", "-C", project, "status", "--porcelain", "-uno"],
            capture_output=True, text=True, timeout=1,
        )
        dirty = d.returncode == 0 and bool(d.stdout.strip())
    except Exception:
        pass

branch_seg = ""
if branch:
    marker = f" {RED}●{R}" if dirty else ""
    branch_seg = f"{GREEN} {branch}{R}{marker}" if NF else f"{GREEN}{branch}{R}{marker}"

# Context usage bar (10 chars)
ctx_seg = ""
ctx = raw.get("context_window") or {}
pct = ctx.get("used_percentage")
if pct is None:
    win_size = ctx.get("context_window_size", 0)
    if win_size:
        usage = ctx.get("current_usage") or {}
        tokens = (usage.get("input_tokens", 0) + usage.get("cache_creation_input_tokens", 0)
                  + usage.get("cache_read_input_tokens", 0)) if usage else (
                  ctx.get("total_input_tokens", 0) + ctx.get("total_output_tokens", 0))
        pct = tokens * 100 / win_size if tokens else 0
if pct is not None:
    pct = max(0, min(100, pct))
    filled = round(pct * 10 / 100)
    bar = "█" * filled + "░" * (10 - filled)
    color = RED if pct >= 80 else YELLOW if pct >= 50 else GREEN
    ctx_seg = f"{color}{bar} {pct:.0f}%{R}"

# Session cost
cost_seg = ""
cost = (raw.get("cost") or {}).get("total_cost_usd", 0) or 0
if cost > 0:
    cost_seg = f"{TAN}${cost:.2f}{R}" if cost < 10 else f"{TAN}${cost:.1f}{R}"

# Elapsed time (from transcript file ctime)
time_seg = ""
transcript = raw.get("transcript_path", "")
if transcript:
    try:
        start = datetime.fromtimestamp(os.path.getctime(transcript), tz=timezone.utc)
        secs = max(0, int((datetime.now(timezone.utc) - start).total_seconds()))
        h, rem = divmod(secs, 3600)
        m, s = divmod(rem, 60)
        time_seg = f"{TEAL}{h}h{m:02d}m{R}" if h else f"{TEAL}{m}m{s:02d}s{R}"
    except Exception:
        pass

segments = [s for s in (model_seg, repo_seg, branch_seg, ctx_seg, cost_seg, time_seg) if s]
sys.stdout.write(SEP.join(segments))
