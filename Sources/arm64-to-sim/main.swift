import Foundation

guard CommandLine.arguments.count > 1 else {
    fatalError("Please add a path to command!")
}
let binaryPath = CommandLine.arguments[1]
var minos: UInt32 = 13
var sdk: UInt32 = 13
if let minosStr = ProcessInfo.processInfo.environment["ARM64_TO_SIM_MINOS"],
    let number = UInt32(minosStr) {
    minos = number
}
if let sdkStr = ProcessInfo.processInfo.environment["ARM64_TO_SIM_SDK"],
   let number = UInt32(sdkStr) {
    sdk = number
}
if CommandLine.arguments.count > 3 {
    if let number = UInt32(CommandLine.arguments[2]) {
        minos = number
    }
    if let number = UInt32(CommandLine.arguments[3]) {
        sdk = number
    }
}
try Patcher.patch(atPath: binaryPath, minos: minos, sdk: sdk)
