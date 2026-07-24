#!/usr/bin/env python3
"""Strict Vibe pre_tool guard that rejects Bash invocations of blocked commands.

Vibe 2.22.0 invokes pre_tool hooks with a JSON object containing tool_name and
tool_input.  For the Bash tool, tool_input.command is the raw shell command.
"""

from __future__ import annotations

import json
import os
import re
import shlex
import sys
from typing import Any, Iterable


BLOCKED_COMMANDS = {"sed"}

DENIAL_REASON = (
    "Execution of sed is prohibited by the user-level Vibe policy. Use ast-grep "
    "for structural Go edits, or an exact anchored Python replacement when "
    "ast-grep is unsuitable. Run gofmt immediately after each Go edit."
)

_SEPARATORS = {";", "&&", "||", "|", "&", "(", ")"}
_REDIRECTIONS = {"<", ">", ">>", "<<", "<<<", "<>", "<&", ">&"}
_ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=.*", re.DOTALL)
_SHELLS = {"sh", "bash"}
_SUDO_OPTIONS_WITH_VALUE = {
    "-C",
    "-g",
    "-h",
    "-p",
    "-r",
    "-t",
    "-T",
    "-u",
    "--chdir",
    "--close-from",
    "--group",
    "--host",
    "--other-user",
    "--prompt",
    "--role",
    "--type",
    "--user",
}
_ENV_OPTIONS_WITH_VALUE = {"-C", "-u", "--chdir", "--unset"}


class ShellSyntaxError(ValueError):
    """The command could not be tokenized safely."""


def deny(reason: str) -> None:
    print(json.dumps({"decision": "deny", "reason": reason}, separators=(",", ":")))


def command_name(token: str) -> str:
    return os.path.basename(token.rstrip("/"))


def is_blocked_command(token: str) -> bool:
    return command_name(token) in BLOCKED_COMMANDS


def lex_shell(command: str) -> list[str]:
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars="|&;()<>")
        lexer.whitespace_split = True
        lexer.commenters = ""
        return list(lexer)
    except ValueError as error:
        raise ShellSyntaxError(str(error)) from error


def command_end(tokens: list[str], start: int) -> int:
    for index in range(start, len(tokens)):
        if tokens[index] in _SEPARATORS:
            return index
    return len(tokens)


def skip_prefixes(tokens: list[str], start: int, end: int) -> int:
    index = start
    while index < end:
        token = tokens[index]
        if token in _REDIRECTIONS:
            index += 2
            continue
        if _ASSIGNMENT.fullmatch(token):
            index += 1
            continue
        break
    return index


def command_option_target(tokens: list[str], start: int, end: int) -> int | None:
    """Return the command following command(1)'s options."""
    index = start + 1
    while index < end:
        token = tokens[index]
        if token == "--":
            return index + 1 if index + 1 < end else None
        if token.startswith("-") and token != "-":
            index += 1
            continue
        return index
    return None


def env_target(tokens: list[str], start: int, end: int) -> int | None:
    """Return env(1)'s command, skipping options and NAME=value prefixes."""
    index = start + 1
    while index < end:
        token = tokens[index]
        if token == "--":
            index += 1
            break
        if token in {"-S", "--split-string"}:
            raise ShellSyntaxError("env -S command strings cannot be safely evaluated")
        if token in _ENV_OPTIONS_WITH_VALUE:
            index += 2
            continue
        if token.startswith("-") and token != "-":
            index += 1
            continue
        if _ASSIGNMENT.fullmatch(token):
            index += 1
            continue
        return index
    return index if index < end else None


def sudo_target(tokens: list[str], start: int, end: int) -> int | None:
    """Return sudo(8)'s command while skipping its option arguments."""
    index = start + 1
    while index < end:
        token = tokens[index]
        if token == "--":
            return index + 1 if index + 1 < end else None
        if token in _SUDO_OPTIONS_WITH_VALUE:
            index += 2
            continue
        if token.startswith("-") and token != "-":
            index += 1
            continue
        return index
    return None


def shell_command_strings(tokens: list[str], start: int, end: int) -> Iterable[str]:
    """Yield command strings passed to sh -c or bash -c."""
    index = start + 1
    while index < end:
        token = tokens[index]
        if token == "--":
            index += 1
            continue
        if token == "-c":
            if index + 1 < end:
                yield tokens[index + 1]
            return
        if token.startswith("-") and token != "-":
            # Bash accepts combined short flags such as -lc; their command is
            # the next argument.  -cCOMMAND embeds its command in the flag.
            flags = token[1:]
            c_index = flags.find("c")
            if c_index >= 0:
                suffix = flags[c_index + 1 :]
                if suffix:
                    yield suffix
                elif index + 1 < end:
                    yield tokens[index + 1]
                return
        index += 1


