---
description: Keep swift-library tap formula updates tied to published stable releases and verified installs.
---
# Tap Agent Guide

Read `README.md` first. `Documentation/ReleaseUpdates.md` owns the distribution
update contract. Live formulae belong in `Formula/`, release identities in
`Metadata/`, repository automation scripts in `scripts/`, and GitHub workflows
in `.github/`.

Preserve immutable release identities. Update formulae only from published
non-draft, non-prerelease GitHub Releases. Verify style, audit, source install,
and runtime behavior before publishing a formula update. Keep generated
candidates and one-run check output out of tracked files.
