# SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
# Copyright (c) 2026 Xudong Xu

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("release_notices", ROOT / "Scripts/release-notices.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
SOURCE = "a" * 40
TAP = "swift-library/homebrew-tap"
RUN = "https://github.com/swift-library/homebrew-tap/actions/runs/1"


def record(name="swift-sh", version="0.2.1", release=2):
    repository = "swift-library/" + name
    return {
        "repository": repository, "version": version, "tag": "v" + version,
        "releaseID": release, "commit": "b" * 40, "sha256": "c" * 64,
        "archiveURL": f"https://github.com/{repository}/archive/refs/tags/v{version}.tar.gz",
    }


def write_record(root, value):
    directory = root / "Metadata"
    directory.mkdir(parents=True, exist_ok=True)
    (directory / (value["repository"].split("/")[1] + ".json")).write_text(json.dumps(value))


class FakeAPI:
    def __init__(self, pages=None, commit=SOURCE, fail_post=False):
        self.pages = pages or [[]]
        self.commit = commit
        self.fail_post = fail_post
        self.calls = []

    def __call__(self, method, path, body=None):
        self.calls.append((method, path, body))
        if method == "POST":
            if self.fail_post:
                raise subprocess.CalledProcessError(1, ["gh", "api"])
            return {"html_url": "https://github.com/" + TAP + "/issues/1"}
        if path.endswith("/commits/master"):
            return {"sha": self.commit}
        return self.pages[int(path.rsplit("=", 1)[1]) - 1]

    @property
    def posts(self):
        return [call for call in self.calls if call[0] == "POST"]


class ReleaseNoticeTests(unittest.TestCase):
    def setUp(self):
        output = ROOT / ".build/notice-tests"
        output.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(dir=output)
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.candidate = self.root / ".candidate"
        write_record(self.root, record(version="0.2.0", release=1))

    def notify(self, api):
        return module.notify(self.root, self.candidate, TAP, SOURCE, RUN, api)

    def test_new_release_creates_an_identity_bound_notice(self):
        value = record()
        write_record(self.candidate, value)
        api = FakeAPI()
        self.assertEqual(self.notify(api), 1)
        self.assertEqual(len(api.posts), 1)
        self.assertEqual(api.posts[0][1], "repos/" + TAP + "/issues")
        body = api.posts[0][2]["body"]
        for expected in [module.marker(value), value["commit"], value["sha256"], RUN]:
            self.assertIn(expected, body)

    def test_open_and_closed_notices_are_not_repeated(self):
        value = record()
        write_record(self.candidate, value)
        for state in ("open", "closed"):
            api = FakeAPI([[{"state": state, "body": module.marker(value)}]])
            self.assertEqual(self.notify(api), 0)
            self.assertFalse(api.posts)
            self.assertIn("state=all", api.calls[1][1])

    def test_pagination_finds_a_closed_notice_on_the_next_page(self):
        value = record()
        write_record(self.candidate, value)
        api = FakeAPI([[{"body": None}] * 100, [{"state": "closed", "body": module.marker(value)}]])
        self.assertEqual(self.notify(api), 0)
        self.assertFalse(api.posts)
        self.assertTrue(api.calls[-1][1].endswith("page=2"))

    def test_pull_requests_do_not_suppress_release_notices(self):
        value = record()
        write_record(self.candidate, value)
        api = FakeAPI([[{"pull_request": {}, "body": module.marker(value)}]])
        self.assertEqual(self.notify(api), 1)

    def test_no_candidate_makes_no_remote_requests(self):
        api = FakeAPI()
        self.assertEqual(self.notify(api), 0)
        self.assertEqual(api.calls, [])

    def test_changed_default_branch_skips_notification(self):
        write_record(self.candidate, record())
        api = FakeAPI(commit="d" * 40)
        self.assertEqual(self.notify(api), 0)
        self.assertFalse(api.posts)
        self.assertEqual(len(api.calls), 1)

    def test_failed_creation_is_not_retried(self):
        write_record(self.candidate, record())
        api = FakeAPI(fail_post=True)
        with self.assertRaises(subprocess.CalledProcessError):
            self.notify(api)
        self.assertEqual(len(api.posts), 1)

    def test_candidate_outside_catalog_is_rejected_before_remote_requests(self):
        write_record(self.candidate, record("swift-unknown"))
        api = FakeAPI()
        with self.assertRaises(ValueError):
            self.notify(api)
        self.assertFalse(api.calls)

    def test_invalid_release_identity_is_rejected(self):
        value = record()
        value["commit"] = "invalid"
        write_record(self.candidate, value)
        with self.assertRaises(ValueError):
            self.notify(FakeAPI())

    def test_detection_aggregates_changes_across_all_tools_and_verifies_them(self):
        write_record(self.root, record("swift-interface-distiller", "0.1.2"))
        calls = []

        def invoke(arguments, root, environment):
            calls.append(arguments)
            self.assertNotIn("GITHUB_OUTPUT", environment)
            if arguments[-1] == "swift-library/swift-interface-distiller":
                write_record(self.candidate, record("swift-interface-distiller", "0.1.3", 3))

        with patch.dict(os.environ, {"GITHUB_OUTPUT": "unused-output"}):
            self.assertEqual(module.detect(self.root, self.candidate, invoke), 1)
        self.assertEqual([call[-1] for call in calls[:2]],
                         ["swift-library/swift-interface-distiller", "swift-library/swift-sh"])
        self.assertEqual(calls[-1][-2:], ["verify", str(self.candidate)])

    def test_detection_with_no_new_release_does_not_verify_an_empty_candidate(self):
        calls = []
        self.assertEqual(module.detect(self.root, self.candidate, lambda *args: calls.append(args)), 0)
        self.assertEqual(len(calls), 1)

    def test_detection_preserves_an_existing_candidate(self):
        write_record(self.candidate, record())
        with self.assertRaises(ValueError):
            module.detect(self.root, self.candidate, lambda *args: self.fail("Unexpected command"))
        self.assertTrue((self.candidate / "Metadata/swift-sh.json").is_file())


if __name__ == "__main__":
    unittest.main()
