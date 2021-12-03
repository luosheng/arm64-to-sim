import Foundation
import ArgumentParser

struct Arm64ToSim: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "A simple command-line tool for hacking native ARM64 binaries to run on the Apple Silicon iOS Simulator.",
        version: "1.0.0",
        subcommands: [Patch.self, Restore.self]
    )
    
}

extension Arm64ToSim {
    struct Patch: ParsableCommand {
        @Argument(help: "The path of the library to patch.")
        var path: String
        
        @Option()
        var minOS: UInt32 = 13
        
        @Option()
        var sdk: UInt32 = 13
        
        func run() throws {
            try Patcher.patch(atPath: path, minos: minOS, sdk: sdk)
        }
    }
    
    struct Restore: ParsableCommand {
        @Argument(help: "The path of the library to restore.")
        var path: String
    }
}

Arm64ToSim.main()
