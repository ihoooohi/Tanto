import Foundation
import IOKit
import IOKit.hid

public class KeyboardLED {
    public static func setCapsLock(enabled: Bool) {
        let hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        
        let deviceDict = [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard
        ] as CFDictionary
        
        IOHIDManagerSetDeviceMatching(hidManager, deviceDict)
        IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        let devices = IOHIDManagerCopyDevices(hidManager)
        guard let deviceSet = devices else { return }
        
        let count = CFSetGetCount(deviceSet)
        let devicesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: count)
        CFSetGetValues(deviceSet, devicesPointer)
        
        for i in 0..<count {
            if let device = devicesPointer[i] {
                let ioDevice = Unmanaged<IOHIDDevice>.fromOpaque(device).takeUnretainedValue()
                setLED(device: ioDevice, page: kHIDPage_LEDs, usage: kHIDUsage_LED_CapsLock, on: enabled)
            }
        }
        devicesPointer.deallocate()
    }
    
    private static func setLED(device: IOHIDDevice, page: Int, usage: Int, on: Bool) {
        let elementDict = [
            kIOHIDElementUsagePageKey: page,
            kIOHIDElementUsageKey: usage
        ] as CFDictionary
        
        let elements = IOHIDDeviceCopyMatchingElements(device, elementDict, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let elementArray = elements else { return }
        
        let count = CFArrayGetCount(elementArray)
        if count > 0 {
            for i in 0..<count {
                if let elementRef = CFArrayGetValueAtIndex(elementArray, i) {
                    let element = Unmanaged<IOHIDElement>.fromOpaque(elementRef).takeUnretainedValue()
                    let timestamp: UInt64 = 0
                    let value = IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault, element, timestamp, on ? 1 : 0)
                    IOHIDDeviceSetValue(device, element, value)
                }
            }
        }
    }
}
