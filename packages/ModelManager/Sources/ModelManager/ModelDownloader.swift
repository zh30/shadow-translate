import Foundation
import SharedCore
import HuggingFace

/// Manages model downloads from HuggingFace Hub.
public actor ModelDownloader {
    private let hubClient: HubClient

    public init(hubClient: HubClient = .default) {
        self.hubClient = hubClient
    }

    /// Download a model from HuggingFace Hub with progress reporting.
    public func download(
        modelId: String = ModelManager.defaultModelId,
        progressHandler: @MainActor @Sendable @escaping (Progress) -> Void = { _ in }
    ) async throws -> URL {
        Log.model.info("ModelDownloader.download · starting download for \(modelId)")

        guard let repoID = Repo.ID(rawValue: modelId) else {
            throw ShadowError.downloadFailed("Invalid model ID: \(modelId)")
        }

        let destination = ModelManager.modelDirectory().appendingPathComponent(
            modelId.replacingOccurrences(of: "/", with: "--"),
            isDirectory: true
        )

        let url = try await hubClient.downloadSnapshot(
            of: repoID,
            kind: .model,
            to: destination,
            matching: ["*.safetensors", "*.json", "*.jinja", "*.txt", "*.model"],
            progressHandler: progressHandler
        )

        Log.model.info("ModelDownloader.download · completed download for \(modelId)")
        return url
    }

    /// Check if a model is already downloaded locally.
    public func isModelDownloaded(modelId: String = ModelManager.defaultModelId) -> Bool {
        let dir = localModelDirectory(modelId: modelId)
        let configFile = dir.appendingPathComponent("config.json")
        return FileManager.default.fileExists(atPath: configFile.path)
    }

    /// Get the local model directory URL for a given model ID.
    public func localModelDirectory(modelId: String = ModelManager.defaultModelId) -> URL {
        ModelManager.modelDirectory().appendingPathComponent(
            modelId.replacingOccurrences(of: "/", with: "--"),
            isDirectory: true
        )
    }

    /// Delete a downloaded model.
    public func deleteModel(modelId: String = ModelManager.defaultModelId) throws {
        let dir = localModelDirectory(modelId: modelId)
        guard FileManager.default.fileExists(atPath: dir.path) else { return }
        try FileManager.default.removeItem(at: dir)
        Log.model.info("ModelDownloader.deleteModel · deleted \(modelId)")
    }
}