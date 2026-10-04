# swift-library Homebrew Tap

Install the organization's Swift command-line tools from published source
releases:

```sh
brew install swift-library/tap/swift-sh
```

swift-sh requires Swift 6.3 or newer on `PATH`. On macOS, it requires macOS 15
or newer and the SDK from Xcode 26 or newer. Select a matching Swift release
toolchain when Xcode's bundled compiler is older. The formula uses the selected
toolchain for its source build and the CLI uses it to compile scripts.

The tap checks formal GitHub Releases daily. Candidate formula updates pass
formatting, audit, source installation, and runtime checks before a separate
publishing job updates `master`. Weekly dependency and Actions updates use
Dependabot pull requests.

[Release update policy](Documentation/ReleaseUpdates.md) describes version
selection, immutable identities, permissions, and validation. The internal
Swift updater uses [SemVer](https://github.com/swift-library/swift-semver).
Formulae retain their products' licenses; updater and automation code use
[Apache-2.0 WITH Swift-exception](LICENSE.txt).
