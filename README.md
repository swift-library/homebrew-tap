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
```

`brew install` adds the tap on its own when you use the full name, so
`brew tap` is optional. `brew update` fetches new formula versions, and
`brew upgrade` installs them.

## Formulae

| Formula | Description | Project |
| --- | --- | --- |
| `swift-sh` | Run single-file Swift scripts with SwiftPM dependencies | [swift-library/swift-sh](https://github.com/swift-library/swift-sh) |

Formulae build with the Swift toolchain on your `PATH`. swift-sh needs Swift
6.3 or later. On macOS it also needs macOS 15 or later and Xcode 26 or later
selected with `xcode-select`.

## Updates

A scheduled workflow checks swift-sh for a newer published GitHub release
every day and skips drafts and prereleases. A formula update reaches `master`
only after it passes Homebrew style and strict audit checks, a build from
source, and `brew test` on macOS 15 and macOS 26. The configured Updater App
proposes updates through signed pull requests with auto-merge governed by the
repository's required checks.

## Contributing

Open a pull request for changes to formulae, the updater, or workflows. The
verify workflow runs the same checks on every pull request.
[Release updates](Documentation/ReleaseUpdates.md) describes how releases are
selected and verified, and lists the checks to run locally. Report problems
with a tool itself to its project.

## License

The tap's updater and automation code is available under the Apache License
2.0 with the Swift Runtime Library Exception. See [LICENSE.txt](LICENSE.txt).
Each formula installs software under its project's own license; swift-sh is
released under the Apache License 2.0 with the Swift Runtime Library Exception.
