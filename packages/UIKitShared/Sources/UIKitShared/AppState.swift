import InferenceKit
import ModelManager
import SharedCore
import SwiftUI

@MainActor @Observable
public final class AppState {
    public enum ModelState: Sendable {
        case notDownloaded
        case termsRequired
        case downloading(progress: Double, speed: String, eta: String?)
        case verifying
        case loading
        case ready
        case error(String)

        public var isReady: Bool {
            if case .ready = self { return true }
            return false
        }

        public var label: String {
            switch self {
            case .notDownloaded: String(localized: "model_state_not_downloaded", defaultValue: "未下载")
            case .termsRequired: String(localized: "model_state_terms_required", defaultValue: "需要同意条款")
            case .downloading(let p, _, _):
                "下载中 \(Int(p * 100))%"
            case .verifying: String(localized: "model_state_verifying", defaultValue: "校验中…")
            case .loading: String(localized: "model_state_loading", defaultValue: "加载中…")
            case .ready: String(localized: "model_state_ready", defaultValue: "就绪")
            case .error(let msg): "错误: \(msg)"
            }
        }

        public var systemImage: String {
            switch self {
            case .notDownloaded, .termsRequired: "arrow.down.circle"
            case .downloading: "arrow.down.circle.fill"
            case .verifying: "checkmark.circle"
            case .loading: "gearshape"
            case .ready: "checkmark.circle.fill"
            case .error: "exclamationmark.triangle"
            }
        }
    }

    public var modelState: ModelState = .notDownloaded

    private let inferenceEngine: InferenceEngine
    private let modelDownloader: ModelDownloader
    private let termsManager: TermsOfUseManager

    public init(
        inferenceEngine: InferenceEngine = InferenceEngine(),
        modelDownloader: ModelDownloader = ModelDownloader(),
        termsManager: TermsOfUseManager = TermsOfUseManager()
    ) {
        self.inferenceEngine = inferenceEngine
        self.modelDownloader = modelDownloader
        self.termsManager = termsManager
    }

    // MARK: - State Check

    public func checkModelState() async {
        let isDownloaded = await modelDownloader.isModelDownloaded()
        let hasAccepted = await termsManager.hasAccepted

        if !isDownloaded {
            modelState = hasAccepted ? .notDownloaded : .termsRequired
        } else {
            modelState = .loading
            await loadModel()
        }
    }

    // MARK: - Download

    public func startDownload() async {
        modelState = .downloading(progress: 0, speed: "", eta: nil)

        do {
            let url = try await modelDownloader.download { @Sendable [weak self] progress in
                Task { @MainActor in
                    self?.handleDownloadProgress(progress)
                }
            }
            Log.model.info("AppState · download completed to \(url.path)")
            modelState = .loading
            await loadModel()
        } catch is CancellationError {
            Log.model.info("AppState · download cancelled")
            modelState = .notDownloaded
        } catch {
            Log.model.error("AppState · download failed: \(error.localizedDescription)")
            modelState = .error(error.localizedDescription)
        }
    }

    public func cancelDownload() async {
        await modelDownloader.cancelDownload()
        modelState = .notDownloaded
    }

    // MARK: - Load

    public func loadModel() async {
        let dir = await modelDownloader.localModelDirectory()
        modelState = .loading

        do {
            try await inferenceEngine.warmUpFromDirectory(dir)
            modelState = .ready
            Log.model.info("AppState · model loaded and ready")
        } catch {
            Log.model.error("AppState · model load failed: \(error.localizedDescription)")
            modelState = .error(error.localizedDescription)
        }
    }

    // MARK: - Delete

    public func deleteModel() async {
        await inferenceEngine.unload()
        do {
            try await modelDownloader.deleteModel()
            await termsManager.reset()
            modelState = .termsRequired
            Log.model.info("AppState · model deleted")
        } catch {
            Log.model.error("AppState · delete failed: \(error.localizedDescription)")
            modelState = .error(error.localizedDescription)
        }
    }

    // MARK: - Terms of Use

    public var termsText: String {
        get async { await termsManager.termsText }
    }

    public func acceptTerms() async {
        await termsManager.accept()
        if case .termsRequired = modelState {
            modelState = .notDownloaded
        }
    }

    public var hasAcceptedTerms: Bool {
        get async { await termsManager.hasAccepted }
    }

    // MARK: - Inference Access

    public var inference: InferenceEngine { inferenceEngine }

    // MARK: - Private

    private func handleDownloadProgress(_ progress: Progress) {
        let throughput = progress.throughput ?? 0
        let speed = throughput > 0
            ? ByteCountFormatter.string(fromByteCount: Int64(throughput), countStyle: .file) + "/s"
            : ""
        let eta = progress.estimatedTimeRemaining.map {
            Self.formatDuration($0)
        }
        modelState = .downloading(progress: progress.fractionCompleted, speed: speed, eta: eta)
    }

    private static func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        }
        return "\(seconds)秒"
    }
}