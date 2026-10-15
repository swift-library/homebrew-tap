<div align="center">

<p align="center">
  <a href="https://github.com/swift-library/homebrew-tap"><img src="Documentation/Assets/Logo.svg" width="160" alt="homebrew-tap logo"></a>
</p>

<h1 align="center">homebrew-tap</h1>

<p align="center">
  Install swift-library command-line tools from release archives verified by SHA-256.
</p>

<p align="center">
  <a href="https://github.com/swift-library/homebrew-tap/actions/workflows/verify.yml"><img src="https://github.com/swift-library/homebrew-tap/actions/workflows/verify.yml/badge.svg?branch=master" alt="CI"></a>
  <a href="LICENSE.txt"><img src="https://img.shields.io/badge/license-Apache--2.0-blue?style=flat" alt="License: Apache-2.0 WITH Swift-exception"></a>
</p>

<p align="center">
  <a href="#overview">Overview</a> ·
  <a href="#quick-look">Quick look</a> ·
  <a href="#install">Install</a> ·
  <a href="#usage">Usage</a> ·
  <a href="#requirements">Requirements</a> ·
  <a href="#documentation">Documentation</a> ·
  <a href="#contributing">Contributing</a> ·
  <a href="#license">License</a>
</p>

</div>

## Overview

Homebrew handles the source build and adds the executable to your path. The [tool guide](Documentation/Tools.md) explains toolchain requirements, platform support, and command differences.

## Quick look

```sh
brew install swift-library/tap/swift-sh
swift sh --version
```

## Install

Install [Homebrew](https://brew.sh/), then use a full formula name as shown above. `brew install` adds the tap automatically; `brew tap swift-library/tap` adds it explicitly.

## Usage

Run `brew update` to fetch formula changes and `brew upgrade swift-library/tap/swift-sh` to update an installed tool. Browse [the formula directory](Formula/) for available tools and open each project’s README for its commands.

## Requirements

- Swift 6.3 or later for the tools built by the formulae
- On macOS, macOS 15 or later and a matching Xcode SDK/toolchain, as described in the [tool guide](Documentation/Tools.md)
- Linux is supported by swift-sh and swift-interface-distiller; check the selected tool’s requirements

## Documentation

- [Tool installation](Documentation/Tools.md): platform differences, completions, and command prerequisites
- [Release updates](Documentation/ReleaseUpdates.md): distribution verification and maintainer checks

## Contributing

Open a pull request for changes to formulae, the updater, or workflows. The
verify workflow runs the same checks on every pull request.
[Release updates](Documentation/ReleaseUpdates.md) describes how releases are
selected and verified, and lists the checks to run locally. Report problems
with a tool itself to its project.

## License

The tap's updater and automation code is available under the Apache License
2.0 with the Swift Runtime Library Exception. See [LICENSE.txt](LICENSE.txt).
Each formula installs software under its project's own license. All tools use
the Apache License 2.0 with the Swift Runtime Library Exception and install
their third-party notices alongside the executable.
