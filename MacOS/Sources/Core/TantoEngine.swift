import Foundation
import CoreGraphics
import Utils
import IOKit

public enum InputMode {
    case insert
    case normal
    case visual
    case operatorPending
    case typeout
}

public enum OperatorType {
    case delete
    case copy
    case cut
}

enum MotionType {
    case line
    case wordRight
    case wordLeft
}

public class TantoEngine {
    public static let shared = TantoEngine()
    
    // We derive mode from system CapsLock state, but we also track it locally for combos
    public var mode: InputMode = .insert {
        didSet {
            if oldValue != mode {
                Logger.log("Mode changed to: \(mode)")
                NotificationCenter.default.post(name: Notification.Name("TantoModeChanged"), object: nil, userInfo: ["mode": mode])
            }
        }
    }
    
    public var pendingOperator: OperatorType?
    
    // Dual-Role State
    private var isCapsLockHeld = false
    private var hasUsedCapsLockCombo = false
    
    // Explicit "Real" CapsLock Mode (Ctrl+Caps enabled this)
    private var explicitAlphaLock = false

    public init() {}
    
    // Helper to toggle system CapsLock (send a key press)
    private func toggleSystemCapsLock() {
        let source = CGEventSource(stateID: .hidSystemState)
        let evDown = CGEvent(keyboardEventSource: source, virtualKey: 57, keyDown: true)
        let evUp = CGEvent(keyboardEventSource: source, virtualKey: 57, keyDown: false)
        // Tag it so we ignore our own generated event
        evDown?.setIntegerValueField(.eventSourceUserData, value: 0x555)
        evUp?.setIntegerValueField(.eventSourceUserData, value: 0x555)
        evDown?.post(tap: .cghidEventTap)
        evUp?.post(tap: .cghidEventTap)
    }
    
