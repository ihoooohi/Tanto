import Cocoa
import Core

public class OverlayManager {
    public static let shared = OverlayManager()
    
    private var statusItem: NSStatusItem?
    public var onOpenSettings: (() -> Void)?

    public init() {
        setupMenuBar()
        NotificationCenter.default.addObserver(self, selector: #selector(modeChanged(_:)), name: Notification.Name("TantoModeChanged"), object: nil)
    }
    
    @objc func modeChanged(_ notification: Notification) {
        if let mode = notification.userInfo?["mode"] as? InputMode {
            updateStatus(mode: mode)
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatus(mode: .insert)
        
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Tanto", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc func openSettings() {
        onOpenSettings?()
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    public func updateStatus(mode: InputMode) {
        DispatchQueue.main.async {
            guard let button = self.statusItem?.button else { return }
            switch mode {
            case .insert:
                button.title = "Tanto: I"
            case .normal:
                button.title = "Tanto: N"
            case .visual:
                button.title = "Tanto: V"
            case .operatorPending:
                button.title = "Tanto: P"
            case .typeout:
                button.title = "Tanto: T"
            }
        }
    }
}