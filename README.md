<p align="center">
  <img src="Documentation/Assets/Logo.svg" width="160" alt="homebrew-tap logo">
</p>

<h1 align="center">homebrew-tap</h1>

<p align="center">
  Homebrew formulae for the swift-library command-line tools.
</p>

<p align="center">
  <a href="https://github.com/swift-library/homebrew-tap/actions/workflows/verify.yml"><img src="https://github.com/swift-library/homebrew-tap/actions/workflows/verify.yml/badge.svg?branch=master" alt="CI"></a>
  <a href="LICENSE.txt"><img src="https://img.shields.io/badge/license-Apache--2.0-blue" alt="License: Apache-2.0 WITH Swift-exception"></a>
</p>

[Overview](#overview) · [Usage](#usage) · [Formulae](#formulae) ·
[Updates](#updates) · [Contributing](#contributing) · [License](#license)

## Overview

This tap installs swift-library tools with Homebrew. Each formula builds its
tool from the source archive of a published GitHub release and checks the
archive against a recorded SHA-256 checksum.

## Usage

Add the tap, then install a formula by its full name:

```bash
brew tap swift-library/tap
brew install swift-library/tap/swift-sh
brew install swift-library/tap/swift-appstoreconnect
```

`brew install` adds the tap on its own when you use the full name, so
`brew tap` is optional. `brew update` fetches new formula versions, and
`brew upgrade` installs them.

## Formulae

| Formula | Description | Project |
| --- | --- | --- |
| `swift-sh` | Run single-file Swift scripts with SwiftPM dependencies | [swift-library/swift-sh](https://github.com/swift-library/swift-sh) |
| `swift-appstoreconnect` | Typed App Store Connect API clients and workflow commands | [swift-library/swift-appstoreconnect](https://github.com/swift-library/swift-appstoreconnect) |

Formulae need Swift 6.3 or later. On macOS, select Xcode 26 or later with
`xcode-select` and use macOS 15 or later. A standalone Swift toolchain must be
selected for both `swift` and `xcrun`; the Xcode SDK supplies the platform
libraries. swift-sh also supports Linux.

swift-appstoreconnect installs the `appstoreconnect` command and Bash, Zsh and
Fish completions. Its schema inspection commands require a source checkout
containing the `Vendor` directory. Live API commands require caller-provided
credentials; the formula's installation test uses a local dry-run workflow.

## Updates

A scheduled workflow prepares swift-sh updates from stable GitHub releases.
The organization-owned Updater App opens signed pull requests and requests
squash auto-merge after validating the selected release and proposal identity.
Required checks include Homebrew style and strict audit, installation from
source, and runtime tests on macOS 15 and macOS 26. App Store Connect updates
use the updater's manual review flow.

The App requires the setup described in
[Release updates](Documentation/ReleaseUpdates.md#updater-app-setup).

## Contributing

Open a pull request for changes to formulae, the updater, or workflows. The
verify workflow runs the same checks on every pull request.
[Release updates](Documentation/ReleaseUpdates.md) describes how releases are
selected and verified, and lists the checks to run locally. Report problems
with a tool itself to its project.

## License

The tap's updater and automation code is available under the Apache License
2.0 with the Swift Runtime Library Exception. See [LICENSE.txt](LICENSE.txt).
Each formula installs software under its project's own license. Both tools use
the Apache License 2.0 with the Swift Runtime Library Exception and install
their third-party notices alongside the executable.
