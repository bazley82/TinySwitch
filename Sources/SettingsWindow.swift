import AppKit

class SettingsWindow: NSWindow {
    
    private var tinygradPathField: NSTextField!
    private var modelsDirField: NSTextField!
    private var modelDropdown: NSPopUpButton!
    private var deviceFlagsDropdown: NSPopUpButton!
    private var portField: NSTextField!
    private var maxContextDropdown: NSPopUpButton!
    
    init() {
        let styleMask: NSWindow.StyleMask = [.titled, .closable]
        let rect = NSRect(x: 0, y: 0, width: 540, height: 350)
        super.init(contentRect: rect, styleMask: styleMask, backing: .buffered, defer: false)
        
        self.title = "TinySwitch Settings"
        self.isReleasedWhenClosed = false
        self.center()
        
        setupUI()
        loadSettings()
    }
    
    private func setupUI() {
        // Main container stack view
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 16
        container.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Window Title Label
        let titleLabel = NSTextField(labelWithString: "TinySwitch Preferences")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        container.addArrangedSubview(titleLabel)
        
        // Tinygrad Path
        let tgLabel = NSTextField(labelWithString: "Tinygrad Path:")
        tgLabel.alignment = .right
        tinygradPathField = NSTextField()
        tinygradPathField.placeholderString = "~/tinygrad"
        let tgBrowseBtn = NSButton(title: "Browse...", target: self, action: #selector(browseTinygradPath))
        tgBrowseBtn.bezelStyle = .rounded
        
        // Models Directory
        let modelsDirLabel = NSTextField(labelWithString: "Models Folder:")
        modelsDirLabel.alignment = .right
        modelsDirField = NSTextField()
        modelsDirField.placeholderString = "~/Documents/Models"
        modelsDirField.target = self
        modelsDirField.action = #selector(modelsDirChanged)
        let modelsDirBrowseBtn = NSButton(title: "Browse...", target: self, action: #selector(browseModelsDir))
        modelsDirBrowseBtn.bezelStyle = .rounded
        
        // Active Model Dropdown
        let modelDropdownLabel = NSTextField(labelWithString: "Active Model:")
        modelDropdownLabel.alignment = .right
        modelDropdown = NSPopUpButton()
        modelDropdown.target = self
        modelDropdown.action = #selector(modelSelectionChanged(_:))
        
        // Device Flags Dropdown
        let flagsLabel = NSTextField(labelWithString: "Device Flags:")
        flagsLabel.alignment = .right
        deviceFlagsDropdown = NSPopUpButton()
        deviceFlagsDropdown.addItems(withTitles: [
            "NVIDIA GPU via Docker (DEV=NV)",
            "Apple Metal Native (DEV=METAL)"
        ])
        
        // Port
        let portLabel = NSTextField(labelWithString: "Port:")
        portLabel.alignment = .right
        portField = NSTextField()
        portField.placeholderString = "8000"
        
        // Max Context Length Dropdown
        let maxContextLabel = NSTextField(labelWithString: "Max Context Length:")
        maxContextLabel.alignment = .right
        maxContextDropdown = NSPopUpButton()
        maxContextDropdown.addItems(withTitles: ["2048", "4096", "8192", "16384", "32768"])
        maxContextDropdown.target = self
        maxContextDropdown.action = #selector(maxContextChanged(_:))
        
        // Set constraints to make fields expand nicely
        tinygradPathField.translatesAutoresizingMaskIntoConstraints = false
        modelsDirField.translatesAutoresizingMaskIntoConstraints = false
        modelDropdown.translatesAutoresizingMaskIntoConstraints = false
        deviceFlagsDropdown.translatesAutoresizingMaskIntoConstraints = false
        portField.translatesAutoresizingMaskIntoConstraints = false
        maxContextDropdown.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tinygradPathField.widthAnchor.constraint(equalToConstant: 260),
            modelsDirField.widthAnchor.constraint(equalToConstant: 260),
            modelDropdown.widthAnchor.constraint(equalToConstant: 260),
            deviceFlagsDropdown.widthAnchor.constraint(equalToConstant: 260),
            portField.widthAnchor.constraint(equalToConstant: 100),
            maxContextDropdown.widthAnchor.constraint(equalToConstant: 100)
        ])
        
        // Settings form using NSGridView
        let formGrid = NSGridView(views: [
            [tgLabel, tinygradPathField, tgBrowseBtn],
            [modelsDirLabel, modelsDirField, modelsDirBrowseBtn],
            [modelDropdownLabel, modelDropdown, NSView()],
            [flagsLabel, deviceFlagsDropdown, NSView()],
            [portLabel, portField, NSView()],
            [maxContextLabel, maxContextDropdown, NSView()]
        ])
        formGrid.rowSpacing = 12
        formGrid.columnSpacing = 10
        
        // Alignments
        formGrid.column(at: 0).xPlacement = .trailing
        formGrid.column(at: 1).xPlacement = .fill
        
        container.addArrangedSubview(formGrid)
        
        // Action buttons
        let actionsStack = NSStackView()
        actionsStack.orientation = .horizontal
        actionsStack.spacing = 12
        actionsStack.alignment = .centerY
        
        let cancelBtn = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        cancelBtn.bezelStyle = .rounded
        cancelBtn.keyEquivalent = "\u{1b}" // Escape key
        
        let saveBtn = NSButton(title: "Save Settings", target: self, action: #selector(saveClicked))
        saveBtn.bezelStyle = .rounded
        saveBtn.keyEquivalent = "\r" // Enter key
        saveBtn.bezelColor = .controlAccentColor
        
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        actionsStack.addArrangedSubview(spacer) // Push buttons to the right
        actionsStack.addArrangedSubview(cancelBtn)
        actionsStack.addArrangedSubview(saveBtn)
        
        container.addArrangedSubview(actionsStack)
        
        self.contentView = container
    }
    
    private func loadSettings() {
        let manager = SettingsManager.shared
        tinygradPathField.stringValue = manager.tinygradPath
        modelsDirField.stringValue = manager.modelsDirectory
        portField.stringValue = manager.port
        
        // Load device flags dropdown choice
        let currentFlags = manager.deviceFlags
        if currentFlags == "DEV=METAL" {
            deviceFlagsDropdown.selectItem(withTitle: "Apple Metal Native (DEV=METAL)")
        } else {
            deviceFlagsDropdown.selectItem(withTitle: "NVIDIA GPU via Docker (DEV=NV)")
        }
        
        // Load max context length dropdown choice
        let currentContext = manager.maxContext
        maxContextDropdown.selectItem(withTitle: currentContext)
        if maxContextDropdown.selectedItem == nil {
            maxContextDropdown.selectItem(withTitle: "8192") // default fallback
        }
        
        // Scan directory and populate dropdown
        refreshModelDropdown()
    }
    
    private func refreshModelDropdown() {
        modelDropdown.removeAllItems()
        
        let manager = SettingsManager.shared
        let expandedDir = manager.expandPath(modelsDirField.stringValue)
        
        var files: [String] = []
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: expandedDir)
            files = contents.filter { $0.lowercased().hasSuffix(".gguf") }.sorted()
        } catch {
            print("Error scanning directory \(expandedDir): \(error)")
        }
        
