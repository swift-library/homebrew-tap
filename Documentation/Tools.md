# Tool installation

Browse [Formula](../Formula/) for the current tools and [Metadata](../Metadata/)
for their release identities and archive checksums.

The tools build with Swift 6.3 or later. On macOS, use macOS 15 or later and
select Xcode with `xcode-select`: Xcode 26 or later, and Xcode 26.6 or later for
swift-interface-distiller. A standalone Swift toolchain must be
selected for both `swift` and `xcrun`; the Xcode SDK supplies the platform
libraries. swift-sh and swift-interface-distiller also support Linux.

swift-appstoreconnect installs the `appstoreconnect` command and Bash, Zsh and
Fish completions. Its schema inspection commands require a source checkout
containing the `Vendor` directory. Live API commands require caller-provided
credentials; the formula's installation test uses a local dry-run workflow.
