import Foundation

public enum HotkeyMode: String, CaseIterable, Identifiable, Sendable {
    case simple
    case deepL

    public var id: String { rawValue }
}

public enum DeepLHotkeyEvent: Sendable {
    case commandC
    case other
}

public enum DeepLHotkeyMonitorStatus: String, Sendable {
    case inactive
    case active
    case permissionRequired
    case fallback

    public var label: String {
        switch self {
        case .inactive:
            "未启用"
        case .active:
            "DeepL 模式监听中"
        case .permissionRequired:
            "缺少输入监听或辅助功能权限，已回退到 ⌘⇧T"
        case .fallback:
            "事件监听不可用，已回退到 ⌘⇧T"
        }
    }
}

public struct DeepLHotkeyStateMachine: Sendable {
    private let window: TimeInterval
    private var firstCommandCAt: TimeInterval?

    public init(window: TimeInterval = 0.35) {
        self.window = window
    }

    public mutating func handle(_ event: DeepLHotkeyEvent, at timestamp: TimeInterval) -> Bool {
        guard case .commandC = event else {
            firstCommandCAt = nil
            return false
        }

        if let firstCommandCAt, timestamp - firstCommandCAt <= window {
            self.firstCommandCAt = nil
            return true
        }

        firstCommandCAt = timestamp
        return false
    }
}
