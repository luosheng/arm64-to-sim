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
    private static let PATCH_EXTENSION = "patched"
    
    private static func getArchitectures(atUrl url: URL) throws -> [String] {
        let output = try shellOut(to: "file", arguments: [url.path])
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
    
    private static func extract(inputFileAtUrl url: URL, withArch arch: String, toURL: URL) throws {
        try shellOut(to: "lipo", arguments: [
            "-thin",
            arch,
            url.path,
            "-output",
            "lib.\(arch)"
        ], at: toURL.path)
    }
    
    static func patch(atPath path: String, minos: UInt32, sdk: UInt32) throws {
        let url = URL(fileURLWithPath: path).absoluteURL
        let patchedUrl = url.appendingPathExtension(PATCH_EXTENSION)
        if FileManager.default.fileExists(atPath: patchedUrl.path) {
            try link(url, withDestinationUrl: patchedUrl)
            return
        }
        
        let extractionUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: extractionUrl, withIntermediateDirectories: true, attributes: nil)
        try getArchitectures(atUrl: url).forEach { arch in
            try extract(inputFileAtUrl: url, withArch: arch, toURL: extractionUrl)
        }
        FileManager.default.changeCurrentDirectoryPath(extractionUrl.path)
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
        try FileManager.default.moveItem(at: extractionUrl.appendingPathComponent(url.lastPathComponent), to: patchedUrl)
        try link(url, withDestinationUrl: patchedUrl)
    }
    
    private static func link(_ url: URL, withDestinationUrl destUrl: URL) throws {
        guard FileManager.default.fileExists(atPath: destUrl.path) else {
            fatalError("Can not find file at \(destUrl.path)")
        }
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try FileManager.default.createSymbolicLink(at: url, withDestinationURL: destUrl)
    }
    
    static func restore(atPath path: String) throws {
        let url = URL(fileURLWithPath: path).absoluteURL
        try link(url, withDestinationUrl: url.appendingPathExtension(ORIGINAL_EXTENSION))
    }
}
