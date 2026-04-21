import Foundation
import SharedCore

public enum InferenceKit {
    public static let version = "0.1.0"
    public static let modelId = "mlx-community/translategemma-4b-it-4bit_immersive-translate"

    public enum Config {
        public static let defaultTemperature: Float = 0.2
        public static let defaultTopP: Float = 0.95
        public static let defaultMaxTokens: Int = 1024
        public static let gpuCacheLimit: Int = 2_000_000_000
        public static let idleTimeoutSeconds: TimeInterval = 60
        public static let languageConfidenceThreshold: Double = 0.7
    }
}