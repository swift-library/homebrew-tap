// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu and the swift-library project authors

extension ReleaseRecord {
  var interfaceDistillerFormula: String {
    """
    class SwiftInterfaceDistiller < Formula
      desc "Distill a Swift package to its public API"
      homepage "https://github.com/swift-library/swift-interface-distiller"
      url "\(archiveURL)"
      sha256 "\(sha256)"
      license "Apache-2.0" => { with: "Swift-exception" }

      env :std

      on_macos do
        depends_on xcode: ["26.6", :build]
        depends_on macos: :sequoia
      end
      on_linux do
        depends_on "swift"
      end

      def install
        swift_version = Utils.safe_popen_read("swift", "--version")[/Swift version (\\d+\\.\\d+(?:\\.\\d+)?)/, 1]
        if !swift_version || Version.new(swift_version) < Version.new("6.3.0")
          odie "Swift 6.3 or newer must be selected on PATH"
        end
        system "swift", "build", "--build-system", "native", "--disable-sandbox", "-c", "release",
               "--force-resolved-versions", "--product", "interface-distiller"
        bin.install ".build/release/interface-distiller"
        pkgshare.install "LICENSE.txt", "NOTICE"
      end

      test do
        assert_equal "\(version)\\n", shell_output("#{bin}/interface-distiller --version")
        assert_match "public-interface snapshots", shell_output("#{bin}/interface-distiller --help")
        (testpath/"configuration.json").write JSON.generate(
          toolchain: "fixture", sdk: "fixture", triple: "fixture", deploymentTarget: "fixture",
          languageMode: "6", buildMode: "debug", conditions: [], traits: [], environment: {},
          extractorVersion: "\(version)"
        )
        (testpath/"fixture.symbols.json").write JSON.generate(
          metadata:      { formatVersion: { major: 0, minor: 6, patch: 0 }, generator: "fixture" },
          module:        { name: "Fixture" },
          symbols:       [{ identifier: { precise: "s:7Fixture1AV", interfaceLanguage: "swift" },
                      kind: { identifier: "swift.struct", displayName: "Structure" },
                      names: { title: "A" }, accessLevel: "public" }],
          relationships: [],
        )
        system bin/"interface-distiller", "normalize", testpath/"fixture.symbols.json",
               "--configuration", testpath/"configuration.json", "--output", testpath/"snapshot.json"
        coverage = JSON.parse(shell_output("#{bin}/interface-distiller coverage #{testpath}/snapshot.json"))
        assert_equal 1, coverage.first.fetch("eligible")
        assert_equal 0, coverage.first.fetch("documented")
      end
    end

    """
  }
}
