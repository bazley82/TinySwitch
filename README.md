# TinySwitch 🟢🔴

TinySwitch is a lightweight, native macOS Swift menu bar application that acts as a universal GUI toggle switch and configuration manager for the local **Tinygrad AI server**.

## Features

- **Pure Menu Bar App**: Hides completely from the macOS Dock (`LSUIElement = YES`) and runs entirely in the status menu bar.
- **Dynamic Settings Window**: Allows users to persistent-configure the environment variables and server options.
- **Browse Actions**: Full integration with `NSOpenPanel` for intuitive folder and file selection.
- **Process Group Execution**: Safely manages the server in the background as a process group using `exec` shell execution and OS-level signaling (`kill(-pid, SIGTERM)`).
- **Persistent Storage**: Configurations are automatically stored and retrieved from `UserDefaults`.
- **Integrated Logging**: All stdout and stderr outputs of the server are captured and logged to `~/Library/Logs/TinySwitch.log` for troubleshooting.
- **Status Indicator**: Dynamic green/red SF symbols or fallbacks showing online/offline states.

## Architecture

- [Sources/main.swift](file:///Users/barriesanders/.gemini/antigravity-ide/scratch/TinySwitch/Sources/main.swift): Instantiates and launches the AppKit application loop.
- [Sources/AppDelegate.swift](file:///Users/barriesanders/.gemini/antigravity-ide/scratch/TinySwitch/Sources/AppDelegate.swift): Orchestrates status items, menu structure, and background server process lifecycles.
- [Sources/SettingsWindow.swift](file:///Users/barriesanders/.gemini/antigravity-ide/scratch/TinySwitch/Sources/SettingsWindow.swift): Formulates the preferences modal using a clean, auto-aligned `NSGridView`.
- [Sources/SettingsManager.swift](file:///Users/barriesanders/.gemini/antigravity-ide/scratch/TinySwitch/Sources/SettingsManager.swift): Abstracts interactions with `UserDefaults` and expands directory structures.

## Build and Package

To build and compile the standalone `.app` bundle:

```bash
chmod +x build.sh
./build.sh
```

This will:
1. Compile all Swift files using `swiftc`.
2. Package the files into `TinySwitch.app` along with `Info.plist`.
3. Copy the compiled `.app` directly to your `~/Applications/` directory.

## Troubleshooting

- **Server logs**: You can view the live server logs by clicking **View Server Logs...** in the TinySwitch dropdown menu, or inspect the file directly at `~/Library/Logs/TinySwitch.log`.
- **macOS Gatekeeper**: If macOS prevents launching custom-built binaries, you can re-apply ad-hoc code signatures by running:
  ```bash
  codesign --force --deep --sign - ~/Applications/TinySwitch.app
  ```
