import Foundation
import ArgumentParser
import TSCBasic

struct Thin: ParsableCommand {
  @Argument
  var path: String

  mutating func run() throws {
    guard let cwd = localFileSystem.currentWorkingDirectory else {
      return
    }

    let inputPath = AbsolutePath(path, relativeTo: cwd)
    guard let enumerator = FileManager.default.enumerator(at: inputPath.asURL, includingPropertiesForKeys: nil) else {
      return
    }

    for case let fileURL as URL in enumerator {
      if fileURL.pathExtension == "" && fileURL.isFatBinary {
        print("Binary \(fileURL)")
        try fileURL.thin()
      }
    }
  }
}

extension URL {
  public var isFatBinary: Bool {
    guard let handle = FileHandle(forReadingAtPath: path) else { return false }
    let fatHeader = handle.readData(ofLength: MemoryLayout<fat_header>.size) as NSData
    if fatHeader.length < MemoryLayout<fat_header>.size {
      return false
    }
    let fatHeaderBound = fatHeader.bytes.assumingMemoryBound(to: fat_header.self)
    return fatHeaderBound.pointee.magic == FAT_MAGIC || fatHeaderBound.pointee.magic == FAT_CIGAM
  }

  func thin() throws {
    let tempFile = deletingLastPathComponent().appendingPathComponent(lastPathComponent.appending("Temp"))
    try FileManager.default.copyItem(at: self, to: tempFile)
    let process = Process()
    process.launchPath = "/usr/bin/xcrun"
    // TODO: WatchOS binaries would be a different architecture
    process.arguments = ["lipo", "-thin", "arm64", path, "-output", tempFile.path]
    try process.run()
    process.waitUntilExit()
    try FileManager.default.removeItem(at: self)
    try FileManager.default.moveItem(at: tempFile, to: self)
  }
}


Thin.main()

