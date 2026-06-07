import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    
    private let keyTinygradPath = "TinygradPath"
    private let keyModelsDirectory = "ModelsDirectory"
    private let keySelectedModelFilename = "SelectedModelFilename"
    private let keyDeviceFlags = "DeviceFlags"
    private let keyPort = "Port"
    private let keyMaxContext = "MaxContext"
    
    private init() {}
    
    var tinygradPath: String {
        get { UserDefaults.standard.string(forKey: keyTinygradPath) ?? "~/tinygrad" }
        set { UserDefaults.standard.set(newValue, forKey: keyTinygradPath) }
    }
    
    var modelsDirectory: String {
        get { UserDefaults.standard.string(forKey: keyModelsDirectory) ?? "~/Documents/Models" }
        set { UserDefaults.standard.set(newValue, forKey: keyModelsDirectory) }
    }
    
    var selectedModelFilename: String {
        get { UserDefaults.standard.string(forKey: keySelectedModelFilename) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: keySelectedModelFilename) }
    }
    
    var deviceFlags: String {
        get { UserDefaults.standard.string(forKey: keyDeviceFlags) ?? "DEV=NV" }
        set { UserDefaults.standard.set(newValue, forKey: keyDeviceFlags) }
    }
    
    var port: String {
        get { UserDefaults.standard.string(forKey: keyPort) ?? "8000" }
        set { UserDefaults.standard.set(newValue, forKey: keyPort) }
    }
    
    var maxContext: String {
        get { UserDefaults.standard.string(forKey: keyMaxContext) ?? "8192" }
        set { UserDefaults.standard.set(newValue, forKey: keyMaxContext) }
    }
    
    /// Expands the tilde (~) in user paths to full absolute paths.
    func expandPath(_ path: String) -> String {
        let nsPath = path as NSString
        return nsPath.expandingTildeInPath
    }
    
    /// Synchronizes the current active model, port, and maximum context length to VS Code's chatLanguageModels.json.
    func syncToVSCode(maxTokens: Int) {
        // Run asynchronously in the background to avoid blocking the main thread
        DispatchQueue.global(qos: .background).async {
            self.performSyncToVSCode(maxTokens: maxTokens)
        }
    }
    
    private func performSyncToVSCode(maxTokens: Int) {
        let fileManager = FileManager.default
        let configURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Code/User/chatLanguageModels.json")
        let vsCodeUserDir = configURL.deletingLastPathComponent()
        
        // Read existing config or start with empty array
        var rootArray: [[String: Any]] = []
        if fileManager.fileExists(atPath: configURL.path) {
            do {
                let data = try Data(contentsOf: configURL)
                if let parsed = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    rootArray = parsed
                }
            } catch {
                print("Error reading or parsing existing chatLanguageModels.json: \(error)")
                // Proceed with empty/new array
            }
        }
        
        // Find existing TinySwitch entry or create a new one
        var tinySwitchIndex: Int? = nil
        for (index, provider) in rootArray.enumerated() {
            if let name = provider["name"] as? String, name.localizedCaseInsensitiveContains("tinyswitch") {
                tinySwitchIndex = index
                break
            } else if let vendor = provider["vendor"] as? String, vendor.lowercased() == "customendpoint" {
                tinySwitchIndex = index
                break
            }
        }
        
        // Current settings values
        let modelFile = self.selectedModelFilename
        let modelDisplayName = modelFile.isEmpty ? "TinySwitch Model" : (modelFile as NSString).deletingPathExtension
        let modelId = modelFile.isEmpty ? "tinyswitch-model" : modelFile
        
        let newModelEntry: [String: Any] = [
            "id": modelId,
            "name": modelDisplayName,
            "url": "http://localhost:8000/v1/chat/completions",
            "maxInputTokens": maxTokens,
            "maxOutputTokens": maxTokens,
            "maxTokens": maxTokens,
            "contextWindow": maxTokens,
            "toolCalling": true,
            "vision": false
        ]
        
        if let idx = tinySwitchIndex {
            var provider = rootArray[idx]
            // Completely overwrite/update the models list to reflect the active model settings
            provider["models"] = [newModelEntry]
            rootArray[idx] = provider
        } else {
            let newProvider: [String: Any] = [
                "name": "TinySwitch",
                "vendor": "customendpoint",
                "apiType": "chat-completions",
                "models": [newModelEntry]
            ]
            rootArray.append(newProvider)
        }
        
        // Write configurations to completely overwrite the existing file contents
        do {
            // Ensure parent directory exists (though it usually does)
            try fileManager.createDirectory(at: vsCodeUserDir, withIntermediateDirectories: true, attributes: nil)
            
            let data = try JSONSerialization.data(withJSONObject: rootArray, options: [.prettyPrinted, .sortedKeys])
            
            // Try writing atomically first, fallback to direct write if needed
            do {
                try data.write(to: configURL, options: .atomic)
            } catch {
                print("Atomic write failed, attempting direct write to overwrite: \(error)")
                try data.write(to: configURL)
            }
            
            print("Successfully synced settings to VS Code at \(configURL.path)")
        } catch {
            print("CRITICAL ERROR: Failed to write VS Code config: \(error)")
            fputs("CRITICAL ERROR: Failed to write VS Code config: \(error.localizedDescription)\n", stderr)
        }
    }
}

