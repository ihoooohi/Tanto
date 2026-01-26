<!--
Sync Impact Report:
- Version change: 0.0.0 -> 1.0.0 (Initial Ratification)
- Modified Principles: Populated all principles from user input.
- Added Sections: AI Interaction Rules.
- Templates Status: ✅ All templates compatible with new principles.
-->
# Tanto Constitution

## Core Principles

### I. Identity & Vision
**Type**: macOS Native Utility (Menu Bar App / Agent).
**Core Philosophy**: "One-shot" Vim-like modal editing for the global system.
**Target Audience**: Power users, developers, Vim enthusiasts.
**Critical Quality**: High performance, zero latency, native look & feel.

### II. Technology Stack (Non-Negotiable)
- **Language**: Swift 5+ (Latest Stable).
- **UI Framework**: AppKit (NSApplication, NSWindow, NSStatusItem).
  - ❌ **FORBIDDEN**: Do NOT use SwiftUI for core window management or event handling unless strictly necessary for complex settings UI. We need precise control over window levels and transparency.
- **System Core**:
  - `CoreGraphics` (`CGEventTap`) for global keyboard hooking.
  - `Accessibility API` (AX) for permission handling.
- **Build System**: Xcode Command Line Tools / Swift Package Manager (SPM).

### III. Architecture Principles
- **Event-Driven**: The core is an event loop processing `CGEvent`.
- **State Machine**: Logic MUST be implemented as a strict Finite State Machine (Enum: Insert, Normal, Visual, Pending).
- **Separation of Concerns**:
  - `InputManager`: Pure C-style wrapper for `CGEventTap`.
  - `TantoEngine`: Pure logic layer (Platform agnostic logic flow).
  - `OverlayManager`: View layer (NSWindow subclasses for crosshair/UI).
- **Zero-Crash Policy**: All `Optional` unwrapping must be handled safely (`guard let`, `if let`). No force unwrapping (`!`) in production code.

### IV. Coding Standards (C++ Developer Friendly)
- **Explicit Types**: Prefer explicit type declarations over obscure type inference for complex structures.
- **Memory Management**:
  - Be explicit about capture lists `[weak self]` in closures to avoid retain cycles (Memory Leaks).
  - Treat `CGEvent` and `Unmanaged<T>` objects with extreme care (Manual Retain/Release logic applies here).
- **Performance**:
  - Keyboard interception callbacks must be lightweight. Heavy logic must be dispatched to background queues.
  - No blocking the Main Thread (UI Thread).

### V. System Behavior Constraints
- **Dock Icon**: The app MUST have `LSUIElement = true` in `Info.plist` (No Dock Icon).
- **Permissions**: The app MUST gracefully check for "Trusted Accessibility" on launch and prompt the user if missing.
- **Sandboxing**: Disable App Sandbox if it interferes with Global Event Tapping (likely required for this type of tool).

## AI Interaction Rules

- **Explanation**: When generating Swift code, always explain "Why" in terms a C++ developer would understand (e.g., comparing ARC to `std::shared_ptr`).
- **Modularity**: Never generate one giant `main.swift`. Always suggest splitting into logical files (`InputManager.swift`, `StateManager.swift`).

## Governance

This constitution supersedes all other practices and documentation. Amendments require documentation, approval, and a clear migration plan for existing code. All Pull Requests and Code Reviews must explicitly verify compliance with these principles.

**Version**: 1.0.0 | **Ratified**: 2026-01-19 | **Last Amended**: 2026-01-19