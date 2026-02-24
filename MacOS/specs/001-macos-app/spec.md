# Feature Specification: macOS Native App

**Feature Branch**: `001-macos-app`
**Created**: 2026-01-19
**Status**: Draft
**Input**: User description: "build a macos version of Tanto. What is Tanto, you can check the parent folder @../README.md for details."

## User Scenarios & Testing

### User Story 1 - Modal Activation & Navigation (Priority: P1)
As a power user, I want to toggle Vim-like modes globally using CapsLock so that I can navigate text without leaving the home row.

**Why this priority**: Core value proposition. Without this, the app does nothing.

**Independent Test**:
1. Launch app (background mode).
2. Open Apple Notes.
3. Press `CapsLock`. Verify Cursor changes to Crosshair (Visual Mode).
4. Press `I`/`K`/`J`/`L`. Verify text selection expands (Shift+Arrow behavior).
5. Press `Esc`. Verify Cursor returns to default and keys type letters again.

**Acceptance Scenarios**:
1. **Given** app is running, **When** I press CapsLock, **Then** system enters Visual Mode and cursor updates.
2. **Given** Visual Mode, **When** I press IJKL, **Then** system simulates Shift+Arrow events.
3. **Given** Visual Mode, **When** I press v, **Then** system toggles to Normal Mode (Cursor: Four-way Arrow, Keys: Arrows).

---

### User Story 2 - One-Shot Editing (Priority: P2)
As a developer, I want copy/cut/delete actions to immediately return me to typing mode so that I don't have to press Esc manually.

**Why this priority**: DIFFERENTIATOR. This is the "One-shot" philosophy defined in the Constitution.

**Independent Test**:
1. Enter Visual Mode.
2. Select text with IJKL.
3. Press `c` (Copy).
4. Verify text is copied to clipboard.
5. Verify system IMMEDIATELY returns to Insert Mode (cursor resets).

**Acceptance Scenarios**:
1. **Given** text selected in Visual Mode, **When** I press 'c', **Then** Cmd+C is sent and mode resets to Insert.
2. **Given** Normal Mode (no selection), **When** I press 'd', **Then** app enters "Operator Pending" state.
3. **Given** Operator Pending, **When** I press 'h' (Whole Line), **Then** Cmd+Backspace is sent (or line deletion logic) and mode resets.

---

### User Story 3 - Typeout Simulation (Priority: P3)
As a user, I want to paste clipboard content as keystrokes to bypass paste restrictions.

**Why this priority**: Useful utility but not core navigation.

**Independent Test**:
1. Copy text "Hello World".
2. Enter Normal Mode.
3. Press `t`.
4. Verify "Hello World" is typed out character by character.
5. Press `Esc` mid-typing. Verify typing stops immediately.

**Acceptance Scenarios**:
1. **Given** clipboard has text, **When** I press 't' in Normal Mode, **Then** app simulates keystrokes for each char.
2. **Given** typing is active, **When** I press Esc, **Then** typing aborts immediately.

## Requirements

### Functional Requirements

- **FR-001**: App MUST run as a background agent (`LSUIElement`) with no Dock icon.
- **FR-002**: App MUST intercept `CapsLock` globally using `CGEventTap`.
- **FR-003**: App MUST require and handle "Trusted Accessibility" permissions gracefully.
- **FR-004**: Visual Mode MUST map `IJKL` to `Shift + Up/Down/Left/Right`.
- **FR-005**: Normal Mode MUST map `IJKL` to `Up/Down/Left/Right`.
- **FR-006**: App MUST support jumping operations in Normal/Visual modes:
  - `Command + I/K`: Vertical Jump (Move/Select 5 lines).
  - `Command + J/L`: Horizontal Jump (Move/Select by Word).
- **FR-007**: App MUST display a custom cursor or overlay (Crosshair for Visual, Arrow for Normal) to indicate state.
- **FR-008**: One-Shot actions (`c`, `d`, `x`) MUST return state to `Insert` immediately after execution.
- **FR-009**: "Operator Pending" logic MUST support `h` (Line), `w` (Word), `b` (Back Word) modifiers.

### Key Entities

- **TantoEngine**: The central State Machine (Insert, Normal, Visual, Pending).
- **InputManager**: The C-style wrapper for `CGEventTap` callbacks.
- **OverlayManager**: Manages the cursor UI/Window overlay.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Mode switching latency (Key press to State change) < 20ms.
- **SC-002**: CPU usage at idle < 1%.
- **SC-003**: Memory usage < 50MB.
- **SC-004**: "Typeout" stops within 200ms of pressing Esc.

## Assumptions

- Target OS is macOS 12.0+.
- Standard US Keyboard layout is the primary target initially.
- We will simulate Mouse Cursor changes via a floating NSWindow or standard NSCursor API if globally possible (NSCursor often only works within app windows, so a floating overlay might be needed).
