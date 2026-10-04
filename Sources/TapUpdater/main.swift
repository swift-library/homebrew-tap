// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu and the swift-library project authors

import Foundation
import SemVer

let repository = "swift-library/swift-sh"

func request(_ url: URL, authenticated: Bool = false) async throws -> Data {
  var request = URLRequest(url: url)
  request.timeoutInterval = 120
  if authenticated {
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    if let token = ProcessInfo.processInfo.environment["GH_TOKEN"] {
      request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
    }
  }
  let (data, response) = try await URLSession.shared.data(for: request)
  guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
    throw UpdateError.failedRequest(
      (response as? HTTPURLResponse)?.statusCode ?? 0, url.absoluteString)
  }
  return data
}

func api(_ path: String) async throws -> Data {
  try await request(
    URL(string: "https://api.github.com/repos/" + repository + "/" + path)!, authenticated: true)
}

func releases() async throws -> [Release] {
  var results: [Release] = []
  var page = 1
  while true {
    let batch = try JSONDecoder().decode(
      [Release].self, from: await api("releases?per_page=100&page=\(page)"))
    results += batch
    if batch.count < 100 { return results }
    page += 1
  }
}

private struct GitObject: Decodable {
  let sha: String
  let type: String
}

private struct GitReference: Decodable {
  let object: GitObject
}

func commit(for tag: String) async throws -> String {
  let encoded = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
  var object = try JSONDecoder().decode(
    GitReference.self, from: await api("git/ref/tags/" + encoded)
  ).object
  while object.type == "tag" {
    object = try JSONDecoder().decode(GitReference.self, from: await api("git/tags/" + object.sha))
      .object
  }
  guard object.type == "commit" else { throw UpdateError.missingCommit }
  return object.sha
}

func readRecord(_ url: URL) throws -> ReleaseRecord {
  let record = try JSONDecoder().decode(ReleaseRecord.self, from: Data(contentsOf: url))
  try record.validate()
  return record
}

func verify(_ directory: URL) async throws {
  let record = try readRecord(directory.appendingPathComponent("Metadata/swift-sh.json"))
  let release = try JSONDecoder().decode(
    Release.self, from: await api("releases/\(record.releaseID)"))
  guard release.version?.description == record.version, release.tagName == record.tag,
    try await commit(for: record.tag) == record.commit,
    checksum(try await request(URL(string: record.archiveURL)!)) == record.sha256,
    try String(contentsOf: directory.appendingPathComponent("Formula/swift-sh.rb"), encoding: .utf8)
      == record.formula
  else { throw UpdateError.changedRelease }
}

func prepare(_ directory: URL) async throws {
  let currentURL = URL(fileURLWithPath: "Metadata/swift-sh.json")
  let current =
    FileManager.default.fileExists(atPath: currentURL.path) ? try readRecord(currentURL) : nil
  guard
    let release = latestRelease(
      try await releases(), after: current.flatMap { Version($0.version) })
  else {
    print("No newer published release.")
    try outputChanged(false)
    return
  }
  let tag = release.tagName
  let archiveURL = "https://github.com/\(repository)/archive/refs/tags/\(tag).tar.gz"
  let record = ReleaseRecord(
    repository: repository, releaseID: release.id, tag: tag, version: release.version!.description,
    commit: try await commit(for: tag), archiveURL: archiveURL,
    sha256: checksum(try await request(URL(string: archiveURL)!)))
  try record.validate()
  try FileManager.default.createDirectory(
    at: directory.appendingPathComponent("Formula"), withIntermediateDirectories: true)
  try FileManager.default.createDirectory(
    at: directory.appendingPathComponent("Metadata"), withIntermediateDirectories: true)
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  try encoder.encode(record).write(
    to: directory.appendingPathComponent("Metadata/swift-sh.json"), options: .atomic)
  try record.formula.write(
    to: directory.appendingPathComponent("Formula/swift-sh.rb"), atomically: true, encoding: .utf8)
  try outputChanged(true)
  print("Staged \(tag) at \(record.commit).")
}

func outputChanged(_ changed: Bool) throws {
  guard let path = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] else { return }
  let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
  defer { try? handle.close() }
  try handle.seekToEnd()
  try handle.write(contentsOf: Data("changed=\(changed)\n".utf8))
}

do {
  let arguments = Array(CommandLine.arguments.dropFirst())
  guard (1...2).contains(arguments.count) else { throw UpdateError.usage }
  let directory = URL(fileURLWithPath: arguments.count == 2 ? arguments[1] : ".candidate")
  switch arguments[0] {
  case "prepare": try await prepare(directory)
  case "verify": try await verify(directory)
  default: throw UpdateError.usage
  }
} catch {
  try FileHandle.standardError.write(
    contentsOf: Data("error: \(error.localizedDescription)\n".utf8))
  exit(1)
}
