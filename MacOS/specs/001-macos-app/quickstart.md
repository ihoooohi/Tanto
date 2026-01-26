# Quickstart: macOS Native App

**Feature**: `001-macos-app`

## Prerequisites

- macOS 12.0+ (Monterey)
- Xcode 14+ (or Command Line Tools)
- Swift 5.9+

## Building

```bash
# From repository root
cd Tanto
swift build -c release
```

## Running

```bash
# Run directly (will prompt for Permissions)
.build/release/Tanto
```

## Troubleshooting Permissions

If the app silently fails to intercept keys:

1. Open **System Settings** > **Privacy & Security** > **Accessibility**.
2. Remove any existing "Tanto" or "Terminal" entries if running from CLI.
3. Re-run the app.
4. Click "Allow" on the prompt.

**Note**: When running from Terminal (during dev), the *Terminal app* (iTerm/Terminal) needs Accessibility permissions to intercept keys for the child process.

## Development Loop

```bash
# Run tests
swift test

# Watch mode (if strictly needed, otherwise manual)
swift run
```
