#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
# Copyright (c) 2026 Xudong Xu

"""Detect published tool releases and notify maintainers through issues."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys


def records(directory):
    if directory.is_symlink():
        raise ValueError("Release metadata must not be a symbolic link")
    result = {}
    for path in sorted(directory.glob("*.json")):
        if path.is_symlink():
            raise ValueError("Release metadata must not be a symbolic link: " + path.name)
        value = json.loads(path.read_text())
        repository = value["repository"]
        version = value["version"]
        if (
            not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository)
            or repository.split("/")[1] != path.stem
            or repository in result
            or not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", version)
            or value["tag"] != "v" + version
            or type(value["releaseID"]) is not int
            or value["releaseID"] <= 0
            or not re.fullmatch(r"[0-9a-f]{40}", value["commit"])
            or not re.fullmatch(r"[0-9a-f]{64}", value["sha256"])
            or value["archiveURL"] != f"https://github.com/{repository}/archive/refs/tags/v{version}.tar.gz"
        ):
            raise ValueError("Invalid release record: " + path.name)
        result[repository] = value
    return result


def command(arguments, root, environment):
    subprocess.run(arguments, cwd=root, env=environment, check=True)


def detect(root, candidate, invoke=command):
    if candidate.exists():
        raise ValueError("Detection requires an empty candidate destination")
    catalog = records(root / "Metadata")
    if not catalog:
        raise ValueError("The tap has no release metadata")
    environment = os.environ.copy()
    # Each prepare invocation reports its own result; this operation owns the aggregate.
    environment.pop("GITHUB_OUTPUT", None)
    for repository in catalog:
        invoke(["swift", "run", "--force-resolved-versions", "tap-updater", "prepare",
                str(candidate), repository], root, environment)
    selected = records(candidate / "Metadata")
    if selected:
        invoke(["swift", "run", "--force-resolved-versions", "tap-updater", "verify",
                str(candidate)], root, environment)
    return len(selected)


class GitHub:
    def __call__(self, method, path, body=None):
        arguments = ["gh", "api", "--method", method, path]
        if body is not None:
            arguments += ["--input", "-"]
        result = subprocess.run(
            arguments, input=json.dumps(body) if body is not None else None,
            text=True, capture_output=True, check=True,
        )
        return json.loads(result.stdout)


def marker(record):
    return f'<!-- release-update: {record["repository"]}:{record["releaseID"]} -->'


def notice(record, run_url):
    repository = record["repository"]
    return {
        "title": f'chore: update {repository.split("/")[1]} to {record["version"]}',
        "body": (
            f'{marker(record)}\n\n'
            f'A newer stable release is available: [{record["tag"]}]'
            f'(https://github.com/{repository}/releases/tag/{record["tag"]}).\n\n'
            f'- Release ID: `{record["releaseID"]}`\n'
            f'- Source commit: `{record["commit"]}`\n'
            f'- Archive SHA-256: `{record["sha256"]}`\n\n'
            f'The [detection run]({run_url}) contains the verified formula and metadata candidate. '
            'Review and validate the candidate, then publish the update through a signed pull request '
            'following [Release Updates](https://github.com/swift-library/homebrew-tap/blob/master/'
            'Documentation/ReleaseUpdates.md). Close this notice after the update lands or when '
            'the release is intentionally declined.\n'
        ),
    }


def notify(root, candidate, repository, source_commit, run_url, api):
    selected = records(candidate / "Metadata")
    catalog = records(root / "Metadata")
    if not catalog:
        raise ValueError("The tap has no release metadata")
    if not selected.keys() <= catalog.keys():
        raise ValueError("A candidate is outside the tap's release catalog")
    if not selected:
        return 0
    if not re.fullmatch(r"[0-9a-f]{40}", source_commit):
        raise ValueError("The detection source commit is invalid")
    if api("GET", f"repos/{repository}/commits/master")["sha"] != source_commit:
        print("The default branch changed; a new detection run will recheck releases.")
        return 0
    bodies = []
    page = 1
    while True:
        batch = api("GET", f"repos/{repository}/issues?state=all&per_page=100&page={page}")
        bodies.extend(issue.get("body") or "" for issue in batch if "pull_request" not in issue)
        if len(batch) < 100:
            break
        page += 1
    created = 0
    for record in selected.values():
        identity = marker(record)
        # Closed notices preserve a maintainer's disposition of this release.
        if any(identity in body for body in bodies):
            continue
        payload = notice(record, run_url)
        api("POST", f"repos/{repository}/issues", payload)
        bodies.append(payload["body"])
        created += 1
    return created


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["detect", "notify"])
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    candidate = root / ".candidate"
    if args.command == "detect":
        count = detect(root, candidate)
        if os.environ.get("GITHUB_OUTPUT"):
            with Path(os.environ["GITHUB_OUTPUT"]).open("a") as output:
                output.write("changed=" + str(count > 0).lower() + "\n")
        print(f"Verified release candidates: {count}")
    else:
        repository = os.environ["GITHUB_REPOSITORY"]
        run_url = f'{os.environ["GITHUB_SERVER_URL"]}/{repository}/actions/runs/{os.environ["GITHUB_RUN_ID"]}'
        count = notify(root, candidate, repository, os.environ["DETECTION_COMMIT"], run_url, GitHub())
        print(f"Release notices opened: {count}")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        sys.exit(error.stderr or f"Release operation failed with exit code {error.returncode}")
    except (OSError, ValueError, KeyError, TypeError) as error:
        sys.exit("Release notices: " + str(error))
