// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu and the swift-library project authors

extension ReleaseRecord {
  var appStoreConnectFormula: String {
    """
    class SwiftAppstoreconnect < Formula
      desc "App Store Connect API clients and workflow commands"
      homepage "https://github.com/swift-library/swift-appstoreconnect"
      url "\(archiveURL)"
      sha256 "\(sha256)"
      license "Apache-2.0" => { with: "Swift-exception" }

      env :std

      depends_on xcode: ["26.0", :build]
      depends_on macos: :sequoia

      def install
        swift_version = Utils.safe_popen_read("swift", "--version")[/Swift version (\\d+\\.\\d+(?:\\.\\d+)?)/, 1]
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
        assert_equal "\(version)\\n", shell_output("#{bin}/appstoreconnect --version")
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

    """
  }
}
