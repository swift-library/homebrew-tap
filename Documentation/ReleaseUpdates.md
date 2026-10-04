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
and an independent script run. The final job alone receives `contents: write`
and commits the verified files to `master` as `github-actions[bot]`.

Updates use a fast-forward push from the validated base commit. Concurrent
source changes reject the push; the next run stages a new candidate. The whole
flow is repeatable and a repeated check with no newer release makes no change.
There is no subsequent push-triggered verification dependency: GitHub's default
workflow token does not trigger a fresh push workflow, so validation occurs
before the publishing job.

Pull requests remain the review entry point for manual formula, updater,
dependency, and Actions changes. Workflow permissions are read-only by default,
Actions are pinned to complete commit SHAs, and Dependabot runs weekly.

## Local Checks

```sh
swift test --force-resolved-versions
xcrun swift-format lint --strict --configuration .swift-format --recursive Package.swift Sources Tests
swift run --force-resolved-versions tap-updater prepare
```

A prepared candidate contains only `Formula/` and `Metadata/`. After applying
those files to a reviewed tap checkout, run Homebrew style, strict audit,
installation from source, and `brew test` for `swift-library/tap/swift-sh`.
The update workflow records source commit, validation logs, and candidate files
as GitHub Actions artifacts.
