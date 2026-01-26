import Foundation
import CoreGraphics
import Cocoa

public class TypeoutManager {
    public static let shared = TypeoutManager()
    private var isTyping = false
    
    public func startTyping() {
        guard let text = NSPasteboard.general.string(forType: .string) else { return }
        
        DispatchQueue.main.async {
            TantoEngine.shared.mode = .typeout
        }
        
        isTyping = true
        
        DispatchQueue.global(qos: .userInteractive).async {
            for char in text {
                if !self.isTyping { break }
                self.typeChar(char)
                usleep(10000) // 10ms
            }
            self.isTyping = false
            DispatchQueue.main.async {
                 TantoEngine.shared.mode = .insert
            }
        }
    }
    
    public func stopTyping() {
        isTyping = false
    }
    
    private func typeChar(_ char: Character) {
        let source = CGEventSource(stateID: .hidSystemState)
        let evDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
        let evUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        
        var uni = Array(String(char).utf16)
        evDown?.keyboardSetUnicodeString(stringLength: uni.count, unicodeString: &uni)
        evUp?.keyboardSetUnicodeString(stringLength: uni.count, unicodeString: &uni)
        
        evDown?.setIntegerValueField(.eventSourceUserData, value: 0x555)
        evUp?.setIntegerValueField(.eventSourceUserData, value: 0x555)
        
        evDown?.post(tap: .cghidEventTap)
        evUp?.post(tap: .cghidEventTap)
    }
}
