import ApplicationServices
import Cocoa

public struct Permissions {
    public static func isTrusted() -> Bool {
        return AXIsProcessTrusted()
    }

    public static func prompt() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    public static func openSystemSettings() {
        // Attempt to open the specific Accessibility pane
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
