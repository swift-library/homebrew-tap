# Tap Agent Guide

Read `README.md` first. `Documentation/ReleaseUpdates.md` owns the distribution
update contract. Live formulae belong in `Formula/`, release identities in
`Metadata/`, and GitHub automation in `.github/`.

Preserve immutable release identities. Update formulae only from published
non-draft, non-prerelease GitHub Releases. Verify style, audit, source install,
and runtime behavior before publishing a formula update. Keep generated
candidates and one-run evidence out of tracked files. The default branch is
`master`.
