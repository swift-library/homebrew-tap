class SwiftInterfaceDistiller < Formula
  desc "Collect, query, and compare public-interface evidence from compiler reports"
  homepage "https://github.com/swift-library/swift-interface-distiller"
  url "https://github.com/swift-library/swift-interface-distiller/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "40a1e9c6d29413809298e1a0efad69129b559b2fab6ad3a2b2fe994df2294dda"
  license "Apache-2.0" => { with: "Swift-exception" }

  env :std

  on_macos do
    depends_on xcode: ["26.0", :build]
    depends_on macos: :sequoia
  end
  on_linux do
    depends_on "swift"
  end

  def install
    swift_version = Utils.safe_popen_read("swift", "--version")[/Swift version (\d+\.\d+(?:\.\d+)?)/, 1]
    if !swift_version || Version.new(swift_version) < Version.new("6.3.0")
      odie "Swift 6.3 or newer must be selected on PATH"
    end
    system "swift", "build", "--build-system", "native", "--disable-sandbox", "-c", "release",
           "--force-resolved-versions", "--product", "interface-distiller"
    bin.install ".build/release/interface-distiller"
    pkgshare.install "LICENSE.txt", "NOTICE"
  end

  test do
    assert_equal "0.2.0\n", shell_output("#{bin}/interface-distiller --version")
    assert_match "public-interface evidence", shell_output("#{bin}/interface-distiller --help")
    (testpath/"configuration.json").write JSON.generate(
      toolchain: "fixture", sdk: "fixture", triple: "fixture", deploymentTarget: "fixture",
      languageMode: "6", buildMode: "debug", conditions: [], traits: [], environment: {},
      extractorVersion: "0.2.0"
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
           "--configuration", testpath/"configuration.json", "--output", testpath/"evidence.json"
    coverage = JSON.parse(shell_output("#{bin}/interface-distiller coverage #{testpath}/evidence.json"))
    assert_equal 1, coverage.first.fetch("eligible")
    assert_equal 0, coverage.first.fetch("documented")
  end
end
