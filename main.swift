import Cocoa
import ServiceManagement

// MARK: - Clipboard history store (memory-only — nothing written to disk)

final class ClipboardManager {
    static let maxItems = 25
    private(set) var items: [String] = []   // memory only — never written to disk

    func add(_ s: String) {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if items.first == s { return }
        items.removeAll { $0 == s }
        items.insert(s, at: 0)
        if items.count > Self.maxItems {
            items.removeLast(items.count - Self.maxItems)
        }
    }

    func clear() {
        items.removeAll()
    }
}

// MARK: - Menu bar app

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let clipboard = ClipboardManager()
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?

    // Pasteboard hints set by well-behaved apps (e.g. password managers)
    private let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
    private let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // menu-bar only, no Dock icon

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "paperclip",
                                   accessibilityDescription: "ClipStash")
        }

        rebuildMenu()

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        let types = pb.types ?? []
        // Respect privacy hints: never record passwords / transient pastes.
        if types.contains(concealedType) || types.contains(transientType) { return }

        if let s = pb.string(forType: .string) {
            clipboard.add(s)
            rebuildMenu()
        }
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        if clipboard.items.isEmpty {
            let empty = NSMenuItem(title: "No clippings yet", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            let header = NSMenuItem(title: "Recent clippings", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
            for (i, item) in clipboard.items.enumerated() {
                let mi = NSMenuItem(title: Self.truncate(item),
                                    action: #selector(copyItem(_:)),
                                    keyEquivalent: i < 9 ? String(i + 1) : "")
                mi.target = self
                mi.representedObject = item
                menu.addItem(mi)
            }
        }

        menu.addItem(.separator())

        let launch = NSMenuItem(title: "Launch at Login",
                                action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launch.target = self
        launch.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        menu.addItem(launch)

        let clearItem = NSMenuItem(title: "Clear History",
                                   action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        let quit = NSMenuItem(title: "Quit ClipStash",
                              action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func copyItem(_ sender: NSMenuItem) {
        guard let s = sender.representedObject as? String else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(s, forType: .string)
        lastChangeCount = pb.changeCount // don't let our own write re-trigger poll()
        clipboard.add(s)                 // move it back to the top
        rebuildMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't change Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        rebuildMenu()
    }

    @objc private func clearHistory() {
        clipboard.clear()
        rebuildMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private static func truncate(_ s: String, _ max: Int = 50) -> String {
        let oneLine = s.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard oneLine.count > max else { return oneLine }
        let idx = oneLine.index(oneLine.startIndex, offsetBy: max)
        return String(oneLine[..<idx]) + "…"
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
