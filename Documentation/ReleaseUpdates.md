# Release Updates

`Sources/TapUpdater` owns release selection and formula rendering. The updater
uses SemVer precedence and accepts `vVERSION` tags from published GitHub
Releases. Drafts, prereleases, malformed versions, and versions no newer than
the installed formula are ignored. Version 0.x releases are eligible.

`Metadata/swift-sh.json` binds a formula to its repository, Release ID, tag,
version, source commit, archive URL, and SHA-256. Annotated tags resolve to their
commit. A staged update is verified against GitHub again before publication.
Changing a published identity fails validation.

The daily workflow stages files in an untracked candidate directory. Read-only
jobs validate the updater and the staged distribution on macOS 15 and 26 with
matching SDKs and Swift toolchains. Checks include strict Swift and Ruby
formatting, Homebrew audit, installation from the source archive, version/help,
and an independent script run. The proposal job rechecks the release identity
and validates that `master` still matches the prepared source commit.

The organization-owned Updater App opens or updates a pull request from
`automation/update-swift-sh`. Its installation token is scoped to this tap
with `contents: write` and `pull_requests: write`; the workflow token remains
read-only. The App creates GitHub-verified signed commits containing only the
formula and its release metadata. Its pull request triggers the normal policy
and installation checks.

Auto-merge is requested for the exact signed head only after checking the
proposal's author, repository, branches and changed files. The default-branch
ruleset still requires successful checks and resolved review threads. The App
has no ruleset bypass. If `master` moves before the proposal step, that run
fails and the next scheduled run prepares a fresh candidate. Repeated runs
reuse the same proposal branch; a check with no newer release makes no change.

Pull requests remain the review entry point for manual formula, updater,
dependency, and Actions changes. Workflow permissions are read-only by default,
Actions are pinned to complete commit SHAs, and Dependabot runs weekly.

## Updater App Setup

An organization owner configures the App before enabling this workflow:

1. Register an organization-owned GitHub App with repository permissions
   **Contents: read and write** and **Pull requests: read and write**.
   Metadata read access is implicit. Webhooks are not needed.
2. Install it on `homebrew-tap` only. Record its client ID and the exact bot
   login, `<app-slug>[bot]`.
3. Add repository variables `UPDATER_APP_CLIENT_ID` and `UPDATER_APP_BOT_LOGIN`.
   Generate an App private key and store it directly as the repository secret
   `UPDATER_APP_PRIVATE_KEY`. Keep the key out of source and build artifacts.
4. Enable **Allow auto-merge** for this repository. Keep squash-only merging,
   signature requirements, required checks and the no-bypass rule in place.
5. Update the organization's
   [MAINTENANCE.md](https://github.com/swift-library/.github/blob/master/MAINTENANCE.md)
   in the same settings change: record the actual App slug, installation and
   permissions, repository variable values, secret name, and auto-merge setting.
   Run its settings checker against the configured state.
6. Run **Update published releases** manually. When a newer stable release
   exists, verify the App-authored PR, GitHub Verified commit, required checks
   and squash merge. A no-change run verifies release discovery only; it does
   not prove the authenticated proposal and merge path.

The workflow checks that the configured bot login belongs to the token's App
before opening a pull request. The source policy allows this exact bot identity
and still requires every commit in the proposed range to be GitHub Verified.

## Local Checks

```sh
swift test --force-resolved-versions
python3 -B -m unittest discover -s Tests/Automation
xcrun swift-format lint --strict --configuration .swift-format --recursive Package.swift Sources Tests
swift run --force-resolved-versions tap-updater prepare
```

A prepared candidate contains only `Formula/` and `Metadata/`. After applying
those files to a reviewed tap checkout, run Homebrew style, strict audit,
installation from source, and `brew test` for `swift-library/tap/swift-sh`.
The update workflow records source commit, validation logs, and candidate files
as GitHub Actions artifacts.
