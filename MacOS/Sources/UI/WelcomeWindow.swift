import Cocoa
import Utils

public class WelcomeWindowController: NSWindowController {
    private var statusLabel: NSTextField!
    private var actionButton: NSButton!
    
    public convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Tanto Setup"
        window.level = .floating
        window.center()
        self.init(window: window)
        setupUI()
        refreshStatus()
        
        // Listen for window activation to refresh status (in case user toggled setting)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshStatus), name: NSApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -40)
        ])
        
        // Logo / Title
        let titleLabel = NSTextField(labelWithString: "Tanto")
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        stackView.addArrangedSubview(titleLabel)
        
        // Instructions
        let instructions = """
        Tanto brings Vim-like editing to macOS.
        
        1. Grant Accessibility Permissions.
        2. Press CapsLock to toggle Visual Mode.
        3. Use I/J/K/L to navigate.
        """
        let instructionLabel = NSTextField(labelWithString: instructions)
        instructionLabel.alignment = .center
        stackView.addArrangedSubview(instructionLabel)
        
        // Status
        statusLabel = NSTextField(labelWithString: "Status: Checking...")
        statusLabel.font = NSFont.systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(statusLabel)
        
        // Button
        actionButton = NSButton(title: "Open Permissions", target: self, action: #selector(openPermissions))
        actionButton.bezelStyle = .rounded
        stackView.addArrangedSubview(actionButton)
    }
    
    @objc private func refreshStatus() {
        if Permissions.isTrusted() {
            statusLabel.stringValue = "Status: Ready (Trusted)"
            statusLabel.textColor = .systemGreen
            actionButton.title = "Close"
            actionButton.action = #selector(closeWindow)
        } else {
            statusLabel.stringValue = "Status: Permission Missing"
            statusLabel.textColor = .systemRed
            actionButton.title = "Grant Permissions"
            actionButton.action = #selector(openPermissions)
        }
    }
    
    @objc private func openPermissions() {
        Permissions.prompt()
        Permissions.openSystemSettings()
    }
    
    @objc private func closeWindow() {
        window?.close()
    }
}
