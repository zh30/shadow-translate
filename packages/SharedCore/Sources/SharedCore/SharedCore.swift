import Foundation
import os

public enum SharedCore {
    public static let version = "0.1.0"
}

public enum Language: String, Sendable, CaseIterable, Codable {
    case auto
    case en
    case zh
    case ja
    case ko
    case fr
    case de
    case es
    case it
    case pt
    case ru

    public var localizedName: String {
        switch self {
        case .auto: String(localized: "auto_detect", defaultValue: "Auto Detect")
        case .en: "English"
        case .zh: "中文"
        case .ja: "日本語"
        case .ko: "한국어"
        case .fr: "Français"
        case .de: "Deutsch"
        case .es: "Español"
        case .it: "Italiano"
        case .pt: "Português"
        case .ru: "Русский"
        }
    }
}

public enum ShadowError: Error, Sendable {
    case modelNotLoaded
    case inferenceFailed(String)
    case persistenceFailed(String)
    case accessibilityDenied
    case downloadFailed(String)
}

public enum Log {
    public static let subsystem = "dev.shadow.translate"
    public static let inference = Logger(subsystem: subsystem, category: "inference")
    public static let persistence = Logger(subsystem: subsystem, category: "persistence")
    public static let accessibility = Logger(subsystem: subsystem, category: "accessibility")
    public static let ui = Logger(subsystem: subsystem, category: "ui")
    public static let model = Logger(subsystem: subsystem, category: "model")
    public static let app = Logger(subsystem: subsystem, category: "app")
}
