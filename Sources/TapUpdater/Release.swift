// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu and the swift-library project authors

import CryptoKit
import Foundation
import SemVer

struct Release: Decodable {
  let id: Int
  let tagName: String
  let draft: Bool
  let prerelease: Bool

  enum CodingKeys: String, CodingKey {
    case id, draft, prerelease
    case tagName = "tag_name"
  }

  var version: Version? {
    guard !draft, !prerelease, tagName.hasPrefix("v"),
      let version = Version(String(tagName.dropFirst())), !version.isPrerelease
    else { return nil }
    return version
  }
}

func latestRelease(_ releases: [Release], after current: Version?) -> Release? {
  releases.filter { release in
    guard let version = release.version else { return false }
    return current.map { version > $0 } ?? true
  }.max { $0.version! < $1.version! }
}

struct ReleaseRecord: Codable, Equatable {
  let repository: String
  let releaseID: Int
  let tag: String
  let version: String
  let commit: String
  let archiveURL: String
  let sha256: String

  func validate() throws {
    guard repository == "swift-library/swift-sh", tag == "v" + version,
      let parsed = Version(version), !parsed.isPrerelease, releaseID > 0,
      commit.count == 40, commit.allSatisfy({ $0.isHexDigit && !$0.isUppercase }),
      sha256.count == 64, sha256.allSatisfy({ $0.isHexDigit && !$0.isUppercase }),
      archiveURL == "https://github.com/\(repository)/archive/refs/tags/\(tag).tar.gz"
    else { throw UpdateError.invalidRecord }
  }

  var formula: String {
    """
    class SwiftSh < Formula
      desc "Run single-file Swift scripts with SwiftPM dependencies"
      homepage "https://github.com/swift-library/swift-sh"
      url "\(archiveURL)"
      sha256 "\(sha256)"
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
        swift_version = Utils.safe_popen_read("swift", "--version")[/Swift version (\\d+\\.\\d+(?:\\.\\d+)?)/, 1]
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
        assert_equal "\(version)\\n", shell_output("#{bin}/swift-sh --version")
        assert_match "swift sh", shell_output("#{bin}/swift-sh --help")
        (testpath/"hello.swift").write "print(42)\\n"
        assert_equal "42\\n", shell_output("#{bin}/swift-sh #{testpath}/hello.swift")
      end
    end

    """
  }
}

func checksum(_ data: Data) -> String {
  SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

enum UpdateError: LocalizedError {
  case invalidRecord
  case failedRequest(Int, String)
  case missingCommit
  case changedRelease
  case usage

  var errorDescription: String? {
    switch self {
    case .invalidRecord: return "Invalid release identity."
    case .failedRequest(let status, let url): return "HTTP \(status): \(url)"
    case .missingCommit: return "The published tag does not resolve to a commit."
    case .changedRelease: return "The release identity or formula changed after staging."
    case .usage: return "Usage: tap-updater prepare|verify [candidate-directory]"
    }
  }
}
