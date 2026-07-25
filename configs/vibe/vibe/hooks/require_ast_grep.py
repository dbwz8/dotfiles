#!/usr/bin/env python3
"""Require a successful ast-grep call before Vibe's sanctioned edit paths.

Vibe 2.22.0 invokes this hook with a JSON payload.  The pre_tool invocation
contains session_id, tool_name, and tool_input.command; post_tool additionally
contains tool_status.  A successful ast-grep Bash call records session-local
state.  A later scoped patch or Python fallback is denied until that state
exists.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Any

from block_sed import ShellSyntaxError, command_contains_blocked, lex_shell


AST_GREP_COMMANDS = {"ast-grep"}
PATCH_COMMANDS = {"vibe-apply-patch"}
UV_COMMANDS = {"uv"}
DIRECT_GO_SOURCE_COMMANDS = {"cat", "cp", "install", "mv", "tee"}
WRITE_REDIRECTIONS = {">", ">>", ">&"}
AST_GREP_SEARCH_TOKEN = re.compile(r"(?<!\S)(?:-p|--pattern|--rewrite|scan|outline)(?!\S)")
PYTHON_TEST_MODULE = re.compile(
    r"(?<!\S)uv\s+run\s+python\s+-m\s+(?:unittest|pytest)(?!\S)"
)

DENIAL_REASON = (
    "Run a successful ast-grep search for the exact target node before editing. "
    "This session has not completed ast-grep yet; then retry the scoped patch or Python "
    "edit script."
)

DIRECT_GO_SOURCE_REASON = (
    "Direct Bash access to Go source through cat, shell redirection, or file-copy commands "
    "is prohibited. Use ast-grep to locate or rewrite a Go node, or use vibe-apply-patch "
    "after a successful ast-grep search."
)

DIRECT_PATCH_REASON = (
    "vibe-apply-patch must receive one scoped, in-line unified diff through its direct "
    "heredoc form. Do not stage a patch in /tmp or combine it with other commands."
)


def deny(reason: str) -> None:
    print(json.dumps({"decision": "deny", "reason": reason}, separators=(",", ":")))


def state_dir() -> Path:
    override = os.environ.get("VIBE_AST_GREP_STATE_DIR")
    if override:
        return Path(override)
    vibe_home = Path(os.environ.get("VIBE_HOME", Path.home() / ".vibe"))
    return vibe_home / "hook-state" / "ast-grep"


def state_path(session_id: str) -> Path:
    digest = hashlib.sha256(session_id.encode("utf-8")).hexdigest()
    return state_dir() / f"{digest}.json"


def has_successful_search(session_id: str) -> bool:
    return state_path(session_id).is_file()


def record_successful_search(session_id: str) -> None:
    destination = state_path(session_id)
    destination.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(prefix=".ast-grep-", dir=destination.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as temporary:
            json.dump({"session_id": session_id}, temporary, separators=(",", ":"))
            temporary.write("\n")
        os.chmod(temporary_name, 0o600)
        os.replace(temporary_name, destination)
    finally:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass


def bash_payload(payload: Any) -> tuple[str, str, str, str | None] | None:
    if not isinstance(payload, dict):
        raise ValueError("hook payload must be a JSON object")
    tool_name = payload.get("tool_name")
    if isinstance(tool_name, str) and tool_name != "bash":
        return None
    if tool_name != "bash":
        raise ValueError("tool hook payload is missing tool_name='bash'")
    event = payload.get("hook_event_name")
    if event not in {"pre_tool", "post_tool"}:
        raise ValueError("Bash hook payload has an unsupported event")
    session_id = payload.get("session_id")
    if not isinstance(session_id, str) or not session_id:
        raise ValueError("Bash hook payload has no non-empty session_id")
    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        raise ValueError("Bash hook payload has no tool_input object")
    command = tool_input.get("command")
    if not isinstance(command, str):
        raise ValueError("Bash hook payload has no string tool_input.command")
    tool_status = payload.get("tool_status")
    if event == "post_tool" and not isinstance(tool_status, str):
        raise ValueError("post_tool Bash payload has no string tool_status")
    return event, session_id, command, tool_status if isinstance(tool_status, str) else None


def invokes_ast_grep_search(command: str) -> bool:
    if not command_contains_blocked(command, AST_GREP_COMMANDS):
        return False
    # `ast-grep run` is the default command, so -p/--pattern identifies both
    # explicit and implicit searches.  scan and outline are also structural
    # queries.  Help/version/new/test/lsp calls deliberately do not unlock an
    # edit path.
    return AST_GREP_SEARCH_TOKEN.search(command) is not None


def requires_prior_search(command: str) -> bool:
    if command_contains_blocked(command, PATCH_COMMANDS):
        return True
    if not command_contains_blocked(command, UV_COMMANDS):
        return False
    # Test modules are validation, not the exact-anchor Python edit fallback.
    # Keep them available before a search; direct `uv run python script.py`
    # remains gated because that is the sanctioned fallback form.
    return PYTHON_TEST_MODULE.search(command) is None


def direct_patch_heredoc_header(command: str) -> str | None:
    """Return a single sanctioned patch heredoc's header, if present.

    The shell-aware tokenizer intentionally fails closed on ambiguous input.
    A patch here-document body can validly contain quotes, braces, and diff
    syntax that are not a standalone shell command.  It is therefore exempted
    only when the entire Bash call is the documented direct patch form, with an
    optional `cd <directory> &&` prefix and no command after its delimiter.
    """
    if "\n" not in command:
        return None
    lines = command.splitlines()
    header = lines[0]
    tokens = lex_shell(header)
    index = 0
    if len(tokens) >= 3 and tokens[:1] == ["cd"] and tokens[2] == "&&":
        index = 3
    if len(tokens) != index + 3 or tokens[index : index + 2] != ["vibe-apply-patch", "<<"]:
        return None
    delimiter = tokens[index + 2]
    if not delimiter:
        return None
    for line_index, line in enumerate(lines[1:], start=1):
        if line == delimiter:
            return header if line_index == len(lines) - 1 else None
    return None


def directly_accesses_go_source(command: str) -> bool:
    """Reject whole-file reads and generic shell writes of Go source.

    `lex_shell` preserves command positions and redirection tokens, so a
    filename or quoted prose that merely contains `.go` does not match.  The
    command-invocation check also handles wrappers such as `command`, `env`,
    `sudo`, and `bash -c`.
    """
    tokens = lex_shell(command)
    if not any(token.endswith(".go") for token in tokens):
        return False
    if command_contains_blocked(command, DIRECT_GO_SOURCE_COMMANDS):
        return True
    return any(
        token in WRITE_REDIRECTIONS
        and index + 1 < len(tokens)
        and tokens[index + 1].endswith(".go")
        for index, token in enumerate(tokens)
    )


def main() -> int:
    # This policy is retained for possible future use, but is deliberately
    # inactive by default.  A strict pre-tool workflow gate made normal coding
    # tasks brittle instead of safer.
    if os.environ.get("VIBE_ENABLE_REQUIRE_AST_GREP_HOOK") != "1":
        return 0
    payload: Any = None
    try:
        payload = json.loads(sys.stdin.read())
        parsed = bash_payload(payload)
        if parsed is None:
            return 0
        event, session_id, command, tool_status = parsed
        if event == "post_tool":
            if tool_status == "success" and invokes_ast_grep_search(command):
                record_successful_search(session_id)
            return 0
        # Do not pass a valid, direct patch heredoc body through the generic
        # shell tokenizer.  Its body is diff data, not a standalone shell
        # command.  Any other invocation is denied, including the previous
        # `cat > /tmp/patch` then `vibe-apply-patch` workaround.
        patch_header = direct_patch_heredoc_header(command)
        if "vibe-apply-patch" in command and patch_header is None:
            deny(DIRECT_PATCH_REASON)
            return 0
        analysis_command = patch_header or command
        if directly_accesses_go_source(analysis_command):
            deny(DIRECT_GO_SOURCE_REASON)
            return 0
        if requires_prior_search(analysis_command) and not has_successful_search(session_id):
            deny(DENIAL_REASON)
        return 0
    except (json.JSONDecodeError, OSError, ShellSyntaxError, ValueError) as error:
        print(f"require_ast_grep hook could not process Bash payload: {error}", file=sys.stderr)
        if isinstance(payload, dict) and payload.get("hook_event_name") == "post_tool":
            # A post-tool marker failure must not replace the tool result.  It
            # merely leaves the session unmarked, so the strict pre-tool gate
            # remains closed on the next attempted edit.
            return 0
        deny("Bash call denied because the ast-grep policy hook could not safely process it.")
        return 0
    except Exception as error:  # strict=true protects against process failures as well.
        print(f"require_ast_grep hook internal failure: {error}", file=sys.stderr)
        if isinstance(payload, dict) and payload.get("hook_event_name") == "post_tool":
            return 0
        deny("Bash call denied because the ast-grep policy hook failed closed.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