    public func handle(event: CGEvent) -> Unmanaged<CGEvent>? {
        // Recursion guard
        if event.getIntegerValueField(.eventSourceUserData) == 0x555 {
            return Unmanaged.passUnretained(event)
        }
        
        let type = event.type
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // --- 1. CapsLock Handling (The Trigger) ---
        if keyCode == 57 && type == .flagsChanged {
            // Check for Ctrl + CapsLock -> Toggle EXPLICIT Alpha Lock
            if flags.contains(.maskControl) {
                explicitAlphaLock = !explicitAlphaLock
                Logger.log("Ctrl+Caps: Explicit Alpha Lock set to \(explicitAlphaLock)")
                // We pass this through so system handles the light/state naturally
                return Unmanaged.passUnretained(event)
            }
            
            // Standard CapsLock Press/Release
            // We distinguish Press vs Release by checking if the AlphaShift flag *changed* state?
            // Actually, hardware CapsLock behaves as a toggle switch on the flag level usually?
            // Wait, for standard keyboards, pressing CapsLock toggles the flag immediately.
            // Pressing it again toggles it back.
            // But we need to know "Held" vs "released".
            // Reliable way: Check event value? No, flagsChanged is special.
            
            // Let's assume:
            // If explicitAlphaLock is ON, we do NOTHING (act like standard keyboard).
            if explicitAlphaLock {
                return Unmanaged.passUnretained(event)
            }
            
            // Tant Logic:
            // We use `isCapsLockHeld` to track physical press duration.
            // But flagsChanged is tricky.
            // Let's toggle our internal 'held' state.
            isCapsLockHeld = !isCapsLockHeld
            
            if isCapsLockHeld {
                // Key DOWN
                hasUsedCapsLockCombo = false
                // We allow the event to pass -> System turns ON AlphaLock -> Visual Mode ON
                Logger.log("Caps Down -> Visual Mode Enabled (System LED ON)")
                mode = .visual
            } else {
                // Key UP
                Logger.log("Caps Up")
                if hasUsedCapsLockCombo {
                    // We used it as a modifier.
                    // The System State is currently ON (Visual).
                    // We need to turn it OFF to return to Insert.
                    Logger.log("Combo Used -> Auto-Disabling System CapsLock")
                    toggleSystemCapsLock()
                    mode = .insert
                } else {
                    // Just a Tap. 
                    // Do nothing. Trust the state established on KeyDown.
                    // The System AlphaShift state latches on KeyDown (usually).
                }
            }
            
            // Always pass through CapsLock (unless we want to hide it, but we promised "顺势而为")
            return Unmanaged.passUnretained(event)
        }
        
        // Sync mode if we missed a transition (e.g. startup)
        // But only if not holding CapsLock (to avoid flickering during combo)
        if !isCapsLockHeld && !explicitAlphaLock {
             let isSystemAlphaOn = flags.contains(.maskAlphaShift)
             if isSystemAlphaOn && mode != .visual { mode = .visual }
             if !isSystemAlphaOn && mode != .insert { mode = .insert }
        }
        
        // --- 2. Combo / Visual Mode Logic ---
        
        // If Explicit Alpha Lock is ON, bypass everything (Type normally in Uppercase)
        if explicitAlphaLock {
            return Unmanaged.passUnretained(event)
        }
        
        // If NOT in Visual Mode, Pass Through (Insert)
        // (Unless we are holding CapsLock, in which case we might be IN Visual effectively)
        if mode == .insert && !isCapsLockHeld {
            return Unmanaged.passUnretained(event)
        }
        
        // We are in Visual Mode OR Holding CapsLock.
        
        let isDown = (type == .keyDown)
        // Swallow KeyUp if we swallowed KeyDown? Usually yes.
        // We'll filter by keyCode.
        
        // IJKL Mapping
        let map: [Int64: Int64] = [
            34: 126, // i -> Up
            38: 123, // j -> Left
            40: 125, // k -> Down
            37: 124  // l -> Right
        ]
        
        if let arrowCode = map[keyCode] {
            if isDown {
                hasUsedCapsLockCombo = true // Mark combo used
                
                // Post Arrow
                let source = CGEventSource(stateID: .combinedSessionState)
                let newEv = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(arrowCode), keyDown: true)
                
                // Visual Mode = Shift + Arrow (Select)
                // Combo Mode (Held but not Visual?) = Just Arrow?
                // Actually, if held, we assume Visual behavior (Select)?
                // User said: "Caps + L = Move". Not Select.
                // But Visual Mode usually implies Select?
                // Let's stick to spec: 
                // Visual Mode (Tapped) -> Shift + Arrow.
                // Combo (Held) -> Just Arrow (Move).
                
                var newFlags = flags
                // Remove AlphaShift from arrow event to be safe
                newFlags.remove(.maskAlphaShift)
                
                if !isCapsLockHeld {
                    // Tapped State (Pure Visual) -> Add Shift
                    newFlags.insert(.maskShift)
                } else {
                    // Held State (Combo) -> No Shift (unless physically pressed)
                }
                
                newEv?.flags = newFlags
                newEv?.setIntegerValueField(.eventSourceUserData, value: 0x555)
                newEv?.post(tap: .cghidEventTap)
                
                let newEvUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(arrowCode), keyDown: false)
                newEvUp?.flags = newFlags
                newEvUp?.setIntegerValueField(.eventSourceUserData, value: 0x555)
                newEvUp?.post(tap: .cghidEventTap)
            }
            return nil
        }
        
        // One-Shot Actions (c/d/x) - Only if isDown
        if isDown {
            if keyCode == 8 { // c -> Copy
                hasUsedCapsLockCombo = true
                performOneShot(keyCode: 8, flags: flags)
                return nil
            }
            if keyCode == 7 { // x -> Cut
                hasUsedCapsLockCombo = true
                performOneShot(keyCode: 7, flags: flags)
                return nil
            }
            if keyCode == 2 { // d -> Delete/Cut (Mapped to Cmd+X or Backspace?)
                // Spec said d=Delete. 
                hasUsedCapsLockCombo = true
                // Let's map d to Backspace for simple deletion, or Cmd+X?
                // Spec: "One-Shot actions... d (Delete)... return to Insert".
                // Vim 'd' is cut.
                performOneShot(keyCode: 51, flags: flags, isSpecial: true) // 51 is Backspace
                return nil
            }
        }
        
        // Swallow other keys if in Visual Mode (Locked) to prevent typing "JJJJ"
        // But if holding CapsLock (Combo), maybe pass through others?
        // Safest: Swallow everything if mode == .visual.
        // If mode == .insert (but holding Caps), maybe pass?
        if mode == .visual {
             return nil 
        }
        
        // If holding caps but mode is insert (first press state before release?),
        // actually system sets AlphaShift immediately on press.
        // So we are likely in .visual if holding.
        
            // Other keys + CapsLock -> Mark used
            // Strict check: Only mark used if it's a KeyDown event.
            // Ignore KeyUp (unlikely to trigger without down) and FlagsChanged (modifiers).
            if type == .keyDown && keyCode != 57 {
                if !hasUsedCapsLockCombo {
                    Logger.log("Marking Combo Used due to KeyCode: \(keyCode)")
                }
                hasUsedCapsLockCombo = true
            }
            return Unmanaged.passUnretained(event)
        }
    
    private func performOneShot(keyCode: Int64, flags: CGEventFlags, isSpecial: Bool = false) {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        var targetCode = keyCode
        var targetFlags: CGEventFlags = .maskCommand
        
        if isSpecial && keyCode == 51 { // Delete -> Backspace (No Cmd)
            targetFlags = []
        }
        
        // Post Command
        let ev = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(targetCode), keyDown: true)
        ev?.flags = targetFlags
        ev?.setIntegerValueField(.eventSourceUserData, value: 0x555)
        ev?.post(tap: .cghidEventTap)
        
        let evUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(targetCode), keyDown: false)
        evUp?.flags = targetFlags
        evUp?.setIntegerValueField(.eventSourceUserData, value: 0x555)
        evUp?.post(tap: .cghidEventTap)
        
        // Auto-Exit Visual Mode (One-Shot)
        // If we are holding caps, the release will trigger toggle off.
        // If we are tapped (Visual Locked), we need to toggle off NOW.
        
        if isCapsLockHeld {
            // We are holding. Do nothing?
            // If I hold Caps, press C, I expect copy.
            // Then I release Caps. The release logic sees `hasUsed` and toggles off.
            // Correct.
        } else {
            // We are locked. We need to turn off.
            Logger.log("One-Shot Executed -> Disabling System CapsLock")
            toggleSystemCapsLock()
            mode = .insert
        }
    }
}