import CoreGraphics
import Foundation
import Utils

func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout {
        Logger.log("Tap disabled by timeout. Re-enabling...")
        if let refcon = refcon {
             let manager = Unmanaged<InputManager>.fromOpaque(refcon).takeUnretainedValue()
             if let tap = manager.eventTap {
                 CGEvent.tapEnable(tap: tap, enable: true)
             }
        }
        return nil
    }
    
    return TantoEngine.shared.handle(event: event)
}

public class InputManager {
    public var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    public init() {}

    public func start() {
        Logger.log("InputManager: Attempting to start event tap...")
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        Logger.log("InputManager: Creating tap with mask \(eventMask)")
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventTapCallback,
            userInfo: selfPointer
        ) else {
            Logger.log("FATAL: Failed to create event tap. result == nil. This usually means Permissions are not actually active or Secure Input is enabled.")
            return
        }

        Logger.log("InputManager: Tap created successfully. Adding to RunLoop.")
        
        self.eventTap = eventTap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        self.runLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        Logger.log("InputManager: Tap Enabled Successfully. Listening for events...")
    }
}