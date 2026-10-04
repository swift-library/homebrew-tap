class SwiftSh < Formula
  desc "Run single-file Swift scripts with SwiftPM dependencies"
  homepage "https://github.com/swift-library/swift-sh"
  url "https://github.com/swift-library/swift-sh/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "74e12f7308cc99a9a35fe58c9b338a0a69460cb86825dc0eebd31b01d36f1eb3"
  license "Unlicense"

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
    system "swift", "build", "--disable-sandbox", "-c", "release", "--force-resolved-versions"
    bin.install ".build/release/swift-sh"
    pkgshare.install "NOTICE", "ThirdPartyLicenses"
  end

  test do
    ENV["XDG_CACHE_HOME"] = (testpath/"cache").to_s
    ENV["SWIFT_SH_TEST_COMPILER"] = shell_output("command -v swift").strip
    # SwiftPM cannot apply a nested sandbox inside Homebrew's test sandbox.
    (testpath/"bin").mkpath
    (testpath/"bin/swift").write <<~SH
      #!/bin/sh
      case "$1" in
        build) exec "$SWIFT_SH_TEST_COMPILER" "$@" --disable-sandbox ;;
        *) exec "$SWIFT_SH_TEST_COMPILER" "$@" ;;
      esac
    SH
    (testpath/"bin/swift").chmod 0755
    ENV.prepend_path "PATH", testpath/"bin"
    assert_equal "0.1.1\n", shell_output("#{bin}/swift-sh --version")
    assert_match "swift sh", shell_output("#{bin}/swift-sh --help")
    (testpath/"hello.swift").write "print(42)\n"
    assert_equal "42\n", shell_output("#{bin}/swift-sh #{testpath}/hello.swift")
  end
end
