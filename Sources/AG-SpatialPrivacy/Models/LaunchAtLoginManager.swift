import Foundation
import ServiceManagement

@MainActor
public final class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()

    @Published public private(set) var isEnabled: Bool = false

    private var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.1bnjmn3.AG-SpatialPrivacy.plist")
    }

    private var appBundlePath: String {
        Bundle.main.bundlePath
    }

    private init() {
        refreshStatus()
    }

    public func refreshStatus() {
        let plistExists = FileManager.default.fileExists(atPath: launchAgentURL.path)
        let smStatus = (SMAppService.mainApp.status == .enabled)
        isEnabled = plistExists || smStatus
    }

    public func setEnabled(_ enabled: Bool) {
        if enabled {
            installLaunchAgent()
            try? SMAppService.mainApp.register()
            print("[LaunchAtLogin] Enabled startup launch")
        } else {
            removeLaunchAgent()
            try? SMAppService.mainApp.unregister()
            print("[LaunchAtLogin] Disabled startup launch")
        }
        refreshStatus()
    }

    public func registerOnStartup() {
        installLaunchAgent()
        try? SMAppService.mainApp.register()
        refreshStatus()
    }

    private func installLaunchAgent() {
        let path = appBundlePath
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.1bnjmn3.AG-SpatialPrivacy</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/open</string>
                <string>\(path)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>ProcessType</key>
            <string>Interactive</string>
        </dict>
        </plist>
        """
        try? plistContent.write(to: launchAgentURL, atomically: true, encoding: .utf8)
    }

    private func removeLaunchAgent() {
        try? FileManager.default.removeItem(at: launchAgentURL)
    }
}
