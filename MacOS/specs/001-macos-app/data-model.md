# Data Model: macOS Native App

**Feature**: `001-macos-app`

## Core Entities

### 1. State Machine (`TantoEngine`)

The heart of the application.

```swift
enum inputMode {
    case insert      // Standard typing (Pass-through)
    case normal      // Vim navigation (Intercept & Remap)
    case visual      // Vim selection (Intercept & Remap + Shift)
    case operatorPending // Waiting for motion (e.g. after pressing 'd')
}

enum OperatorType {
    case delete  // 'd'
    case change  // 'c' (maps to Copy for now per spec, or Cut? Spec says c=Copy in one place, but vim c=change. Spec: "One-Shot actions (copy/cut/delete)... c (Copy)". Okay, following Spec: c=Copy.)
    case yank    // 'y' (Standard Vim copy? Spec uses c=Copy). 
    // SPEC CLARIFICATION: Spec says "c (Copy)". Vim uses 'y' for yank/copy and 'c' for change. 
    // I will follow the Spec: c = Copy.
    case cut     // 'x'
}

struct TantoState {
    var mode: InputMode = .insert
    var pendingOperator: OperatorType? = nil
}
```

### 2. Key Configuration

```swift
struct KeyCombo: Hashable {
    let keyCode: Int64
    let modifiers: CGEventFlags
}

enum Action {
    case move(direction: Direction, select: Bool)
    case enterMode(InputMode)
    case execute(OperatorType)
    case performPending(Motion) // e.g., 'h' (whole line)
    case typeout // 't'
    case escape // Reset to Normal or Insert
}
```

### 3. Events

- **Input**: `CGEvent` (Keyboard)
- **Output**: 
    - `CGEvent` (Synthesized keystrokes)
    - `StateChange` (Notification for UI)

## Data Flow

1. **InputManager**:
   - Captures `CGEvent`.
   - Checks `TantoEngine.shouldSuppress(event)`.
   - If true: return `nil`.
   - If false: return `event`.
   - Forwards valid keys to `TantoEngine.handle(key)`.

2. **TantoEngine**:
   - Updates `currentState`.
   - Triggers `Action` (e.g., `InputManager.post(Cmd+C)`).
   - Notifies `OverlayManager`.

3. **OverlayManager**:
   - Listens for `StateChange`.
   - Updates `NSWindow` content/cursor image.
