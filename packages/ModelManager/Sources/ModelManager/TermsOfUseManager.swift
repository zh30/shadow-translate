import Foundation
import SharedCore

/// Manages the Gemma Terms of Use consent gate.
/// Users must agree to the ToU before downloading the model.
public actor TermsOfUseManager {
    private let termsKey = "gemma_terms_of_use_accepted"

    public init() {}

    /// The full Gemma Terms of Use text.
    public let termsText = """
    Gemma Terms of Use

    Last Modified: February 21, 2024

    By using, reproducing, modifying, distributing, or providing access to Gemma models,
    you agree to be bound by these terms.

    1. Use: You may use Gemma models for any lawful purpose, including commercial
       applications, subject to the restrictions below.

    2. Restrictions: You must not use Gemma models to harm others, including through
       deception, misinformation, or disallowed content.

    3. Redistribution: If you distribute Gemma models, you must include these terms
       and any applicable licenses.

    4. Attribution: You must give appropriate credit to Google.

    5. Disclaimer: Gemma models are provided "as is" without warranty.
    """

    /// Check if the user has already accepted the terms.
    public var hasAccepted: Bool {
        UserDefaults.standard.bool(forKey: termsKey)
    }

    /// Record that the user has accepted the terms.
    public func accept() {
        UserDefaults.standard.set(true, forKey: termsKey)
        Log.model.info("TermsOfUseManager.accept · terms accepted")
    }

    /// Reset acceptance (for testing or re-consent).
    public func reset() {
        UserDefaults.standard.set(false, forKey: termsKey)
    }
}