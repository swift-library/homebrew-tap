// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu and the swift-library project authors

import Foundation
import SemVer

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

func api(_ path: String, repository: String) async throws -> Data {
  try await request(
    URL(string: "https://api.github.com/repos/" + repository + "/" + path)!, authenticated: true)
}

func releases(repository: String) async throws -> [Release] {
  var results: [Release] = []
  var page = 1
  while true {
    let batch = try JSONDecoder().decode(
      [Release].self, from: await api("releases?per_page=100&page=\(page)", repository: repository))
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

func commit(for tag: String, repository: String) async throws -> String {
  let encoded = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
  var object = try JSONDecoder().decode(
    GitReference.self, from: await api("git/ref/tags/" + encoded, repository: repository)
  ).object
  while object.type == "tag" {
    object = try JSONDecoder().decode(
      GitReference.self, from: await api("git/tags/" + object.sha, repository: repository)
    )
    .object
  }
  guard object.type == "commit" else { throw UpdateError.missingCommit }
  return object.sha
}

func verify(_ directory: URL) async throws {
  for record in try distributionRecords(in: directory) {
    let release = try JSONDecoder().decode(
      Release.self, from: await api("releases/\(record.releaseID)", repository: record.repository))
    guard release.version?.description == record.version, release.tagName == record.tag,
      try await commit(for: record.tag, repository: record.repository) == record.commit,
      checksum(try await request(URL(string: record.archiveURL)!)) == record.sha256,
      try String(
        contentsOf: directory.appendingPathComponent("Formula/\(record.formulaName).rb"),
        encoding: .utf8) == record.formula
    else { throw UpdateError.changedRelease }
  }
}

func prepare(_ directory: URL, repository: String) async throws {
  guard ReleaseRecord.supportedRepositories.contains(repository) else {
    throw UpdateError.invalidRecord
  }
  let name = String(repository.split(separator: "/").last!)
  let currentURL = URL(fileURLWithPath: "Metadata/\(name).json")
  let current =
    FileManager.default.fileExists(atPath: currentURL.path) ? try readRecord(currentURL) : nil
  guard current == nil || current?.repository == repository else { throw UpdateError.invalidRecord }
  guard
    let release = latestRelease(
      try await releases(repository: repository), after: current.flatMap { Version($0.version) })
  else {
    print("No newer published release.")
    try outputChanged(false)
    return
  }
  let tag = release.tagName
  let archiveURL = "https://github.com/\(repository)/archive/refs/tags/\(tag).tar.gz"
  let record = ReleaseRecord(
    repository: repository, releaseID: release.id, tag: tag, version: release.version!.description,
    commit: try await commit(for: tag, repository: repository), archiveURL: archiveURL,
    sha256: checksum(try await request(URL(string: archiveURL)!)))
  try record.validate()
  try FileManager.default.createDirectory(
    at: directory.appendingPathComponent("Formula"), withIntermediateDirectories: true)
  try FileManager.default.createDirectory(
    at: directory.appendingPathComponent("Metadata"), withIntermediateDirectories: true)
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  try encoder.encode(record).write(
    to: directory.appendingPathComponent("Metadata/\(name).json"), options: .atomic)
  try record.formula.write(
    to: directory.appendingPathComponent("Formula/\(name).rb"), atomically: true, encoding: .utf8)
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
  guard (1...3).contains(arguments.count), arguments.count < 3 || arguments[0] == "prepare" else {
    throw UpdateError.usage
  }
  let directory = URL(fileURLWithPath: arguments.count >= 2 ? arguments[1] : ".candidate")
  switch arguments[0] {
  case "prepare":
    try await prepare(
      directory, repository: arguments.count == 3 ? arguments[2] : "swift-library/swift-sh")
  case "verify": try await verify(directory)
  default: throw UpdateError.usage
  }
} catch {
  try FileHandle.standardError.write(
    contentsOf: Data("error: \(error.localizedDescription)\n".utf8))
  exit(1)
}
