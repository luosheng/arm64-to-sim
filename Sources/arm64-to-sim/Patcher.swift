//
//  File.swift
//  
//
//  Created by Luo Sheng on 2021/12/3.
//

import Foundation
import ShellOut

struct Patcher {
    
    private static let ORIGINAL_EXTENSION = "original"
    private static let PATCH_EXTENSION = "patch"
    
    private static func getArchitectures(atPath path: String) throws -> [String] {
        let output = try shellOut(to: "file", arguments: [path])
        let pattern = #"for architecture (?<arch>\w*)"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsrange = NSRange(output.startIndex..<output.endIndex,
                              in: output)
        let matches = regex.matches(in: output, options: [], range: nsrange)
        return matches.map { match in
            guard let range = Range(match.range(withName: "arch"), in: output) else {
                return nil
            }
            return String(output[range])
        }.compactMap { $0 }
    }
    
    private static func extract(inputFileAtPath path: String, withArch arch: String, toURL: URL) throws {
        try shellOut(to: "lipo", arguments: [
            "-thin",
            arch,
            path,
            "-output",
            toURL.appendingPathComponent("lib.\(arch)").path
        ])
    }
    
    static func patch(atPath path: String, minos: UInt32, sdk: UInt32) throws {
        let url = URL(fileURLWithPath: path).standardized
        let extractionUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: extractionUrl, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.changeCurrentDirectoryPath(extractionUrl.path)
        try getArchitectures(atPath: url.path).forEach { arch in
            try extract(inputFileAtPath: url.path, withArch: arch, toURL: extractionUrl)
        }
        try shellOut(to: "ar", arguments: ["x", extractionUrl.appendingPathComponent("lib.arm64").path])
        if let emulator = FileManager.default.enumerator(atPath: extractionUrl.path) {
            for file in emulator {
                if let fileString = file as? String {
                    if fileString.hasSuffix(".o") {
                        Transmogrifier.processBinary(atPath: extractionUrl.appendingPathComponent(fileString).path, minos: minos, sdk: sdk)
                    }
                }
            }
        }
        try FileManager.default.removeItem(at: extractionUrl.appendingPathComponent("lib.arm64"))
        try shellOut(to: "ar", arguments: ["cr", "lib.arm64", "*.o"])
        try shellOut(to: "lipo", arguments: ["-create", "-output", url.lastPathComponent, "lib.*"])
        try FileManager.default.moveItem(at: url, to: url.appendingPathExtension(ORIGINAL_EXTENSION))
        let patchedUrl = url.appendingPathExtension(PATCH_EXTENSION)
        try FileManager.default.moveItem(at: extractionUrl.appendingPathComponent(url.lastPathComponent), to: patchedUrl)
        try link(url, withExtension: PATCH_EXTENSION)
    }
    
    private static func link(_ url: URL, withExtension ext: String) throws {
        let destinationUrl = url.appendingPathExtension(ext)
        guard try destinationUrl.checkResourceIsReachable() else {
            fatalError("Can not find file at \(destinationUrl)")
        }
        if (FileManager.default.fileExists(atPath: url.absoluteString)) {
            try FileManager.default.removeItem(at: url)
        }
        try FileManager.default.createSymbolicLink(at: url, withDestinationURL: destinationUrl)
    }
    
    static func restore(atPath path: String) throws {
        let url = URL(fileURLWithPath: path).standardized
        try link(url, withExtension: ORIGINAL_EXTENSION)
    }
}
