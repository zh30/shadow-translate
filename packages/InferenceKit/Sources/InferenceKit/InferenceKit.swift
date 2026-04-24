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
        public static let lowMemoryGpuCacheLimit: Int = 1_000_000_000
        public static let idleTimeoutSeconds: TimeInterval = 60
        public static let lowMemoryIdleTimeoutSeconds: TimeInterval = 20
        public static let languageConfidenceThreshold: Double = 0.7

        public static var currentTemperature: Float {
            let value = UserDefaults.standard.object(forKey: "temperature") as? Double ?? Double(defaultTemperature)
            return Float(min(max(value, 0.0), 1.0))
        }

        public static var currentTopP: Float {
            let value = UserDefaults.standard.object(forKey: "topP") as? Double ?? Double(defaultTopP)
            return Float(min(max(value, 0.1), 1.0))
        }

        public static var currentMaxTokens: Int {
            let value = UserDefaults.standard.object(forKey: "maxTokens") as? Int ?? defaultMaxTokens
            let upperBound = lowMemoryMode ? 1024 : 4096
            return min(max(value, 128), upperBound)
        }

        public static var lowMemoryMode: Bool {
            UserDefaults.standard.bool(forKey: "lowMemoryMode")
        }

        public static var currentGpuCacheLimit: Int {
            lowMemoryMode ? lowMemoryGpuCacheLimit : gpuCacheLimit
        }

        public static var currentIdleTimeoutSeconds: TimeInterval {
            lowMemoryMode ? lowMemoryIdleTimeoutSeconds : idleTimeoutSeconds
        }
    }
}
