# Release Updates

`Sources/TapUpdater` owns release selection and formula rendering. The updater
uses SemVer precedence and accepts `vVERSION` tags from published GitHub
Releases. Drafts, prereleases, malformed versions, and versions no newer than
the installed formula are ignored. Version 0.x releases are eligible.

`Metadata/<formula>.json` binds each formula to its repository, Release ID, tag,
version, source commit, archive URL, and SHA-256. Annotated tags resolve to their
commit. A staged update is verified against GitHub again before publication.
Changing a published identity fails validation.

The updater supports `swift-sh` and `swift-appstoreconnect`. Verification
requires a matching metadata record for every formula and checks each selected
release, commit, archive digest and rendered formula against GitHub. The default
preparation command selects swift-sh; an explicit repository selects App Store
Connect. A candidate can contain one distribution, while a tap checkout must
verify every live formula.

The daily workflow prepares swift-sh updates in an untracked candidate
directory. Automatic PR publication is not configured; the protected default
branch rejects the workflow's direct publishing step. Apply accepted candidates
on a signed branch and publish them through a pull request. Existing release
tags and metadata remain immutable.

Read-only PR jobs validate the updater and both distributions on macOS 15 and
26 with matching SDKs and Swift toolchains. Checks include strict Swift and Ruby
formatting, Homebrew audit, installation from source, and version/help checks.
swift-sh runs an independent script. App Store Connect runs a local workflow
plan and verifies the three installed shell completions. These checks require
no Apple credentials or live API requests.

Pull requests remain the review entry point for manual formula, updater,
dependency, and Actions changes. Workflow permissions are read-only by default,
Actions are pinned to complete commit SHAs, and Dependabot runs weekly.

## Local Checks

```sh
swift test --force-resolved-versions
xcrun swift-format lint --strict --configuration .swift-format --recursive Package.swift Sources Tests
swift run --force-resolved-versions tap-updater prepare
swift run --force-resolved-versions tap-updater prepare .candidate swift-library/swift-appstoreconnect
swift run --force-resolved-versions tap-updater verify .candidate
```

A prepared candidate contains only `Formula/` and `Metadata/`. After applying
those files to a reviewed tap checkout, run Homebrew style, strict audit,
installation from source, and `brew test` for each changed formula by its full
`swift-library/tap/<formula>` name.
The update workflow records source commit, validation logs, and candidate files
as GitHub Actions artifacts.
