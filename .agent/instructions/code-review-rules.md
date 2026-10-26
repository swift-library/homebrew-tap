---
description: Flag tap changes that break release identity, omit consumer requirements, or claim untested updater behavior.
---
## Code Review Rules

### Release identity

- Flag a formula update that cannot be traced to the published stable release
  selected by `Documentation/ReleaseUpdates.md`; consumers must receive the
  accepted source. Safe path: regenerate and verify the release metadata and
  archive checksum together.

### Consumer behavior

- Flag a new toolchain or runtime requirement that the formula or install
  guidance omits. Safe path: declare the requirement and validate installation
  and `brew test` on the supported systems.

### Claims and tests

- Flag updater behavior changes without a regression case, or README claims
  unsupported by the formula and checks. Safe path: cover release selection
  in the updater tests and describe the verified installation behavior.
