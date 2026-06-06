import AppKit
import Darwin

enum ServerState {
    case off
    case connecting
    case connected
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem!
    var menu: NSMenu!
    
    var startItem: NSMenuItem!
    var stopItem: NSMenuItem!
    var settingsItem: NSMenuItem!
    
    var settingsWindow: SettingsWindow?
    var process: Process?
    
    var serverState: ServerState = .off
    private var healthCheckTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopServer()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        menu = NSMenu()
        
        startItem = NSMenuItem(title: "Start Server", action: #selector(startServerClicked), keyEquivalent: "")
        startItem.target = self
        menu.addItem(startItem)
        
        stopItem = NSMenuItem(title: "Stop Server", action: #selector(stopServerClicked), keyEquivalent: "")
        stopItem.target = self
        menu.addItem(stopItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let logItem = NSMenuItem(title: "View Server Logs...", action: #selector(showLogsClicked), keyEquivalent: "")
        logItem.target = self
        menu.addItem(logItem)
        
        settingsItem = NSMenuItem(title: "Settings...", action: #selector(settingsClicked), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        transitionTo(state: .off)
    }
    
    private func transitionTo(state: ServerState) {
        self.serverState = state
        updateMenuState(state: state)
    }
    
    private func updateMenuState(state: ServerState) {
        if let button = statusItem.button {
            let imageName: String
            let fallbackTitle: String
            let toolTip: String
            
            switch state {
            case .off:
                imageName = "status_red"
                fallbackTitle = "🔴"
                toolTip = "TinySwitch: Server Offline"
            case .connecting:
                imageName = "status_yellow"
                fallbackTitle = "🟡"
                toolTip = "TinySwitch: Server Loading..."
            case .connected:
                imageName = "status_green"
                fallbackTitle = "🟢"
                toolTip = "TinySwitch: Server Online"
            }
            
            if let image = NSImage(named: imageName) {
                image.isTemplate = false
                button.image = image
                button.title = ""
            } else {
                button.image = nil
                button.title = fallbackTitle
            }
            button.toolTip = toolTip
        }
        
        let isOff = state == .off
        startItem.isEnabled = isOff
        stopItem.isEnabled = !isOff
        settingsItem.isEnabled = isOff
    }
    
    @objc func statusBarButtonClicked(_ sender: Any?) {
        guard let button = statusItem.button, let window = button.window else { return }
        
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp || 
                           (event?.type == .leftMouseUp && event?.modifierFlags.contains(.control) == true)
        
        if isRightClick {
            let frame = window.frame
            // Align menu below the status item button
            let pt = CGPoint(x: frame.origin.x, y: frame.origin.y - 4)
            button.isHighlighted = true
            menu.popUp(positioning: nil, at: pt, in: nil)
            button.isHighlighted = false
        } else {
            toggleServer()
        }
    }
    
    private func toggleServer() {
        if serverState == .off {
            startServerClicked(nil)
        } else {
            stopServer()
        }
    }
    
    @objc func startServerClicked(_ sender: Any?) {
        let manager = SettingsManager.shared
        let resolvedTinygrad = manager.expandPath(manager.tinygradPath)
        
        // 1. Verify Tinygrad path exists
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: resolvedTinygrad, isDirectory: &isDir)
        if !exists || !isDir.boolValue {
            let alert = NSAlert()
            alert.messageText = "Tinygrad Path Not Found"
            alert.informativeText = "The directory at '\(resolvedTinygrad)' does not exist. Please update your path in Settings."
            alert.alertStyle = .warning
            alert.runModal()
            return
        }
        
        // 2. Verify model selection is valid
        let selectedModel = manager.selectedModelFilename
        if selectedModel.isEmpty || selectedModel == "(No .gguf models found)" {
            let alert = NSAlert()
            alert.messageText = "No Model Selected"
            alert.informativeText = "Please select a valid .gguf model in Settings before starting the server."
            alert.alertStyle = .warning
            alert.runModal()
            return
        }
        
        // Construct and verify full model path
        let resolvedModelsDir = manager.expandPath(manager.modelsDirectory)
        let fullModelPath = (resolvedModelsDir as NSString).appendingPathComponent(selectedModel)
        
        if !FileManager.default.fileExists(atPath: fullModelPath) {
            let alert = NSAlert()
            alert.messageText = "Model File Not Found"
            alert.informativeText = "The model file at '\(fullModelPath)' was not found. Do you want to start the server anyway?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Start Anyway")
            if alert.runModal() == .alertFirstButtonReturn {
                return
            }
        }
        
        // 3. Prepare log directory
        let logPath = manager.expandPath("~/Library/Logs/TinySwitch.log")
        let logDir = (logPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: logDir, withIntermediateDirectories: true)
        
        // Reset or create log file
        FileManager.default.createFile(atPath: logPath, contents: nil)
        
        // 4. Assemble execution command
        let deviceFlags = manager.deviceFlags
        let port = manager.port
        let maxContext = manager.maxContext
        
        var deviceFlagsPart = ""
        if !deviceFlags.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            deviceFlagsPart = "export \(deviceFlags) && "
        }
        
        let cmd = "export PATH=~/.local/bin:~/tinygrad/bin:/usr/local/cuda/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:$PATH && cd \"\(resolvedTinygrad)\" && \(deviceFlagsPart)exec python3 -m tinygrad.llm --model \"\(fullModelPath)\" --max_context \(maxContext) --serve \(port) > \"\(logPath)\" 2>&1"
        
        // 5. Spawn Process
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/zsh")
        p.arguments = ["-c", cmd]
        p.terminationHandler = { [weak self] proc in
            DispatchQueue.main.async {
                self?.processTerminated()
            }
        }
        
        self.process = p
        
        do {
            try p.run()
            transitionTo(state: .connecting)
            startHealthCheck()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to Start Server"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
            transitionTo(state: .off)
        }
    }
    
    @objc func stopServerClicked(_ sender: Any?) {
        stopServer()
    }
    
    func stopServer() {
        stopHealthCheck()
        transitionTo(state: .off)
        
        guard let p = self.process, p.isRunning else { return }
        let pid = p.processIdentifier
        if pid > 0 {
            // Kill the entire process group
            kill(-pid, SIGTERM)
            
            // Safety timeout: if still running after 2.0s, force kill
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                if let proc = self.process, proc.isRunning {
                    let pid2 = proc.processIdentifier
                    if pid2 > 0 {
                        kill(-pid2, SIGKILL)
                    }
                }
            }
        } else {
            p.terminate()
        }
    }
    