        if files.isEmpty {
            modelDropdown.addItem(withTitle: "(No .gguf models found)")
            modelDropdown.isEnabled = false
        } else {
            modelDropdown.addItems(withTitles: files)
            modelDropdown.isEnabled = true
            
            // Select previously selected model if it exists in the list
            let prevSelected = manager.selectedModelFilename
            if !prevSelected.isEmpty && files.contains(prevSelected) {
                modelDropdown.selectItem(withTitle: prevSelected)
            } else {
                modelDropdown.selectItem(at: 0)
            }
        }
    }
    
    @objc private func modelsDirChanged(_ sender: Any?) {
        refreshModelDropdown()
    }
    
    @objc private func browseTinygradPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        let initialPath = SettingsManager.shared.expandPath(tinygradPathField.stringValue)
        panel.directoryURL = URL(fileURLWithPath: initialPath)
        
        panel.beginSheetModal(for: self) { response in
            if response == .OK, let url = panel.url {
                let path = url.path
                let home = NSHomeDirectory()
                if path.hasPrefix(home) {
                    let relative = path.replacingOccurrences(of: home, with: "~")
                    self.tinygradPathField.stringValue = relative
                } else {
                    self.tinygradPathField.stringValue = path
                }
            }
        }
    }
    
    @objc private func browseModelsDir() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        let initialPath = SettingsManager.shared.expandPath(modelsDirField.stringValue)
        panel.directoryURL = URL(fileURLWithPath: initialPath)
        
        panel.beginSheetModal(for: self) { response in
            if response == .OK, let url = panel.url {
                let path = url.path
                let home = NSHomeDirectory()
                if path.hasPrefix(home) {
                    let relative = path.replacingOccurrences(of: home, with: "~")
                    self.modelsDirField.stringValue = relative
                } else {
                    self.modelsDirField.stringValue = path
                }
                self.refreshModelDropdown()
                self.modelSelectionChanged(self.modelDropdown)
            }
        }
    }
    
    @objc private func cancelClicked() {
        self.close()
    }
    
    @objc private func saveClicked() {
        let manager = SettingsManager.shared
        manager.tinygradPath = tinygradPathField.stringValue
        manager.modelsDirectory = modelsDirField.stringValue
        
        if modelDropdown.isEnabled, let selectedTitle = modelDropdown.titleOfSelectedItem {
            if selectedTitle != "(No .gguf models found)" {
                manager.selectedModelFilename = selectedTitle
            } else {
                manager.selectedModelFilename = ""
            }
        } else {
            manager.selectedModelFilename = ""
        }
        
        // Save raw device flags based on selected menu item
        let selectedFlagsTitle = deviceFlagsDropdown.titleOfSelectedItem
        if selectedFlagsTitle == "Apple Metal Native (DEV=METAL)" {
            manager.deviceFlags = "DEV=METAL"
        } else {
            manager.deviceFlags = "DEV=NV"
        }
        
        manager.port = portField.stringValue
        
        // Save selected context length
        var tokens = 8192
        if let selectedContext = maxContextDropdown.titleOfSelectedItem {
            manager.maxContext = selectedContext
            tokens = Int(selectedContext) ?? 8192
        }
        
        // Sync to VS Code on save
        manager.syncToVSCode(maxTokens: tokens)
        
        self.close()
    }
    
    private func contextLimit(for modelName: String) -> Int {
        // Internal dictionary mapping model options to context ceilings
        let mapping: [String: Int] = [
            "Heavy 35B Model": 8192,
            "Faster Smaller Model": 4096
        ]
        if let limit = mapping[modelName] {
            return limit
        }
        // Substring checks for scanned model names
        if modelName.localizedCaseInsensitiveContains("35b") {
            return 8192
        }
        return 4096
    }
    
    @objc private func modelSelectionChanged(_ sender: NSPopUpButton) {
        guard let selectedModel = sender.titleOfSelectedItem,
              selectedModel != "(No .gguf models found)" else { return }
        
        let tokens = contextLimit(for: selectedModel)
        
        // Auto-populate the Max Context Length dropdown
        maxContextDropdown.selectItem(withTitle: String(tokens))
        
        // Immediately sync to VS Code
        SettingsManager.shared.syncToVSCode(maxTokens: tokens)
    }
    
    @objc private func maxContextChanged(_ sender: NSPopUpButton) {
        guard let selectedContext = sender.titleOfSelectedItem,
              let tokens = Int(selectedContext) else { return }
        
        // Immediately sync to VS Code
        SettingsManager.shared.syncToVSCode(maxTokens: tokens)
    }
}
