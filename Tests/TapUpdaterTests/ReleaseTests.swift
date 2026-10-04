// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu and the swift-library project authors

import Foundation
import SemVer
import Testing

@testable import TapUpdater

struct ReleaseTests {
  @Test func formalReleaseSelection() throws {
    let releases = try JSONDecoder().decode(
      [Release].self,
      from: Data(
        """
        [
          {"id": 1, "tag_name": "v0.1.0", "draft": false, "prerelease": false},
          {"id": 2, "tag_name": "v0.2.0-alpha", "draft": false, "prerelease": false},
          {"id": 3, "tag_name": "v0.2.0", "draft": true, "prerelease": false},
          {"id": 4, "tag_name": "v0.1.2", "draft": false, "prerelease": true},
          {"id": 5, "tag_name": "v0.1.1", "draft": false, "prerelease": false},
          {"id": 6, "tag_name": "v01.3.0", "draft": false, "prerelease": false}
        ]
        """.utf8))
    #expect(latestRelease(releases, after: Version(0, 1, 0))?.id == 5)
    #expect(latestRelease(releases, after: Version(0, 1, 1)) == nil)
    #expect(latestRelease(releases, after: Version(0, 2, 0)) == nil)
    #expect(latestRelease(releases, after: nil)?.id == 5)
  }

  @Test func recordRoundTripAndIdentityValidation() throws {
    let record = ReleaseRecord(
      repository: "swift-library/swift-sh", releaseID: 1,
      tag: "v0.1.0", version: "0.1.0", commit: String(repeating: "a", count: 40),
      archiveURL: "https://github.com/swift-library/swift-sh/archive/refs/tags/v0.1.0.tar.gz",
      sha256: String(repeating: "b", count: 64))
    try record.validate()
    #expect(
      try JSONDecoder().decode(ReleaseRecord.self, from: JSONEncoder().encode(record)) == record)
    #expect(record.formula.contains("--force-resolved-versions"))
    let invalid = ReleaseRecord(
      repository: record.repository, releaseID: record.releaseID,
      tag: "v0.1.1", version: record.version, commit: record.commit,
      archiveURL: record.archiveURL, sha256: record.sha256)
    #expect(throws: UpdateError.self) { try invalid.validate() }
  }

  @Test func archiveChecksum() {
    #expect(
      checksum(Data("abc".utf8))
        == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
  }
}
