# Release Updates

`Sources/TapUpdater` owns release selection and formula rendering. The updater
uses SemVer precedence and accepts `vVERSION` tags from published GitHub
Releases. Drafts, prereleases, malformed versions, and versions no newer than
the installed formula are ignored. Version 0.x releases are eligible.

`Metadata/<formula>.json` binds each formula to its repository, Release ID, tag,
version, source commit, archive URL, and SHA-256. Annotated tags resolve to their
commit. A staged update is verified against GitHub again before publication.
Changing a published identity fails validation.

The updater supports `swift-sh`, `swift-appstoreconnect` and
`swift-interface-distiller`. Verification
requires a matching metadata record for every formula and checks each selected
release, commit, archive digest and rendered formula against GitHub. The default
preparation command selects swift-sh; an explicit repository selects another
supported tool. A candidate can contain one distribution, while a tap checkout must
verify every live formula.

The daily workflow checks every distribution recorded in `Metadata/` and
prepares newer releases in an untracked candidate directory. It verifies the
candidate release identities and archives, then opens an issue linking the
detection run and its candidate artifact. The issue records the release ID,
version, source commit and archive checksum.

Notifications use the workflow token with issue-write permission. Runs are
serialized, and both open and closed issues are checked for the repository and
release ID before creating a notice. Closing a notice records that release's
disposition. If the default branch changed since detection, notification waits
for a new detection run to recheck the current formulae.

For each tool release, the maintainer prepares or downloads its candidate,
reviews the formula and metadata together, and runs the local checks below.
Apply accepted candidates on an owner-signed branch and submit a pull request.
After required checks pass and review threads are resolved, squash-merge the
exact reviewed head under the
[shared change flow](https://github.com/swift-library/.github/blob/master/MAINTENANCE.md#change-flow).
Close the release notice after that merge, or when intentionally declining the
release. Existing release tags and metadata remain immutable.

Read-only PR jobs validate the updater and all three distributions on macOS 15 and
26 with matching SDKs and Swift toolchains. Checks include strict Swift and Ruby
formatting, Homebrew audit, installation from source, and version/help checks.
swift-sh runs an independent script. App Store Connect runs a local workflow
plan and verifies the three installed shell completions. These checks require
no Apple credentials or live API requests. Interface Distiller normalizes a small
symbol graph and checks its documentation coverage.

Pull requests remain the review entry point for manual formula, updater,
dependency, and Actions changes. Workflow permissions are read-only by default,
Actions are pinned to complete commit SHAs, and Dependabot runs weekly.

## Local Checks

```sh
swift test --force-resolved-versions
python3 -B -m unittest discover -s Tests/Automation
xcrun swift-format lint --strict --configuration .swift-format --recursive Package.swift Sources Tests
swift run --force-resolved-versions tap-updater prepare
swift run --force-resolved-versions tap-updater prepare .candidate swift-library/swift-appstoreconnect
swift run --force-resolved-versions tap-updater prepare .candidate swift-library/swift-interface-distiller
swift run --force-resolved-versions tap-updater verify .candidate
```

A prepared candidate contains only `Formula/` and `Metadata/`. After applying
those files to a reviewed tap checkout, run Homebrew style, strict audit,
installation from source, and `brew test` for each changed formula by its full
`swift-library/tap/<formula>` name.
The update workflow records its source commit and uploads verified candidate
files. Pull request validation records the installation and runtime logs as
GitHub Actions artifacts.
