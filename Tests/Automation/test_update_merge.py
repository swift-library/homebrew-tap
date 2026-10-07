# SPDX-License-Identifier: Apache-2.0 WITH Swift-exception

from copy import deepcopy
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "update_merge", Path(__file__).resolve().parents[2] / "Scripts/enable-update-merge.py",
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
HEAD = "a" * 40
BOT = "release-updater[bot]"


class UpdateMergeTests(unittest.TestCase):
    def setUp(self):
        self.proposal = {
            "state": "open", "draft": False, "user": {"login": BOT},
            "base": {"ref": "master"},
            "head": {"ref": "automation/update-swift-sh", "sha": HEAD,
                     "repo": {"full_name": "fixture/tap"}},
        }
        self.commit = {"author": {"login": BOT}, "commit": {"verification": {"verified": True}}}
        self.files = "Formula/swift-sh.rb\nMetadata/swift-sh.json\n"

    def run_proposal(self):
        module.enable("fixture/tap", 7, HEAD, BOT)

    def responses(self):
        return [json.dumps(self.proposal), json.dumps(self.commit), self.files, ""]

    def test_verified_proposal_requests_auto_merge_for_exact_head(self):
        with patch.object(module, "gh", side_effect=self.responses()) as gh:
            self.run_proposal()
        self.assertEqual(gh.call_args.args, (
            "pr", "merge", "7", "--repo", "fixture/tap", "--auto", "--squash",
            "--match-head-commit", HEAD,
        ))

    def test_unexpected_proposals_never_request_a_merge(self):
        original = deepcopy(self.proposal)
        for key, value in (
            ("state", "closed"), ("draft", True),
            ("user", {"login": "different[bot]"}), ("base", {"ref": "release"}),
            ("head", {**original["head"], "ref": "manual/update"}),
            ("head", {**original["head"], "sha": "b" * 40}),
            ("head", {**original["head"], "repo": {"full_name": "other/tap"}}),
        ):
            with self.subTest(key=key):
                self.proposal = {**original, key: value}
                with patch.object(module, "gh", side_effect=self.responses()) as gh:
                    with self.assertRaises(ValueError):
                        self.run_proposal()
                self.assertEqual(gh.call_count, 1)

    def test_unsigned_or_different_author_commits_never_request_a_merge(self):
        for commit in (
            {"author": {"login": BOT}, "commit": {"verification": {"verified": False}}},
            {"author": {"login": "different[bot]"}, "commit": {"verification": {"verified": True}}},
        ):
            with self.subTest(commit=commit):
                self.commit = commit
                with patch.object(module, "gh", side_effect=self.responses()) as gh:
                    with self.assertRaises(ValueError):
                        self.run_proposal()
                self.assertEqual(gh.call_count, 2)

    def test_partial_or_unrelated_changes_never_request_a_merge(self):
        for files in ("Formula/swift-sh.rb\n", self.files + "README.md\n", ""):
            with self.subTest(files=files):
                self.files = files
                with patch.object(module, "gh", side_effect=self.responses()) as gh:
                    with self.assertRaises(ValueError):
                        self.run_proposal()
                self.assertEqual(gh.call_count, 3)


if __name__ == "__main__":
    unittest.main()
