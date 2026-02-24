---
description: "Task list for macOS Native App implementation"
---

# Tasks: macOS Native App

**Input**: Design documents from `/specs/001-macos-app/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md
**Organization**: Tasks are grouped by user story to enable independent implementation.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize Swift Package and core folders.

- [x] T001 Create project directories (Sources/App, Sources/Core, Sources/UI, Sources/Utils) per plan
- [x] T002 Initialize Swift Package (`swift package init --type executable`) in root
- [x] T003 Update Package.swift with target definitions (App, Core, UI, Utils)
- [x] T004 Create Main Entry Point (`main.swift` or `@main` struct) in Sources/App/AppDelegate.swift

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core Accessibility and Event Tap infrastructure.

- [x] T005 Implement `Permissions.swift` with `AXIsProcessTrusted` checks in Sources/Utils/Permissions.swift
- [x] T006 Implement `InputManager` class skeleton with `CGEvent.tapCreate` in Sources/Core/InputManager.swift
- [x] T007 Define `TantoEngine` State Machine Enums (InputMode, OperatorType) in Sources/Core/TantoEngine.swift
- [x] T008 Implement basic `OverlayManager` window setup (invisible for now) in Sources/UI/OverlayManager.swift

**Checkpoint**: App runs, requests permissions, and prints "Tap Enabled" to console.

## Phase 3: User Story 1 - Modal Activation & Navigation (Priority: P1) 🎯 MVP

**Goal**: Toggle modes via CapsLock and navigate with IJKL.

**Independent Test**:
1. Run App.
2. Press CapsLock → Verify State=Visual.
3. Press IJKL → Verify Shift+Arrow events emitted.
4. Press v → Verify State=Normal.

### Implementation

- [x] T009 [US1] Implement `TantoEngine` state transition logic (Insert <-> Visual via CapsLock) in Sources/Core/TantoEngine.swift
- [x] T010 [US1] Update `InputManager` to forward keys to `TantoEngine` in Sources/Core/InputManager.swift
- [x] T011 [US1] Implement Key Mapping logic (IJKL -> Arrows) in Sources/Core/TantoEngine.swift
- [x] T012 [US1] Implement Event Synthesis (posting modified events) in Sources/Core/InputManager.swift
- [x] T013 [US1] Implement Visual Mode Specifics (Shift modifier injection) in Sources/Core/TantoEngine.swift
- [x] T014 [US1] Add `Command+I/K/J/L` jumping logic in Sources/Core/TantoEngine.swift
- [x] T015 [US1] Update `OverlayManager` to show basic Menu Bar status (Visual/Normal) in Sources/UI/OverlayManager.swift

**Checkpoint**: Fully functional navigation system.

## Phase 4: User Story 2 - One-Shot Editing (Priority: P2)

**Goal**: Copy/Delete/Cut returns to Insert mode immediately.

**Independent Test**:
1. Enter Visual. Select text. Press 'c'. Verify Cmd+C sent + Return to Insert.
2. Enter Normal. Press 'd'. Verify Operator Pending. Press 'h'. Verify Cmd+Backspace sent + Return to Insert.

### Implementation

- [x] T016 [US2] Add `OperatorType` handling to `TantoEngine` in Sources/Core/TantoEngine.swift
- [x] T017 [US2] Implement `c` (Copy) action handler (Send Cmd+C -> Switch to Insert) in Sources/Core/TantoEngine.swift
- [x] T018 [US2] Implement `d` (Delete) pending state logic in Sources/Core/TantoEngine.swift
- [x] T019 [US2] Implement `Operator Pending` modifiers (h=Line, w=Word, b=Back) in Sources/Core/TantoEngine.swift
- [x] T020 [US2] Wire up `d` + motion -> Execute Delete logic in Sources/Core/TantoEngine.swift

**Checkpoint**: Editing operations work as "One-Shot".

## Phase 5: User Story 3 - Typeout Simulation (Priority: P3)

**Goal**: Type clipboard content as keystrokes.

**Independent Test**:
1. Copy text. Press 't' in Normal. Verify typing.
2. Press Esc during typing. Verify abort.

### Implementation

- [x] T021 [US3] Implement `Typeout` state/action in Sources/Core/TantoEngine.swift
- [x] T022 [US3] Create `TypeoutManager` (or helper) to read Clipboard and fire events loop in Sources/Core/InputManager.swift
- [x] T023 [US3] Add Escape interrupt logic to stop typing loop in Sources/Core/InputManager.swift

**Checkpoint**: Typeout feature functional.

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T024 [P] Hide Dock Icon (`LSUIElement` in Info.plist)
- [x] T025 [P] Improve Overlay (Floating HUD window instead of just Menu Bar) in Sources/UI/OverlayManager.swift
- [x] T026 Code Cleanup: Ensure no force unwraps
- [x] T027 Update README with usage instructions

## Dependencies & Execution Order

- **Setup & Foundational**: Blocks everything.
- **US1 (Navigation)**: Blocks US2 and US3 (needs State Machine working).
- **US2 (One-Shot)**: Depends on US1.
- **US3 (Typeout)**: Independent of US2, depends on US1 (needs Normal mode).

## Implementation Strategy

1. **MVP**: Complete Phase 1-3. We have a working navigator.
2. **Beta**: Add Phase 4 (One-Shot). We have a useful editor.
3. **Final**: Add Phase 5 & 6.