    private func processTerminated() {
        self.process = nil
        stopHealthCheck()
        transitionTo(state: .off)
    }
    
    private func startHealthCheck() {
        healthCheckTimer?.invalidate()
        let port = SettingsManager.shared.port
        let urlString = "http://127.0.0.1:\(port)/v1/models"
        guard let url = URL(string: urlString) else { return }
        
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkServerHealth(url: url)
        }
    }
    
    private func checkServerHealth(url: URL) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 1.0
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if self.serverState == .connecting {
                        self.transitionTo(state: .connected)
                        self.stopHealthCheck() // Stop checking once connected to save resources
                    }
                }
            }
        }
        task.resume()
    }
    
    private func stopHealthCheck() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    @objc func settingsClicked(_ sender: Any?) {
        // Recreate Settings Window to always reflect fresh configuration
        settingsWindow = SettingsWindow()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func showLogsClicked(_ sender: Any?) {
        let logPath = SettingsManager.shared.expandPath("~/Library/Logs/TinySwitch.log")
        let url = URL(fileURLWithPath: logPath)
        if FileManager.default.fileExists(atPath: logPath) {
            NSWorkspace.shared.open(url)
        } else {
            let alert = NSAlert()
            alert.messageText = "No Logs Found"
            alert.informativeText = "The log file does not exist yet. It will be created when the server starts."
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
    
    @objc func quitClicked(_ sender: Any?) {
        NSApplication.shared.terminate(self)
    }
}
