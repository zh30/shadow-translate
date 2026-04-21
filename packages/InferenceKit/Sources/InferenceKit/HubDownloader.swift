import Foundation
import MLXLMCommon
import HuggingFace

enum HubDownloadError: LocalizedError {
    case invalidRepositoryID(String)

    var errorDescription: String? {
        switch self {
        case .invalidRepositoryID(let id):
            "Invalid repository ID: \(id)"
        }
    }
}

struct HubDownloader: MLXLMCommon.Downloader {
    private let client: HuggingFace.HubClient

    init(_ client: HuggingFace.HubClient = .default) {
        self.client = client
    }

    func download(
        id: String,
        revision: String?,
        matching patterns: [String],
        useLatest: Bool,
        progressHandler: @Sendable @escaping (Progress) -> Void
    ) async throws -> URL {
        guard let repoID = HuggingFace.Repo.ID(rawValue: id) else {
            throw HubDownloadError.invalidRepositoryID(id)
        }
        return try await client.downloadSnapshot(
            of: repoID,
            revision: revision ?? "main",
            matching: patterns,
            progressHandler: { @Sendable progress in
                progressHandler(progress)
            }
        )
    }
}