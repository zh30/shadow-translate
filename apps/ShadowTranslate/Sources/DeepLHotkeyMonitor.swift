import CoreGraphics
import Foundation
import SharedCore
import UIKitShared

final class DeepLHotkeyMonitor {
    private static let commandCKeyCode: CGKeyCode = 8
    private static let statusKey = "deepLHotkeyStatus"

    private let lock = NSLock()
    private let onTrigger: @MainActor () -> Void
    private var stateMachine = DeepLHotkeyStateMachine()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(onTrigger: @escaping @MainActor () -> Void) {
        self.onTrigger = onTrigger
    }

    deinit {
        stop(publishInactive: false)
    }

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else {
            publish(.active)
            return true
        }

        guard CGPreflightListenEventAccess() else {
            _ = CGRequestListenEventAccess()
            publish(.permissionRequired)
            Log.app.warning("DeepLHotkeyMonitor.start · listen event permission required")
            return false
        }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: Self.handleEvent,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            publish(.fallback)
            Log.app.warning("DeepLHotkeyMonitor.start · failed to create CGEventTap")
            return false
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            publish(.fallback)
            return false
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        publish(.active)
        Log.app.info("DeepLHotkeyMonitor.start · active")
        return true
    }

    func stop(publishInactive: Bool = true) {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        eventTap = nil
        runLoopSource = nil
        resetState()
        if publishInactive {
            publish(.inactive)
        }
    }

    private func resetState() {
        lock.lock()
        stateMachine = DeepLHotkeyStateMachine()
        lock.unlock()
    }

    private func handle(event: DeepLHotkeyEvent, at timestamp: TimeInterval) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return stateMachine.handle(event, at: timestamp)
    }

    private func fireTrigger() {
        Task { @MainActor [onTrigger] in
            onTrigger()
        }
    }

    private func publish(_ status: DeepLHotkeyMonitorStatus) {
        guard UserDefaults.standard.string(forKey: Self.statusKey) != status.rawValue else { return }
        UserDefaults.standard.set(status.rawValue, forKey: Self.statusKey)
    }

    private static let handleEvent: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else {
            return Unmanaged.passUnretained(event)
        }

        let monitor = Unmanaged<DeepLHotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = monitor.eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let isCommandC = keyCode == commandCKeyCode
            && flags.contains(.maskCommand)
            && !flags.contains(.maskControl)
            && !flags.contains(.maskAlternate)

        let didTrigger = monitor.handle(
            event: isCommandC ? .commandC : .other,
            at: Date().timeIntervalSince1970
        )

        if didTrigger {
            Log.app.info("DeepLHotkeyMonitor · detected ⌘C double press")
            monitor.fireTrigger()
        }

        return Unmanaged.passUnretained(event)
    }
}
