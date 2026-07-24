#!/usr/bin/env python3
"""Direct contract tests for the Vibe 2.22.0 user-level pre_tool guard."""

from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path


GUARD = Path(__file__).with_name("block_sed.py")


def payload(command: str, tool_name: str = "bash") -> dict[str, object]:
    return {
        "hook_event_name": "pre_tool",
        "session_id": "test-session",
        "parent_session_id": None,
        "transcript_path": "/tmp/vibe-test.jsonl",
        "cwd": "/tmp",
        "tool_name": tool_name,
        "tool_call_id": "call-test",
        "tool_input": {"command": command},
    }


def run_guard(raw_payload: str) -> tuple[int, str, str]:
    result = subprocess.run(
        [sys.executable, str(GUARD)],
        input=raw_payload,
        text=True,
        capture_output=True,
        check=False,
    )
    return result.returncode, result.stdout, result.stderr


class BlockSedTests(unittest.TestCase):
    blocked_commands = [
        "sed -i 's/a/b/' file.txt",
        "/bin/sed -n '1p' file.txt",
        "/usr/bin/sed -n '1p' file.txt",
        "command sed -n '1p' file.txt",
        "env sed -n '1p' file.txt",
        "env NAME=value sed -n '1p' file.txt",
        "sudo sed -n '1p' file.txt",
        "sudo -n sed -n '1p' file.txt",
        "true && sed -n '1p' file.txt",
        "false || sed -n '1p' file.txt",
        "cat file.txt | sed -n '1p'",
        "sed -n '1p' file.txt ; gofmt -w file.go",
        "bash -c 'sed -n 1p file.txt'",
        'sh -c "printf x | sed -n \'1p\'"',
        "find . -exec sed -n '1p' {} +",
        "find . -execdir sed -n '1p' {} +",
        "printf '%s' $(sed -n '1p' file.txt)",
        "printf '%s' `sed -n '1p' file.txt`",
        "bash -c \"$(printf sed)\"",
        "runner=sed; $runner -n '1p' file.txt",
        "eval 'sed -n 1p file.txt'",
    ]

    allowed_commands = [
        "grep -R sed .",
        "git grep 'sed -i'",
        "printf '%s\\n' sed",
        'echo "do not use sed"',
        "cat sediment.txt",
        "test -f notes-about-sed.txt",
        "ast-grep --pattern 'sed'",
        "gofmt -w file.go",
        "go test ./...",
        "find . -exec echo sed {} +",
    ]

    def assert_decision(self, command: str, expected: str | None) -> None:
        code, stdout, stderr = run_guard(json.dumps(payload(command)))
        self.assertEqual(code, 0, stderr)
        if expected is None:
            self.assertEqual(stdout, "", stderr)
            return
        response = json.loads(stdout)
        self.assertEqual(response["decision"], expected)
        self.assertIsInstance(response.get("reason"), str)

    def test_blocked_command_positions(self) -> None:
        for command in self.blocked_commands:
            with self.subTest(command=command):
                self.assert_decision(command, "deny")

    def test_allowed_text_and_paths(self) -> None:
        for command in self.allowed_commands:
            with self.subTest(command=command):
                self.assert_decision(command, None)

    def test_malformed_json_fails_closed_with_valid_json(self) -> None:
        code, stdout, stderr = run_guard("{not json")
        self.assertEqual(code, 0, stderr)
        self.assertEqual(json.loads(stdout)["decision"], "deny")
        self.assertTrue(stderr)

    def test_malformed_bash_payload_fails_closed(self) -> None:
        bad = payload("printf allowed")
        bad["tool_input"] = {}
        code, stdout, stderr = run_guard(json.dumps(bad))
        self.assertEqual(code, 0, stderr)
        self.assertEqual(json.loads(stdout)["decision"], "deny")

    def test_malformed_shell_command_fails_closed(self) -> None:
        self.assert_decision("sed 'unterminated", "deny")

    def test_non_bash_payload_is_ignored(self) -> None:
        code, stdout, stderr = run_guard(json.dumps(payload("sed -n '1p'", "read_file")))
        self.assertEqual(code, 0, stderr)
        self.assertEqual(stdout, "")


if __name__ == "__main__":
    unittest.main(verbosity=2)
