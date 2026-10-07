class SwiftAppstoreconnect < Formula
  desc "App Store Connect API clients and workflow commands"
  homepage "https://github.com/swift-library/swift-appstoreconnect"
  url "https://github.com/swift-library/swift-appstoreconnect/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "04633351838bb7ee761d2aa6e097a5ed00f0c376e9bdfb4718b160608f9f8983"
  license "Apache-2.0" => { with: "Swift-exception" }

  env :std

  depends_on xcode: ["26.0", :build]
  depends_on macos: :sequoia

  def install
    swift_version = Utils.safe_popen_read("swift", "--version")[/Swift version (\d+\.\d+(?:\.\d+)?)/, 1]
    if !swift_version || Version.new(swift_version) < Version.new("6.3.0")
      odie "Swift 6.3 or newer must be selected on PATH"
    end
    system "swift", "build", "--disable-sandbox", "-c", "release", "--force-resolved-versions",
           "--product", "appstoreconnect"
    build_path = Pathname.new(Utils.safe_popen_read("swift", "build", "-c", "release", "--show-bin-path").strip)
    bin.install build_path/"appstoreconnect"
    pkgshare.install "LICENSE.txt", "NOTICE"
    generate_completions_from_executable(bin/"appstoreconnect", "completion")
  end

  test do
    assert_equal "0.1.0\n", shell_output("#{bin}/appstoreconnect --version")
    assert_match "appstoreconnect commands list", shell_output("#{bin}/appstoreconnect --help")
    assert_match "publicReleaseReadiness", shell_output(
      "#{bin}/appstoreconnect workflow dry-run public-release-readiness --app-id example-app",
    )
    assert_match "complete -F _appstoreconnect_completions appstoreconnect",
                 (bash_completion/"appstoreconnect").read
    assert_match "#compdef appstoreconnect", (zsh_completion/"_appstoreconnect").read
    assert_match "complete -c appstoreconnect", (fish_completion/"appstoreconnect.fish").read
  end
end
