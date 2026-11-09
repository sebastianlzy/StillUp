import AppKit
import IOKit.pwr_mgt

final class KeepAwake {
    private var assertion: IOPMAssertionID?

    var isActive: Bool { assertion != nil }

    @discardableResult
    func toggle() -> Bool {
        if let assertion {
            guard IOPMAssertionRelease(assertion) == kIOReturnSuccess else {
                return false
            }
            self.assertion = nil
        } else {
            var newAssertion: IOPMAssertionID = 0
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "StillUp: Keep Mac Awake" as CFString,
                &newAssertion
            )
            guard result == kIOReturnSuccess else { return false }
            assertion = newAssertion
        }
        return true
    }

    deinit {
        if let assertion {
            IOPMAssertionRelease(assertion)
        }
    }
}

final class StillUpDelegate: NSObject, NSApplicationDelegate {
    private let keepAwake = KeepAwake()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let toggleItem = NSMenuItem()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        toggleItem.action = #selector(toggleAwake)
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(
            title: "Quit StillUp",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)
        statusItem.menu = menu
        refreshMenu()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if keepAwake.isActive {
            keepAwake.toggle()
        }
    }

    @objc private func toggleAwake() {
        guard keepAwake.toggle() else {
            let alert = NSAlert()
            alert.messageText = "StillUp couldn’t change the sleep setting"
            alert.informativeText = "Try the menu bar toggle again."
            alert.runModal()
            return
        }
        refreshMenu()
    }

    private func refreshMenu() {
        let active = keepAwake.isActive
        let status = active ? "StillUp is keeping your Mac awake" : "StillUp is off"
        toggleItem.title = active ? "Allow Sleep" : "Keep Mac Awake"
        statusItem.button?.image = NSImage(
            systemSymbolName: active ? "cup.and.saucer.fill" : "cup.and.saucer",
            accessibilityDescription: status
        )
        statusItem.button?.setAccessibilityLabel(status)
        statusItem.button?.toolTip = status
    }
}

let app = NSApplication.shared
let delegate = StillUpDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
