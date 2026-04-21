import Foundation
import MLXLMCommon
import MLXLLM
import MLX
import SharedCore

public actor InferenceEngine {
    private var container: ModelContainer?
    private var lastUseAt: Date = .distantPast
    private var idleTask: Task<Void, Never>?

    private let downloader = HubDownloader()
    private let tokenizerLoader = TransformersTokenizerLoader()

    public init() {}

    // MARK: - Warm Up

    public func warmUp() async throws {
        Log.inference.info("InferenceEngine.warmUp · starting model load")
        MLX.GPU.set(cacheLimit: InferenceKit.Config.gpuCacheLimit)

        let config = ModelConfiguration(id: InferenceKit.modelId)
        let loaded = try await LLMModelFactory.shared.loadContainer(
            from: downloader,
            using: tokenizerLoader,
            configuration: config
        )
        self.container = loaded
        self.lastUseAt = Date()

        // Run 1-token dummy to warm GPU pipelines
        let input = try await loaded.prepare(input: UserInput(prompt: "warm up"))
        let params = GenerateParameters(maxTokens: 1, temperature: 0.01)
        let stream = try await loaded.generate(input: input, parameters: params)
        for await generation in stream {
            if case .info = generation { break }
        }

        Log.inference.info("InferenceEngine.warmUp · model ready")
        scheduleIdleTimer()
    }

    // MARK: - Translate

    public func translate(
        text: String,
        source: Language,
        target: Language
    ) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                do {
                    let resolvedSource: Language
                    if source == .auto {
                        resolvedSource = LanguageDetector.detect(text) ?? .en
                    } else {
                        resolvedSource = source
                    }

                    let prompt = Self.buildPrompt(text: text, source: resolvedSource, target: target)

                    guard let container = try await self.ensureLoaded() else {
                        continuation.finish()
                        return
                    }

                    // Touch lastUseAt on the actor
                    await self.touchLastUse()
                    await self.rescheduleIdleTimer()

                    let input = try await container.prepare(input: UserInput(prompt: prompt))
                    let params = GenerateParameters(
                        maxTokens: InferenceKit.Config.defaultMaxTokens,
                        temperature: InferenceKit.Config.defaultTemperature,
                        topP: InferenceKit.Config.defaultTopP
                    )

                    let stream = try await container.generate(input: input, parameters: params)

                    for await generation in stream {
                        switch generation {
                        case .chunk(let text):
                            continuation.yield(text)
                        case .info:
                            break
                        case .toolCall:
                            break
                        }
                    }

                    continuation.finish()
                } catch {
                    Log.inference.error("InferenceEngine.translate · \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }

    // MARK: - Unload

    public func unloadIfIdle() {
        guard Date().timeIntervalSince(lastUseAt) >= InferenceKit.Config.idleTimeoutSeconds
        else { return }

        Log.inference.info("InferenceEngine.unloadIfIdle · unloading model after idle timeout")
        container = nil
        idleTask?.cancel()
        idleTask = nil
        MLX.GPU.clearCache()
    }

    // MARK: - Private

    private func touchLastUse() {
        lastUseAt = Date()
    }

    private func ensureLoaded() async throws -> ModelContainer? {
        if let container { return container }
        Log.inference.info("InferenceEngine.ensureLoaded · re-loading model")
        return try await warmUp()
    }

    @discardableResult
    private func warmUp() async throws -> ModelContainer? {
        MLX.GPU.set(cacheLimit: InferenceKit.Config.gpuCacheLimit)
        let config = ModelConfiguration(id: InferenceKit.modelId)
        let loaded = try await LLMModelFactory.shared.loadContainer(
            from: downloader,
            using: tokenizerLoader,
            configuration: config
        )
        self.container = loaded
        self.lastUseAt = Date()
        scheduleIdleTimer()
        return loaded
    }

    private func scheduleIdleTimer() {
        idleTask?.cancel()
        idleTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(InferenceKit.Config.idleTimeoutSeconds))
            await self?.unloadIfIdle()
        }
    }

    /// Public wrapper so `translate()`'s non-isolated Task can reschedule.
    public func rescheduleIdleTimer() {
        scheduleIdleTimer()
    }

    private static func buildPrompt(text: String, source: Language, target: Language) -> String {
        "<<<source>>>\(source.rawValue)<<<target>>>\(target.rawValue)<<<text>>>\(text)"
    }
}