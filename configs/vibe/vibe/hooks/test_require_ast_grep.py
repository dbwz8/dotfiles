#!/usr/bin/env python3
"""Direct contract tests for the Vibe 2.22.0 ast-grep policy hook."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


GUARD = Path(__file__).with_name("require_ast_grep.py")


def payload(
    command: str,
    *,
    event: str = "pre_tool",
    session_id: str = "test-session",
    tool_name: str = "bash",
    status: str = "success",
) -> dict[str, object]:
    result: dict[str, object] = {
        "hook_event_name": event,
        "session_id": session_id,
        "parent_session_id": None,
        "transcript_path": "/tmp/vibe-test.jsonl",
        "cwd": "/tmp",
        "tool_name": tool_name,
        "tool_call_id": "call-test",
        "tool_input": {"command": command},
    }
    if event == "post_tool":
        result["tool_status"] = status
    return result


class RequireAstGrepTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.state_dir = Path(self.temporary_directory.name) / "state"

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def run_guard(self, raw_payload: str) -> tuple[int, str, str]:
        environment = dict(os.environ)
        environment["VIBE_AST_GREP_STATE_DIR"] = str(self.state_dir)
        result = subprocess.run(
            [sys.executable, str(GUARD)],
            input=raw_payload,
            text=True,
            capture_output=True,
            check=False,
            env=environment,
        )
        return result.returncode, result.stdout, result.stderr

    def assert_decision(self, raw: dict[str, object], expected: str | None) -> None:
        code, stdout, stderr = self.run_guard(json.dumps(raw))
        self.assertEqual(code, 0, stderr)
        if expected is None:
            self.assertEqual(stdout, "", stderr)
            return
        response = json.loads(stdout)
        self.assertEqual(response["decision"], expected)
        self.assertIsInstance(response.get("reason"), str)

    def mark_search(self, command: str = "ast-grep run --lang go -p 'func $NAME($$$) { $$$ }' file.go") -> None:
        self.assert_decision(payload(command, event="post_tool"), None)

    def test_edit_paths_are_denied_before_successful_search(self) -> None:
        for command in [
            "vibe-apply-patch < change.diff",
            "uv run python /tmp/exact_replace.py",
            "command vibe-apply-patch < change.diff",
            "env MODE=edit vibe-apply-patch < change.diff",
            "sudo -n vibe-apply-patch < change.diff",
            "bash -c 'uv run python /tmp/exact_replace.py'",
            "printf x | vibe-apply-patch",
        ]:
            with self.subTest(command=command):
                self.assert_decision(payload(command), "deny")

    def test_python_test_modules_do_not_require_a_search(self) -> None:
        for command in [
            "uv run python -m unittest -v configs/vibe/vibe/hooks/test_require_ast_grep.py",
            "uv run python -m pytest -q",
        ]:
            with self.subTest(command=command):
                self.assert_decision(payload(command), None)

    def test_successful_search_allows_edit_paths_in_that_session(self) -> None:
        self.mark_search()
        self.assert_decision(payload("vibe-apply-patch < change.diff"), None)
        self.assert_decision(payload("uv run python /tmp/exact_replace.py"), None)

    def test_failed_search_does_not_unlock_edit_paths(self) -> None:
        self.assert_decision(
            payload("ast-grep run --lang go -p '$X' missing.go", event="post_tool", status="failure"), None
        )
        self.assert_decision(payload("vibe-apply-patch < change.diff"), "deny")

    def test_ast_grep_must_be_invoked_as_a_command(self) -> None:
        self.assert_decision(payload("printf '%s\\n' ast-grep", event="post_tool"), None)
        self.assert_decision(payload("vibe-apply-patch < change.diff"), "deny")

    def test_ast_grep_help_or_version_do_not_unlock_edit_paths(self) -> None:
        self.assert_decision(payload("ast-grep --version", event="post_tool"), None)
        self.assert_decision(payload("ast-grep --help", event="post_tool"), None)
        self.assert_decision(payload("vibe-apply-patch < change.diff"), "deny")

    def test_nested_shell_ast_grep_unlocks_session(self) -> None:
        self.mark_search("bash -c \"ast-grep run --lang go -p '$X' file.go\"")
        self.assert_decision(payload("vibe-apply-patch < change.diff"), None)

    def test_read_and_format_commands_remain_allowed_without_search(self) -> None:
        for command in [
            "cat file.go",
            "grep -n 'func' file.go",
            "gofmt -w file.go",
            "go test ./...",
            "echo 'ast-grep is preferred'",
        ]:
            with self.subTest(command=command):
                self.assert_decision(payload(command), None)

    def test_state_is_isolated_by_session(self) -> None:
        self.mark_search()
        self.assert_decision(payload("vibe-apply-patch < change.diff", session_id="other-session"), "deny")

    def test_malformed_bash_payload_fails_closed_with_json(self) -> None:
        bad = payload("vibe-apply-patch < change.diff")
        bad["tool_input"] = {}
        self.assert_decision(bad, "deny")

    def test_malformed_post_payload_does_not_replace_tool_output(self) -> None:
        bad = payload("ast-grep run --lang go -p '$X' file.go", event="post_tool")
        bad["tool_input"] = {}
        self.assert_decision(bad, None)

    def test_malformed_json_fails_closed_with_json(self) -> None:
        code, stdout, stderr = self.run_guard("{not json")
        self.assertEqual(code, 0, stderr)
        self.assertEqual(json.loads(stdout)["decision"], "deny")
        self.assertTrue(stderr)

    def test_non_bash_payload_is_ignored(self) -> None:
        self.assert_decision(payload("vibe-apply-patch < change.diff", tool_name="read_file"), None)


if __name__ == "__main__":
    unittest.main(verbosity=2)
