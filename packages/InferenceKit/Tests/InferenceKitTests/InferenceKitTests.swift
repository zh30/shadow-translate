import Testing
@testable import InferenceKit

@Test func modelIdIsImmersiveTranslateVariant() {
    #expect(InferenceKit.modelId.contains("immersive-translate"))
}
