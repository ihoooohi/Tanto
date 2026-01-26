import Cocoa
import Core
import UI
import Utils

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    var inputManager: InputManager?
    var welcomeWindowController: WelcomeWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Simple Debug Logging
        let logStr = "Tanto Agent Started at \(Date())\n"
        if let data = logStr.data(using: .utf8) {
            let logURL = URL(fileURLWithPath: "/tmp/tanto_debug.log")
            if FileManager.default.fileExists(atPath: logURL.path) {
                if let handle = try? FileHandle(forWritingTo: logURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logURL)
            }
        }
        
        // Setup UI First
        welcomeWindowController = WelcomeWindowController()
        welcomeWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Setup Status Bar Action
        OverlayManager.shared.onOpenSettings = { [weak self] in
            self?.welcomeWindowController?.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        
        if !Permissions.isTrusted() {
            // Log missing permissions
            try? "Permissions missing.\n".data(using: .utf8)?.append(to: URL(fileURLWithPath: "/tmp/tanto_debug.log"))
            
            // Just prompt system, let the Window handle the UI explanation.
            // Removing the blocking Alert to ensure Window is visible.
            Permissions.prompt()
        } else {
             try? "Permissions Trusted.\n".data(using: .utf8)?.append(to: URL(fileURLWithPath: "/tmp/tanto_debug.log"))
        }

        // Ensure Singletons are alive
        _ = TantoEngine.shared
        _ = OverlayManager.shared
        
        // Init InputManager
        inputManager = InputManager()
        inputManager?.start()
        
        // Heartbeat for debugging
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            try? "Heartbeat: App is alive at \(Date())\n".data(using: .utf8)?.append(to: URL(fileURLWithPath: "/tmp/tanto_debug.log"))
        }
    }
}

extension Data {
    func append(to url: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: url) {
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: url, options: .atomic)
        }
    }
}
