import Foundation

public struct Logger {
    public static func log(_ msg: String) {
        let str = "\(Date()): \(msg)\n"
        guard let data = str.data(using: .utf8) else { return }
        let url = URL(fileURLWithPath: "/tmp/tanto_debug.log")
        
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        } else {
            try? data.write(to: url)
        }
    }
}

