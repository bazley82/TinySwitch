# TinySwitch 🟢🟡🔴

TinySwitch is a native macOS AppKit menu bar application designed to act as an offline control panel and manager for running local **Tinygrad LLM servers** (e.g. with AMD/NVIDIA eGPUs or Metal). It resides entirely in the status bar, manages background processes cleanly, and keeps local AI configurations in sync with developer environments like **VS Code**.

---

## 🌟 Core Features

### 1. 3-State Status Indicator (Red / Yellow / Green)
Instead of a simple binary toggle, TinySwitch implements a 3-state machine to accurately reflect server readiness:
*   🔴 **OFF (Red Switch):** The server process is completely dead, and no resources are consumed.
*   🟡 **CONNECTING/LOADING (Yellow Switch):** The background zsh process has launched. Tinygrad is scanning the folder, loading model weights, and compiling kernels/shaders into VRAM. The server is not yet accepting HTTP connections.
*   🟢 **CONNECTED (Green Switch):** The local server has bound to its designated port and responds successfully to health checks. It is fully ready to answer `/v1/chat/completions` API requests.

### 2. Automatic VS Code Token & Model Synchronization
TinySwitch bridges the gap between your macOS settings and your VS Code Copilot/Chat configuration:
*   **Model Context Mapping:** Automatically maps your active model to hardware-safe context ceiling limits:
    *   *Heavy 35B Models* ➔ default to **8192** tokens.
    *   *Faster Smaller Models* ➔ default to **4096** tokens.
*   **Target Configuration:** Directly parses and mutates the VS Code configuration file at:
    `~/Library/Application Support/Code/User/chatLanguageModels.json`
*   **Atomic Mutations:** Whenever you change the active model or manually override the context window in settings, TinySwitch updates `maxInputTokens`, `maxOutputTokens`, `maxTokens`, and `contextWindow` keys for the `TinySwitch` provider block. It also hardcodes the URL to `http://localhost:8000/v1/chat/completions` to ensure VS Code remains stable, even if the native server runs on a custom debug port.
*   **Fault-Tolerant Creation:** If the VS Code configuration file does not exist, TinySwitch will automatically create it with a structured default provider block.

### 3. Graceful Background Process Group Control
To prevent ghost processes from leaking VRAM or pinning CPU threads:
*   Launches the server in a login shell context via `/bin/zsh -c` to inherit standard paths (like CUDA/`nvcc` paths, homebrew, and local bins).
*   Appends `exec` to the Python command, replacing the zsh shell process image with the native Python execution thread.
*   On shutdown, retrieves the background process group identifier (`PID`) and performs POSIX-level process group signaling (`kill(-pid, SIGTERM)` followed by `SIGKILL` if unresponsive) to guarantee all spawned sub-processes are terminated cleanly.

### 4. Native Preferences UI
Built using AppKit and aligned with a grid system, the preferences modal offers:
*   **Models Folder Selection:** Select folders containing GGUF model files using native directory picker browsing panels.
*   **Dynamic Model Scanning:** Scans the folder and populates a dropdown list with all available `.gguf` model files.
*   **Hardware Device Flags:** Select between native macOS Metal execution (`DEV=METAL`) or Docker-routed NVIDIA eGPU runtime (`DEV=NV`).

---

## 🛠️ Installation & Compilation

Ensure you have Xcode Command Line Tools installed.

1.  Clone the repository or open the project folder:
    ```bash
    cd TinySwitch
    ```

2.  Run the build script:
    ```bash
    chmod +x build.sh
    ./build.sh
    ```
    This script will:
    *   Compile the Swift sources (`Sources/*.swift`).
    *   Compile the status icons using standard drawing context routines.
    *   Package everything into a self-contained macOS `TinySwitch.app` bundle.
    *   Deploy it directly to your `~/Applications/` directory.

3.  Apply ad-hoc code signing to avoid Gatekeeper constraints:
    ```bash
    codesign --force --deep --sign - ~/Applications/TinySwitch.app
    ```

4.  Launch the app:
    ```bash
    open ~/Applications/TinySwitch.app
    ```

---

## 📂 Codebase Architecture

```
TinySwitch/
├── Sources/
│   ├── main.swift              # App boots and triggers NSApplicationMain loop
│   ├── AppDelegate.swift       # Status bar interface, health check polling loop, process group manager
│   ├── SettingsManager.swift   # UserDefaults configuration storage and VS Code JSON sync routine
│   └── SettingsWindow.swift    # AppKit preferences window, dynamic model scanner & context mapping
├── Info.plist                  # Configures app to run as an LSUIElement agent (hidden from Dock)
├── build.sh                    # Automation compilation, packaging, and local deployment script
└── generate_icon.swift         # Dynamic status and application icon vector drawing engine
```

---

## 🔍 Verification & Logs

*   **Server Log Location:** TinySwitch redirects all stdout and stderr streams to:
    `~/Library/Logs/TinySwitch.log`
*   **Menu Log Access:** Click the status icon and select **View Server Logs...** to open the log file instantly in Console or your default text editor.
*   **VS Code Sync Verification:** Whenever a model or context length changes, verify the changes inside:
    `/Users/barriesanders/Library/Application Support/Code/User/chatLanguageModels.json`
