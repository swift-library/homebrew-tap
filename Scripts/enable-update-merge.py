#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
"""Enable ruleset-governed auto-merge for the Updater App's exact proposal."""

import argparse
import json
import re
import subprocess


def gh(*arguments):
    return subprocess.check_output(["gh", *arguments], text=True)


def enable(repository, number, head, bot):
    if not re.fullmatch(r"[0-9a-f]{40}", head) or not bot.endswith("[bot]"):
        raise ValueError("Expected a full commit SHA and App bot login")
    proposal = json.loads(gh("api", f"repos/{repository}/pulls/{number}"))
    if (proposal["state"] != "open" or proposal["draft"]
            or (proposal["head"].get("repo") or {}).get("full_name") != repository
            or proposal["user"]["login"] != bot
            or proposal["base"]["ref"] != "master"
            or proposal["head"]["ref"] != "automation/update-swift-sh"
            or proposal["head"]["sha"] != head):
        raise ValueError("Pull request is not the expected Updater App proposal")
    commit = json.loads(gh("api", f"repos/{repository}/commits/{head}"))
    if (not commit["commit"]["verification"]["verified"]
            or (commit.get("author") or {}).get("login") != bot):
        raise ValueError("Proposal head must be a Verified commit by the Updater App")
    files = set(gh("pr", "diff", str(number), "--repo", repository, "--name-only").splitlines())
    if files != {"Formula/swift-sh.rb", "Metadata/swift-sh.json"}:
        raise ValueError("Proposal must contain only the formula and its release metadata")
    gh("pr", "merge", str(number), "--repo", repository,
       "--auto", "--squash", "--match-head-commit", head)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--number", required=True, type=int)
    parser.add_argument("--head", required=True)
    parser.add_argument("--bot", required=True)
    args = parser.parse_args()
    enable(args.repository, args.number, args.head, args.bot)


if __name__ == "__main__":
    main()
