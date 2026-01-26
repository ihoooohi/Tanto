# Research: macOS Native App

**Feature**: `001-macos-app`
**Date**: 2026-01-19

## key Technical Decisions

### 1. Accessibility Permissions (AX)
**Decision**: Use `AXIsProcessTrusted()` for checking and `AXIsProcessTrustedWithOptions()` to prompt.
**Rationale**: Standard macOS API.
**Implementation Detail**:
- Check on app launch.
- If false, show an alert explaining why, then call `AXIsProcessTrustedWithOptions` to open System Settings.
- Poll or wait for relaunch.

### 2. Global Keyboard Interception (`CGEventTap`)
**Decision**: Create a dedicated `InputManager` class wrapping `CGEvent.tapCreate`.
**Rationale**: `CGEventTap` is the only way to intercept keys globally (outside app focus).
**Safety Measures**:
- Use `Unmanaged<CGEvent>.fromOpaque()` and `takeUnretainedValue()` carefully.
- Handle `.tapDisabledByTimeout` events by re-enabling the tap (critical for stability).
- Run the run loop source on a dedicated background thread or main thread depending on performance (Main thread usually safer for UI sync, but `CGEventTap` can block it. Spec says "Heavy logic must be dispatched". The tap callback itself must be fast).
- **Callback Logic**: If State == Insert, return event (pass-through). If State == Normal/Visual, consume event (return nil) and inject replacement events if needed.

### 3. Visual Feedback (Cursor vs Overlay)
**Decision**: Use a transparent, click-through `NSWindow` (`styleMask: .borderless`) that floats above everything (`.floating` level) to draw custom crosshair/indicators.
**Rationale**: `NSCursor` API only affects the cursor when it is over the application's windows. To change it globally, we essentially need a screen-sized transparent window or to rely on standard system behavior (which doesn't allow global cursor override easily).
**Refinement**: A small floating window following the mouse cursor might be too laggy. A better approach for "Cursor" visual is to actually set the system cursor *if* we can, but likely we can't globally.
**Alternative**: Center-screen HUD (Bezel) or Menu Bar Icon change is most reliable.
**Selected Approach**:
1. Menu Bar Icon changes (Normal/Visual icons).
2. A small floating indicator window (HUD) near the active window or screen center.
3. *Research Note*: `CGSSetConnectionProperty` (private API) used to allow global cursor changes, but we should avoid private APIs.
4. **Final Decision**: We will implement a "Crosshair" by drawing a custom `NSWindow` centered on the screen or following the mouse (if performance allows). For MVP, a fixed position HUD or Menu Bar change is safer.
*Spec Adjustment*: "Display a custom cursor OR overlay". I will plan for an Overlay Window that can display the state icon.

### 4. Key Synthesis (One-Shot Actions)
**Decision**: Use `CGEvent(keyboardEventSource: ...)` to post events.
**Rationale**: Required to send `Cmd+C`, `Cmd+V`, `Arrows`.
**Flow**:
- User presses `c` (in Visual).
- App consumes `c`.
- App posts `Cmd` (down), `C` (down), `C` (up), `Cmd` (up).
- App switches state to Insert.

## Unresolved Questions (Resolved)
- **SwiftUI vs AppKit**: Constitution forbids SwiftUI. We use `NSWindow`, `NSView`.
- **Sandbox**: Must disable `App Sandbox` entitlement.

## Dependencies / Libraries
- None. Pure standard library.
