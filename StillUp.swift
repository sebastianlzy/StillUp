import AppKit
import IOKit.pwr_mgt

final class KeepAwake {
    private var assertion: IOPMAssertionID?

    var isActive: Bool { assertion != nil }

    @discardableResult
    func setActive(_ active: Bool) -> Bool {
        guard active != isActive else { return true }
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

final class StillUpDelegate: NSObject, NSApplicationDelegate, NSViewToolTipOwner {
    private let keepAwake = KeepAwake()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let toggleItem = NSMenuItem()
    private let endTimeItem = NSMenuItem()
    private var sleepTimer: Timer?
    private var awakeStatus: String {
        keepAwake.isActive ? "StillUp is keeping your Mac awake" : "StillUp is off"
    }

    private let remainingTimeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        menu.addItem(endTimeItem)
        toggleItem.action = #selector(toggleAwake)
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        for hours in [1, 2, 5] {
            let item = NSMenuItem(
                title: hours == 1 ? "Keep Awake for 1 Hour" : "Keep Awake for \(hours) Hours",
                action: #selector(startTimedSession(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = hours
            menu.addItem(item)
        }
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
        if let button = statusItem.button {
            _ = button.addToolTip(button.bounds, owner: self, userData: nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        sleepTimer?.invalidate()
        keepAwake.setActive(false)
    }

    @objc private func toggleAwake() {
        setSession(active: !keepAwake.isActive)
    }

    @objc private func startTimedSession(_ item: NSMenuItem) {
        setSession(active: true, duration: TimeInterval(item.tag * 3600))
    }

    private func setSession(active: Bool, duration: TimeInterval? = nil) {
        guard keepAwake.setActive(active) else {
            refreshMenu()
            let alert = NSAlert()
            alert.messageText = "StillUp couldn’t change the sleep setting"
            alert.informativeText = "Try the menu bar toggle again."
            alert.runModal()
            return
        }
        sleepTimer?.invalidate()
        sleepTimer = nil
        if let duration {
            let timer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
                self?.endTimedSession()
            }
            sleepTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
        refreshMenu()
    }

    private func endTimedSession() {
        sleepTimer = nil
        setSession(active: false)
    }

    func view(_ view: NSView, stringForToolTip tag: NSView.ToolTipTag, point: NSPoint,
              userData: UnsafeMutableRawPointer?) -> String {
        if let sleepTimer {
            let seconds = max(0, ceil(sleepTimer.fireDate.timeIntervalSinceNow))
            if let remaining = remainingTimeFormatter.string(from: seconds) {
                return "\(remaining) remaining"
            }
        }
        return awakeStatus
    }

    private func refreshMenu() {
        let active = keepAwake.isActive
        let endTime = sleepTimer?.fireDate.formatted(date: .omitted, time: .shortened)
        endTimeItem.isHidden = endTime == nil
        endTimeItem.title = endTime.map { "Keeping Awake Until \($0)" } ?? ""
        let status = endTime.map { "StillUp is keeping your Mac awake until \($0)" }
            ?? awakeStatus
        toggleItem.title = active ? "Allow Sleep" : "Keep Mac Awake"
        statusItem.button?.image = NSImage(
            systemSymbolName: active ? "cup.and.saucer.fill" : "cup.and.saucer",
            accessibilityDescription: status
        )
        statusItem.button?.setAccessibilityLabel(status)
    }
}

let app = NSApplication.shared
let delegate = StillUpDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