def find_exec_target(tokens: list[str], start: int, end: int) -> bool:
    """Check find -exec/-execdir command positions without scanning arguments."""
    index = start + 1
    while index < end:
        if tokens[index] not in {"-exec", "-execdir"}:
            index += 1
            continue
        exec_end = index + 1
        while exec_end < end and tokens[exec_end] not in {";", "+"}:
            exec_end += 1
        if command_invokes_blocked(tokens, index + 1, exec_end):
            return True
        index = exec_end + 1
    return False


def command_invokes_blocked(tokens: list[str], start: int, end: int) -> bool:
    """Check one shell command position, unwrapping common command wrappers."""
    index = skip_prefixes(tokens, start, end)
    while index is not None and index < end:
        executable = tokens[index]
        executable_name = command_name(executable)
        if executable == "$" or executable.startswith("$") or executable.startswith("`"):
            raise ShellSyntaxError("dynamic command names cannot be safely evaluated")
        if is_blocked_command(executable):
            return True
        if executable_name in _SHELLS:
            if any(command_contains_blocked(command) for command in shell_command_strings(tokens, index, end)):
                return True
            return False
        if executable_name == "find":
            return find_exec_target(tokens, index, end)
        if executable_name == "command":
            index = command_option_target(tokens, index, end)
            continue
        if executable_name == "env":
            index = env_target(tokens, index, end)
            continue
        if executable_name == "sudo":
            index = sudo_target(tokens, index, end)
            continue
        if executable_name == "eval":
            return command_contains_blocked(" ".join(tokens[index + 1 : end]))
        return False
    return False


def extract_subcommands(command: str) -> Iterable[str]:
    """Yield command-substitution and backtick bodies outside single quotes."""
    index = 0
    quote: str | None = None
    while index < len(command):
        char = command[index]
        if char == "\\":
            index += 2
            continue
        if quote is None and char in {"'", '"'}:
            quote = char
            index += 1
            continue
        if quote == "'":
            if char == "'":
                quote = None
            index += 1
            continue
        if quote == '"' and char == '"':
            quote = None
            index += 1
            continue
        if char == "`":
            end = index + 1
            while end < len(command):
                if command[end] == "\\":
                    end += 2
                    continue
                if command[end] == "`":
                    yield command[index + 1 : end]
                    index = end + 1
                    break
                end += 1
            else:
                raise ShellSyntaxError("unterminated backtick command substitution")
            continue
        if char == "$" and index + 1 < len(command) and command[index + 1] == "(":
            start = index + 2
            end = start
            depth = 1
            nested_quote: str | None = None
            while end < len(command):
                nested = command[end]
                if nested == "\\":
                    end += 2
                    continue
                if nested_quote is None and nested in {"'", '"'}:
                    nested_quote = nested
                elif nested_quote is not None and nested == nested_quote:
                    nested_quote = None
                elif nested_quote is None and nested == "(":
                    depth += 1
                elif nested_quote is None and nested == ")":
                    depth -= 1
                    if depth == 0:
                        yield command[start:end]
                        index = end + 1
                        break
                end += 1
            else:
                raise ShellSyntaxError("unterminated $(...) command substitution")
            continue
        index += 1


def command_contains_blocked(command: str) -> bool:
    for subcommand in extract_subcommands(command):
        if command_contains_blocked(subcommand):
            return True
    return command_contains_blocked_tokens(lex_shell(command))


def command_contains_blocked_tokens(tokens: list[str]) -> bool:
    index = 0
    at_command_start = True
    while index < len(tokens):
        token = tokens[index]
        if token in _SEPARATORS:
            at_command_start = True
            index += 1
            continue
        if at_command_start:
            end = command_end(tokens, index)
            if command_invokes_blocked(tokens, index, end):
                return True
            at_command_start = False
        index += 1
    return False


def payload_command(payload: Any) -> str | None:
    if not isinstance(payload, dict):
        raise ValueError("hook payload must be a JSON object")
    tool_name = payload.get("tool_name")
    if isinstance(tool_name, str) and tool_name != "bash":
        return None
    if tool_name != "bash":
        raise ValueError("pre_tool payload is missing tool_name='bash'")
    if payload.get("hook_event_name") != "pre_tool":
        raise ValueError("Bash hook payload is not a pre_tool event")
    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        raise ValueError("Bash pre_tool payload has no tool_input object")
    command = tool_input.get("command")
    if not isinstance(command, str):
        raise ValueError("Bash pre_tool payload has no string tool_input.command")
    return command


def main() -> int:
    try:
        raw_payload = sys.stdin.read()
        payload = json.loads(raw_payload)
        command = payload_command(payload)
        if command is None:
            return 0
        if command_contains_blocked(command):
            deny(DENIAL_REASON)
        return 0
    except (json.JSONDecodeError, ValueError, ShellSyntaxError) as error:
        print(f"block_sed hook denied malformed Bash payload or command: {error}", file=sys.stderr)
        deny("Bash call denied because the user-level sed policy could not safely parse the hook payload or command.")
        return 0
    except Exception as error:  # strict=true also protects against process failures.
        print(f"block_sed hook internal failure: {error}", file=sys.stderr)
        deny("Bash call denied because the user-level sed policy guard failed closed.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
