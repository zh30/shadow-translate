import Foundation
import SharedCore
import HuggingFace

public enum ModelManager {
    public static let version = "0.1.0"

    /// Default model ID on HuggingFace Hub.
    public static let defaultModelId = "mlx-community/translategemma-4b-it-4bit_immersive-translate"

    /// Directory where downloaded models are stored.
    public static func modelDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport
            .appendingPathComponent("dev.shadow.translate", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}