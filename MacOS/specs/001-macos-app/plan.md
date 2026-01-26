# Implementation Plan: macOS Native App

**Branch**: `001-macos-app` | **Date**: 2026-01-19 | **Spec**: [specs/001-macos-app/spec.md](../specs/001-macos-app/spec.md)
**Input**: Feature specification from `/specs/001-macos-app/spec.md`

## Summary

Build a native macOS menu bar application ("agent") that provides global Vim-like modal editing using `CGEventTap` for keyboard interception and a lightweight AppKit overlay for visual feedback. The core logic relies on a strict Finite State Machine to handle mode transitions and "One-Shot" editing operations.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: AppKit, CoreGraphics (CGEventTap), Accessibility (AXUIElement)
**Storage**: UserDefaults (for basic preferences)
**Testing**: XCTest
**Target Platform**: macOS 12.0+ (Monterey or later)
**Project Type**: Single Project (macOS App)
**Performance Goals**: < 20ms key-to-state latency, < 1% CPU idle
**Constraints**: LSUIElement=true (No Dock Icon), Non-Sandboxed (likely required for global event tap), No SwiftUI for core window management.
**Scale/Scope**: Single user, system-wide utility.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Language**: Swift 5+ (Latest Stable).
- [x] **UI Framework**: AppKit used (SwiftUI avoided for core).
- [x] **System Core**: `CGEventTap` and `AX` APIs planned.
- [x] **Architecture**: Event-driven State Machine planned.
- [x] **Safety**: Zero-crash policy acknowledged (safe unwrapping).
- [x] **Performance**: Lightweight callbacks, main thread non-blocking.
- [x] **Behavior**: LSUIElement defined.

## Project Structure

### Documentation (this feature)

```text
specs/001-macos-app/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
Tanto/MacOS
├── Sources/
│   ├── App/
│   │   └── AppDelegate.swift    # Entry point & Menu handling
│   ├── Core/
│   │   ├── TantoEngine.swift    # State Machine Logic
│   │   └── InputManager.swift   # CGEventTap Wrapper (C-style)
│   ├── UI/
│   │   └── OverlayManager.swift # NSWindow management for Cursor
│   └── Utils/
│       └── Permissions.swift    # Accessibility checks
├── Tests/
│   └── TantoTests/
│       └── StateMachineTests.swift
└── Package.swift                # SPM Definition
```

**Structure Decision**: Standard Swift Package Manager executable structure with logical separation of concerns (Core, UI, App).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Non-Sandboxed | Global `CGEventTap` requires broad system permissions usually restricted in Sandbox. | App Sandbox prevents global key interception required for core functionality. |